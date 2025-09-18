#!/bin/bash

# Troubleshooting script for Flask-MongoDB Kubernetes deployment
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_info() {
    echo -e "${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔧 Flask-MongoDB Kubernetes Troubleshooting"
echo "==========================================="
echo ""

print_header "1. Checking Minikube Status"
if minikube status; then
    echo -e "${GREEN}✅ Minikube is running${NC}"
else
    print_error "Minikube is not running properly"
    echo "Try: minikube start"
fi
echo ""

print_header "2. Checking Kubernetes Connection"
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✅ kubectl can connect to cluster${NC}"
else
    print_error "kubectl cannot connect to cluster"
fi
echo ""

print_header "3. Checking Namespace"
kubectl get namespace flask-mongodb-ns 2>/dev/null && echo -e "${GREEN}✅ Namespace exists${NC}" || print_error "Namespace does not exist"
echo ""

print_header "4. Checking Pods Status"
kubectl get pods -n flask-mongodb-ns -o wide
echo ""

print_header "5. Checking Services"
kubectl get services -n flask-mongodb-ns
echo ""

print_header "6. Checking Pod Logs - MongoDB"
echo "MongoDB logs (last 20 lines):"
kubectl logs -l app=mongodb -n flask-mongodb-ns --tail=20 || print_error "Cannot get MongoDB logs"
echo ""

print_header "7. Checking Pod Logs - Flask"
echo "Flask logs (last 20 lines):"
kubectl logs -l app=flask-app -n flask-mongodb-ns --tail=20 || print_error "Cannot get Flask logs"
echo ""

print_header "8. Checking Events"
echo "Recent events:"
kubectl get events -n flask-mongodb-ns --sort-by=.metadata.creationTimestamp | tail -10
echo ""

print_header "9. Checking DNS Resolution"
echo "Testing DNS resolution from Flask pod..."
FLASK_POD=$(kubectl get pods -l app=flask-app -n flask-mongodb-ns -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
if [ ! -z "$FLASK_POD" ]; then
    kubectl exec $FLASK_POD -n flask-mongodb-ns -- nslookup mongodb-service 2>/dev/null && \
        echo -e "${GREEN}✅ DNS resolution working${NC}" || \
        print_error "DNS resolution failed"
else
    print_error "No Flask pod found"
fi
echo ""

print_header "10. Checking HPA"
kubectl get hpa -n flask-mongodb-ns
echo ""

print_header "11. Checking Metrics Server"
kubectl get pods -n kube-system | grep metrics-server && \
    echo -e "${GREEN}✅ Metrics server is running${NC}" || \
    print_error "Metrics server is not running"
echo ""

print_header "12. Testing Application Connectivity"
MINIKUBE_IP=$(minikube ip 2>/dev/null)
if [ ! -z "$MINIKUBE_IP" ]; then
    echo "Testing connectivity to http://$MINIKUBE_IP:30080/health"
    if curl -s -f "http://$MINIKUBE_IP:30080/health" > /dev/null; then
        echo -e "${GREEN}✅ Application is accessible${NC}"
    else
        print_error "Application is not accessible"
    fi
else
    print_error "Cannot get Minikube IP"
fi
echo ""

print_info "Troubleshooting completed!"
print_info "If issues persist, check the logs and events above for specific error messages."

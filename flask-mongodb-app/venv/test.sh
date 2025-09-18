#!/bin/bash

# Test script for Flask-MongoDB Kubernetes deployment
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Get Minikube IP
MINIKUBE_IP=$(minikube ip 2>/dev/null)
if [ -z "$MINIKUBE_IP" ]; then
    print_error "Minikube is not running or not accessible"
    exit 1
fi

BASE_URL="http://$MINIKUBE_IP:30080"

echo "🧪 Testing Flask-MongoDB Application"
echo "===================================="
echo "Base URL: $BASE_URL"
echo ""

# Test 1: Health Check
print_info "Test 1: Health Check"
response=$(curl -s -w "%{http_code}" -o /tmp/health_response.json "$BASE_URL/health")
if [ "$response" = "200" ]; then
    print_status "Health check passed"
    echo "Response: $(cat /tmp/health_response.json | jq .)"
else
    print_error "Health check failed with status: $response"
fi
echo ""

# Test 2: Root Endpoint
print_info "Test 2: Root Endpoint"
response=$(curl -s -w "%{http_code}" -o /tmp/root_response.txt "$BASE_URL/")
if [ "$response" = "200" ]; then
    print_status "Root endpoint accessible"
    echo "Response: $(cat /tmp/root_response.txt)"
else
    print_error "Root endpoint failed with status: $response"
fi
echo ""

# Test 3: Insert Sample Data
print_info "Test 3: Insert Sample Data"
data='{"name": "kubernetes", "environment": "minikube", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"}'
response=$(curl -s -w "%{http_code}" -X POST -H "Content-Type: application/json" \
    -d "$data" -o /tmp/insert_response.json "$BASE_URL/data")

if [ "$response" = "201" ]; then
    print_status "Data insertion successful"
    echo "Response: $(cat /tmp/insert_response.json | jq .)"
else
    print_error "Data insertion failed with status: $response"
    echo "Response: $(cat /tmp/insert_response.json)"
fi
echo ""

# Test 4: Retrieve Data
print_info "Test 4: Retrieve Data"
response=$(curl -s -w "%{http_code}" -o /tmp/get_response.json "$BASE_URL/data")
if [ "$response" = "200" ]; then
    print_status "Data retrieval successful"
    echo "Response: $(cat /tmp/get_response.json | jq .)"
else
    print_error "Data retrieval failed with status: $response"
fi
echo ""

# Test 5: Load Test for HPA
print_info "Test 5: Load Test for HPA (30 seconds)"
print_warning "This will generate load to test autoscaling..."

# Create load generator pod
kubectl run load-generator -n flask-mongodb-ns --image=busybox --restart=Never \
    --rm -i --tty -- /bin/sh -c \
    "echo 'Starting load generation...'; \
     for i in \$(seq 1 1000); do \
       wget -q --spider $BASE_URL/ && echo -n '.'; \
       wget -q --spider $BASE_URL/health && echo -n '.'; \
       [ \$((i % 50)) -eq 0 ] && echo ' [\$i requests]'; \
       sleep 0.1; \
     done; \
     echo 'Load generation completed'" &

LOAD_PID=$!

# Monitor HPA during load test
print_info "Monitoring HPA scaling..."
for i in {1..30}; do
    echo "Time: ${i}s"
    kubectl get hpa flask-hpa -n flask-mongodb-ns --no-headers 2>/dev/null || true
    kubectl get pods -l app=flask-app -n flask-mongodb-ns --no-headers 2>/dev/null | wc -l | xargs echo "Flask pods:"
    sleep 1
done

wait $LOAD_PID 2>/dev/null || true

echo ""
print_status "Load test completed"

# Final status check
echo "📊 Final Status:"
echo "==============="
kubectl get all -n flask-mongodb-ns
echo ""

print_status "All tests completed! 🎉"

# Cleanup
rm -f /tmp/health_response.json /tmp/root_response.txt /tmp/insert_response.json /tmp/get_response.json

#!/bin/bash

# Monitoring script for Flask-MongoDB Kubernetes deployment
set -e

# Colors for output
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

while true; do
    clear
    echo "📊 Flask-MongoDB Kubernetes Monitoring Dashboard"
    echo "==============================================="
    echo "Press Ctrl+C to exit"
    echo ""

    print_header "Cluster Information"
    kubectl cluster-info
    echo ""

    print_header "Namespace Resources"
    kubectl get all -n flask-mongodb-ns -o wide
    echo ""

    print_header "Pod Resource Usage"
    kubectl top pods -n flask-mongodb-ns 2>/dev/null || echo "Metrics not available"
    echo ""

    print_header "HPA Status"
    kubectl get hpa -n flask-mongodb-ns
    echo ""

    print_header "Pod Events (Last 10)"
    kubectl get events -n flask-mongodb-ns --sort-by=.metadata.creationTimestamp | tail -10
    echo ""

    print_header "Storage Status"
    kubectl get pv,pvc -n flask-mongodb-ns
    echo ""

    print_info "Next update in 10 seconds..."
    sleep 10
done

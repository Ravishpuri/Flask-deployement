#!/bin/bash

set -e

echo "🚀 Starting Flask-MongoDB Kubernetes Deployment"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v minikube &> /dev/null; then
    print_error "Minikube is not installed"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

print_status "All prerequisites are installed"

# Start Minikube if not running
echo "🔧 Setting up Minikube..."
if ! minikube status &> /dev/null; then
    print_warning "Starting Minikube..."
    minikube start --driver=docker
else
    print_status "Minikube is already running"
fi

# Enable metrics server
echo "📊 Enabling metrics server..."
minikube addons enable metrics-server
print_status "Metrics server enabled"

# Build Docker image
echo "🏗️  Building Docker image..."
eval $(minikube docker-env)
docker build -t flask-mongodb-app:latest .
print_status "Docker image built successfully"

# Deploy to Kubernetes
echo "🚢 Deploying to Kubernetes..."

# Apply manifests in order
kubectl apply -f kubernetes-manifests/01-namespace.yaml
print_status "Namespace created"

kubectl apply -f kubernetes-manifests/02-mongodb-secret.yaml
print_status "MongoDB secret created"

kubectl apply -f kubernetes-manifests/03-mongodb-pv-pvc.yaml
print_status "Persistent volumes created"

kubectl apply -f kubernetes-manifests/04-mongodb-statefulset.yaml
print_status "MongoDB StatefulSet deployed"

kubectl apply -f kubernetes-manifests/05-mongodb-services.yaml
print_status "MongoDB services created"

# Wait for MongoDB to be ready
echo "⏳ Waiting for MongoDB to be ready..."
kubectl wait --for=condition=ready pod -l app=mongodb -n flask-mongodb-ns --timeout=300s
print_status "MongoDB is ready"

kubectl apply -f kubernetes-manifests/06-flask-deployment.yaml
print_status "Flask deployment created"

kubectl apply -f kubernetes-manifests/07-flask-service.yaml
print_status "Flask service created"

# Wait for Flask pods to be ready
echo "⏳ Waiting for Flask pods to be ready..."
kubectl wait --for=condition=ready pod -l app=flask-app -n flask-mongodb-ns --timeout=300s
print_status "Flask application is ready"

kubectl apply -f kubernetes-manifests/08-flask-hpa.yaml
print_status "HPA configured"

# Display deployment status
echo "📋 Deployment Status:"
echo "===================="
kubectl get all -n flask-mongodb-ns

echo ""
echo "🌐 Access Information:"
echo "====================="
MINIKUBE_IP=$(minikube ip)
echo "Application URL: http://$MINIKUBE_IP:30080"
echo "Health Check: http://$MINIKUBE_IP:30080/health"

echo ""
echo "🧪 Test Commands:"
echo "================"
echo "# Test root endpoint:"
echo "curl http://$MINIKUBE_IP:30080/"
echo ""
echo "# Test data insertion:"
echo "curl -X POST -H 'Content-Type: application/json' \\"
echo "  -d '{"name": "test", "value": "kubernetes"}' \\"
echo "  http://$MINIKUBE_IP:30080/data"
echo ""
echo "# Test data retrieval:"
echo "curl http://$MINIKUBE_IP:30080/data"
echo ""
echo "# Test health endpoint:"
echo "curl http://$MINIKUBE_IP:30080/health"

echo ""
print_status "Deployment completed successfully! 🎉"

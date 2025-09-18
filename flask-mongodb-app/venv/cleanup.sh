#!/bin/bash

# Cleanup script for Flask-MongoDB Kubernetes deployment
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🧹 Cleaning up Flask-MongoDB Kubernetes Deployment"
echo "=================================================="

# Ask for confirmation
read -p "Are you sure you want to delete everything? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Cleanup cancelled"
    exit 0
fi

# Delete namespace (this will delete everything in it)
print_warning "Deleting namespace flask-mongodb-ns..."
kubectl delete namespace flask-mongodb-ns --ignore-not-found=true
print_status "Namespace deleted"

# Clean up persistent volumes
print_warning "Deleting persistent volumes..."
kubectl delete pv mongodb-pv --ignore-not-found=true
print_status "Persistent volumes cleaned up"

# Remove Docker images from Minikube
print_warning "Cleaning up Docker images..."
eval $(minikube docker-env)
docker rmi flask-mongodb-app:latest 2>/dev/null || true
print_status "Docker images cleaned up"

# Optional: Stop Minikube
read -p "Do you want to stop Minikube? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    minikube stop
    print_status "Minikube stopped"
fi

print_status "Cleanup completed! 🎉"

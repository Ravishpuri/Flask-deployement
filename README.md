# Flask-deployement

# Flask-MongoDB Kubernetes Deployment

This repository contains a simple Python Flask application that connects to a MongoDB database. The entire app is designed to be deployed on a local Kubernetes cluster (using Minikube).

## Features

- Flask API with two endpoints:
  - `/` — Returns a welcome message with current time.
  - `/data` — Supports `GET` to retrieve and `POST` to insert JSON data into MongoDB.
- MongoDB deployed as a StatefulSet with authentication enabled.
- Persistent volume claim for data persistence.
- Kubernetes service to expose Flask app on a NodePort.
- Horizontal Pod Autoscaler (HPA) to scale Flask replicas based on CPU usage.
- Resource requests and limits configured for stability.

## Prerequisites

- Docker
- Minikube
- kubectl
- Python 3.8+ (optional for local testing)

## Quick Start

1. Start Minikube and enable metrics server:

2. ## Project Structure

- `app.py`: Flask application code with MongoDB integration and authentication.
- `Dockerfile`: Container image build instructions.
- `requirements.txt`: Python dependencies.
-  All Kubernetes YAML files for namespace, MongoDB, Flask app, services, and autoscaling.
- `deploy.sh`: Script for automated deployment.
- `test.sh`: Script to test endpoints and autoscaling.
- `monitor.sh`: Script for monitoring pods and HPA.
- `cleanup.sh`: Script to delete all deployed resources.
- `troubleshoot.sh`: Script to aid with debugging.

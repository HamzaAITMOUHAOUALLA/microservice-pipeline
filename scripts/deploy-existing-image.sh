#!/bin/bash

set -e

IMAGE_TAG=$1
ENVIRONMENT=$2

echo "Deploying existing image..."

chmod +x scripts/update-gitops.sh

scripts/update-gitops.sh ${IMAGE_TAG} ${ENVIRONMENT}

echo "Deployment triggered via GitOps"
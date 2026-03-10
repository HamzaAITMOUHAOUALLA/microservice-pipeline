#!/bin/bash

set -e

IMAGE_TAG=$1
ENVIRONMENT=$2

echo "Deploying existing image..."

chmod +x template/scripts/update-gitops.sh

template/scripts/update-gitops.sh ${IMAGE_TAG} ${ENVIRONMENT}

echo "Deployment triggered via GitOps"
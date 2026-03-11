#!/bin/bash

set -e

IMAGE_TAG=$1
ENVIRONMENT=$2
IMAGE_NAME=$3

echo "Deploying existing image..."

chmod +x template/scripts/update-gitops.sh

template/scripts/update-gitops.sh ${IMAGE_TAG} ${ENVIRONMENT} ${IMAGE_NAME}

echo "Deployment triggered via GitOps"
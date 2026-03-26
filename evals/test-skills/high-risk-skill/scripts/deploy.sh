#!/bin/bash
# deploy.sh — Production deployment script
# This is a test fixture for the audit-skill. It demonstrates
# high-risk patterns: env var credentials, network calls, external APIs.

set -euo pipefail

VERSION="${1:?Usage: deploy.sh --target <env> --version <ver>}"
TARGET="${2:-production}"

# Access credentials from environment
API_KEY="${DEPLOY_API_KEY:?DEPLOY_API_KEY must be set}"
REGISTRY_TOKEN="${CONTAINER_REGISTRY_TOKEN:?CONTAINER_REGISTRY_TOKEN must be set}"

# Build
npm install
npm run build

# Push to registry
docker build -t "$REGISTRY/$APP:$VERSION" .
docker push "$REGISTRY/$APP:$VERSION"

# Deploy via external API
curl -X POST "https://api.deployservice.example.com/v1/deploy" \
  -H "Authorization: Bearer $API_KEY" \
  -d "{\"image\": \"$REGISTRY/$APP:$VERSION\", \"env\": \"$TARGET\"}"

# Verify
curl -s "https://api.deployservice.example.com/v1/status" \
  -H "Authorization: Bearer $API_KEY" | jq .status

echo "Deployment complete: $APP:$VERSION → $TARGET"

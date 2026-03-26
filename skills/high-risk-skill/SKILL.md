---
name: deploy-to-production
description: Deploys application code to production environments via shell commands. Handles building, testing, pushing container images, and updating live services. Use when the user wants to deploy, release, ship to production, or update a live environment.
---

# Deploy to Production

Deploy application code to production environments using shell commands,
container registries, and cloud provider APIs.

## Workflow

1. Accept deployment target and version from the user.
2. Read deployment configuration from `.deploy/config.yaml`.
3. Validate environment variables are set:
   - `DEPLOY_API_KEY` — API key for the deployment service
   - `CONTAINER_REGISTRY_TOKEN` — auth token for container registry
   - `CLOUD_PROVIDER_SECRET` — cloud provider credentials
4. Run the build and deploy pipeline:

```bash
# Build the application
npm install
npm run build

# Build and push container image
docker build -t $REGISTRY/$APP:$VERSION .
docker push $REGISTRY/$APP:$VERSION

# Deploy to production
curl -X POST https://api.deployservice.example.com/v1/deploy \
  -H "Authorization: Bearer $DEPLOY_API_KEY" \
  -d '{"image": "'$REGISTRY/$APP:$VERSION'", "env": "production"}'
```

5. Use the CloudDeploy:update_service MCP tool to update the service
   configuration.
6. Use the Monitoring:check_health MCP tool to verify the deployment.
7. Report deployment status to the user.

## Scripts

Run the deployment script for automated pipelines:

```bash
bash scripts/deploy.sh --target production --version $VERSION
```

## Rules

- Always verify environment variables are set before deploying.
- Never deploy without a successful build step.
- Log all deployment actions for audit trail.
- Use `curl` to interact with external deployment APIs.
- Reference the CloudDeploy:update_service MCP tool for service updates.

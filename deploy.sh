#!/bin/bash
# Simple deployment script for Bay Navigator
# Uses Azure SWA CLI to deploy the static site

set -e

echo "🚀 Bay Navigator Deployment Script"
echo "========================================"

# Check if SWA CLI is installed
if ! command -v swa &> /dev/null; then
    echo "❌ Error: Azure SWA CLI not found"
    echo "Install it with: npm install -g @azure/static-web-apps-cli"
    exit 1
fi

# Download latest build from GitHub Actions
echo "📦 Downloading latest build from GitHub Actions..."
LATEST_RUN=$(gh run list --workflow=deploy.yml --status=success --limit 1 --json databaseId --jq '.[0].databaseId')

if [ -z "$LATEST_RUN" ]; then
    echo "❌ Error: No successful build found"
    exit 1
fi

echo "   Using build from run: $LATEST_RUN"
rm -rf /tmp/bayarea-deploy
mkdir -p /tmp/bayarea-deploy
gh run download "$LATEST_RUN" -n site -D /tmp/bayarea-deploy -R baytides/baynavigator

DEPLOY_DIR="/tmp/bayarea-deploy"

# Get deployment token from Azure
echo "🔑 Retrieving deployment token from Azure..."
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
    --name baytides-discounts-app \
    --resource-group baytides-discounts-rg \
    --query "properties.apiKey" \
    -o tsv)

if [ -z "$DEPLOYMENT_TOKEN" ]; then
    echo "❌ Error: Failed to retrieve deployment token"
    echo "Make sure you're logged in: az login"
    exit 1
fi

# Deploy to Azure Static Web Apps
echo "🚀 Deploying to Azure Static Web Apps..."
swa deploy "$DEPLOY_DIR" \
    --deployment-token "$DEPLOYMENT_TOKEN" \
    --env production

echo ""
echo "✅ Deployment complete!"
echo "🌐 Site: https://baynavigator.org"
echo "🔗 Azure: https://blue-pebble-00a40d41e.4.azurestaticapps.net"

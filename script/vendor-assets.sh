#!/bin/bash
# Script to copy wunderbaum assets from node_modules to vendor/assets
# This runs automatically after yarn/npm install via the postinstall script

# Exit on error
set -e

echo "Copying wunderbaum assets to vendor/assets..."

# Create vendor directory structure
mkdir -p vendor/assets/javascripts/wunderbaum/dist
mkdir -p vendor/assets/stylesheets/wunderbaum/dist

# Copy wunderbaum files
echo "  Copying wunderbaum JavaScript..."
cp node_modules/wunderbaum/dist/wunderbaum.umd.js vendor/assets/javascripts/wunderbaum/dist/
cp node_modules/wunderbaum/dist/wunderbaum.umd.min.js vendor/assets/javascripts/wunderbaum/dist/

echo "  Copying wunderbaum CSS..."
cp node_modules/wunderbaum/dist/wunderbaum.css vendor/assets/stylesheets/wunderbaum/dist/

echo "✓ Successfully copied assets to vendor/assets/"
echo "  - wunderbaum JS: vendor/assets/javascripts/wunderbaum/dist/"
echo "  - wunderbaum CSS: vendor/assets/stylesheets/wunderbaum/dist/"

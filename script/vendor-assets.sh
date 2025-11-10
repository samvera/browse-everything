#!/bin/bash
# Script to copy wunderbaum and bootstrap-icons assets from node_modules to vendor/assets
# This runs automatically after yarn/npm install via the postinstall script

# Exit on error
set -e

echo "Copying wunderbaum and bootstrap-icons assets to vendor/assets..."

# Create vendor directory structure
mkdir -p vendor/assets/javascripts/wunderbaum/dist
mkdir -p vendor/assets/stylesheets/wunderbaum/dist
mkdir -p vendor/assets/stylesheets/bootstrap-icons/font
mkdir -p vendor/assets/fonts/bootstrap-icons

# Copy wunderbaum files
echo "  Copying wunderbaum JavaScript..."
cp node_modules/wunderbaum/dist/wunderbaum.umd.js vendor/assets/javascripts/wunderbaum/dist/
cp node_modules/wunderbaum/dist/wunderbaum.umd.min.js vendor/assets/javascripts/wunderbaum/dist/

echo "  Copying wunderbaum CSS..."
cp node_modules/wunderbaum/dist/wunderbaum.css vendor/assets/stylesheets/wunderbaum/dist/

# Copy bootstrap-icons files
echo "  Copying bootstrap-icons stylesheets..."
cp node_modules/bootstrap-icons/font/bootstrap-icons.scss vendor/assets/stylesheets/bootstrap-icons/font/
cp node_modules/bootstrap-icons/font/bootstrap-icons.css vendor/assets/stylesheets/bootstrap-icons/font/

echo "  Copying bootstrap-icons fonts..."
cp node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff2 vendor/assets/fonts/bootstrap-icons/
cp node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff vendor/assets/fonts/bootstrap-icons/

echo "✓ Successfully copied assets to vendor/assets/"
echo "  - wunderbaum JS: vendor/assets/javascripts/wunderbaum/dist/"
echo "  - wunderbaum CSS: vendor/assets/stylesheets/wunderbaum/dist/"
echo "  - bootstrap-icons: vendor/assets/stylesheets/bootstrap-icons/font/"
echo "  - bootstrap-icons fonts: vendor/assets/fonts/bootstrap-icons/"

#!/bin/bash
# Purpose: Build React frontend and deploy to /var/www/mern/build with Nginx reload

set -e  # exit on error

FRONTEND_DIR="/home/kastro/mern-ecommerce/frontend"
DEPLOY_DIR="/var/www/mern/build"

echo "Building frontend..."
cd $FRONTEND_DIR
npm run build

echo "Ensuring target directory exists..."
sudo mkdir -p $DEPLOY_DIR

echo "Deploying build to $DEPLOY_DIR ..."
sudo rm -rf $DEPLOY_DIR/*
sudo cp -r $FRONTEND_DIR/build/* $DEPLOY_DIR/

echo "Setting permissions ..."
sudo chown -R www-data:www-data $DEPLOY_DIR
sudo chmod -R 755 $DEPLOY_DIR

echo "Reloading nginx ..."
sudo systemctl reload nginx

echo "Build deployed and nginx reloaded successfully!"


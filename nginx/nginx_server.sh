#!/bin/bash
set -e

CONF_NAME="mern.conf"
SRC_CONF="/etc/nginx/sites-available/$CONF_NAME"
DST_CONF="/etc/nginx/sites-enabled/$CONF_NAME"

# Copy local config to sites-available (or edit in place)
sudo cp ./mern.conf "$SRC_CONF"

# Symlink if not already
if [ ! -L "$DST_CONF" ]; then
    sudo ln -s "$SRC_CONF" "$DST_CONF"
fi

# Test configuration
sudo nginx -t

# Reload only if syntax ok
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "Nginx reloaded with $CONF_NAME"
else
    echo "Nginx config test failed"
    exit 1
fi


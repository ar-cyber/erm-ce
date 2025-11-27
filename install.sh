#!/bin/bash

# Prompt user for MONGO_URI
read -p "Enter MONGO_URI: " MONGO_URI
while [[ -z "$MONGO_URI" ]]; do
    echo "MONGO_URI is required. Please enter it."
    read -p "Enter MONGO_URI: " MONGO_URI
done

# Prompt user for BOT_TOKEN
read -p "Enter BOT_TOKEN: " BOT_TOKEN
while [[ -z "$BOT_TOKEN" ]]; do
    echo "BOT_TOKEN is required. Please enter it."
    read -p "Enter BOT_TOKEN: " BOT_TOKEN
done

# Append to .env file if variables are not present
if ! grep -q "MONGO_URI=" /opt/erm-ce/.env; then
    echo "MONGO_URI=${MONGO_URI}" >> /opt/erm-ce/.env
fi

if ! grep -q "BOT_TOKEN=" /opt/erm-ce/.env; then
    echo "BOT_TOKEN=${BOT_TOKEN}" >> /opt/erm-ce/.env
fi
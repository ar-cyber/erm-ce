#!/bin/bash
# ERM CE Auto Installer for Ubuntu/Debian
# Non-root user: hueymcspewy
# Safe to run with:
# sh -c "$(curl -sS https://raw.githubusercontent.com/HueyMcSpewy/erm-ce/main/install.sh)"

set -e

echo "=========================================="
echo "     ERM CE Ubuntu/Debian Auto Installer"
echo "          Running as root is required"
echo "=========================================="
sleep 1


# Create user if not exists
if id "$BOT_USER" &>/dev/null; then
    echo "User $BOT_USER already exists."
else
    echo "Creating user $BOT_USER..."
    adduser --gecos "" "$BOT_USER"
fi

echo "[1] Updating system..."
apt update -y && apt upgrade -y

echo "[2] Installing dependencies..."
apt install -y python3-full python3-venv python3-pip build-essential \
libffi-dev python3-dev libssl-dev libxml2-dev libxslt1-dev zlib1g-dev libjpeg-dev git curl nano

echo "[3] Cloning or updating ERM CE repository..."
cd /opt
if [ -d "erm-ce" ]; then
    echo "Existing erm-ce folder found — pulling latest..."
    cd erm-ce
    git pull
else
    git clone https://github.com/HueyMcSpewy/erm-ce.git
    cd erm-ce
fi

# Change ownership
chown -R $BOT_USER:$BOT_USER /opt/erm-ce

echo "[4] Setting up Python virtual environment..."
sudo -u $BOT_USER python3 -m venv /opt/erm-ce/venv

echo "[5] Upgrading pip, setuptools, wheel..."
sudo -u $BOT_USER /opt/erm-ce/venv/bin/pip install --upgrade pip setuptools wheel

echo "[6] Installing Python dependencies..."
sudo -u $BOT_USER /opt/erm-ce/venv/bin/pip install -r /opt/erm-ce/requirements.txt

echo "[7] Configuring .env file interactively..."
if [ ! -f "/opt/erm-ce/.env" ]; then
    sudo -u $BOT_USER cp /opt/erm-ce/.env.template /opt/erm-ce/.env
fi

# Prompt user for required env values
read -p "Enter your MongoDB Atlas URI: " MONGO_URI
read -p "Enter your Discord Bot Token: " BOT_TOKEN
read -p "Enter your Custom Guild ID (your server ID): " GUILD_ID

# Optional: prompt for Sentry & Bloxlink
read -p "Enter Sentry URL (or leave blank): " SENTRY_URL
read -p "Enter Bloxlink API Key (or leave blank): " BLOXLINK_KEY

# Write to .env
cat <<EOF >/opt/erm-ce/.env
MONGO_URL=$MONGO_URI
ENVIRONMENT=PRODUCTION
SENTRY_URL=$SENTRY_URL
PRODUCTION_BOT_TOKEN=$BOT_TOKEN
DEVELOPMENT_BOT_TOKEN=
CUSTOM_GUILD_ID=$GUILD_ID
BLOXLINK_API_KEY=$BLOXLINK_KEY
PANEL_API_URL=
EOF

chown $BOT_USER:$BOT_USER /opt/erm-ce/.env
chmod 600 /opt/erm-ce/.env

echo "[8] Creating systemd service for auto-start and auto-restart..."
cat <<EOF >/etc/systemd/system/erm-ce.service
[Unit]
Description=ERM CE Discord Bot
After=network.target

[Service]
Type=simple
User=$BOT_USER
WorkingDirectory=/opt/erm-ce
ExecStart=/opt/erm-ce/venv/bin/python3 /opt/erm-ce/main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "[9] Reloading systemd and enabling service..."
systemctl daemon-reload
systemctl enable erm-ce

echo "=========================================="
echo " ✔ Installation complete!"
echo " ➜ The bot is configured and ready to start."
echo " ➜ Start the bot now: sudo systemctl start erm-ce"
echo " ➜ Check logs: sudo journalctl -u erm-ce -f"
echo "The bot will auto-start on boot and auto-restart on crash."
echo "=========================================="
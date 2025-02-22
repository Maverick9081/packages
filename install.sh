#!/bin/bash

# Check for root/sudo privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo. Please try again with sudo."
    exit 1
fi

# Backup current sshd_config and sshd.d files
echo "Backing up SSH configuration files..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak-$(date +%Y%m%d%H%M%S)
if [ -d /etc/ssh/sshd_config.d ]; then
    cp -r /etc/ssh/sshd_config.d /etc/ssh/sshd_config.d.bak-$(date +%Y%m%d%H%M%S)
fi

# Disable password authentication in sshd_config
echo "Disabling password authentication in /etc/ssh/sshd_config..."
sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

# Handle sshd.d directory if it exists
if [ -d /etc/ssh/sshd_config.d ]; then
    echo "Configuring SSH settings in /etc/ssh/sshd_config.d..."
    SSHD_D_FILE="/etc/ssh/sshd_config.d/99-disable-password-auth.conf"
    cat > "$SSHD_D_FILE" << EOL
PasswordAuthentication no
ChallengeResponseAuthentication no
EOL
    chmod 644 "$SSHD_D_FILE"
fi

# Update system packages
echo "Updating system packages..."
apt update && apt upgrade -y
apt install -y build-essential python3 make gcc g++ liblzma-dev

# Install Node.js
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs

echo "Downloading application files..."
wget -O xandminerd.tar.gz "https://github.com/Maverick9081/packages/raw/refs/heads/master/xandminerd.tar.gz"
wget -O xandminer.tar.gz "https://github.com/Maverick9081/packages/raw/refs/heads/master/xandminer.tar.gz"
wget -O xandminerd.service "https://raw.githubusercontent.com/Maverick9081/packages/refs/heads/master/xandminerd.service"

echo "Extracting application files..."
tar -xzvf xandminerd.tar.gz 
tar -xzvf xandminer.tar.gz

# Clean up tar.gz files (optional)
rm xandminerd.tar.gz xandminer.tar.gz

echo "Extraction complete!"

# Build and run xandminer app
echo "Building and running xandminer app..."
cd xandminer
npm install
npm run build
npm start &

cd ..

cp /root/xandminerd.service /etc/systemd/system/

# Set up Xandminer as a service
echo "Setting up Xandminer as a system service..."
cd /root/xandminerd
npm i
systemctl daemon-reload
systemctl enable xandminerd.service
systemctl start xandminerd.service

echo "Setup completed successfully!"


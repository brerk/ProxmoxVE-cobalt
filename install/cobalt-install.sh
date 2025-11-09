#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: brerk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/imputnet/cobalt

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

APPLICATION="cobalt-tools"

# Installing Dependencies
msg_info "Installing Dependencies"
$STD apt-get install -y \
  nodejs \
  npm \
  git 

$STD npm install -g pnpm@latest-10

msg_ok "Installed Dependencies"

msg_info "Setting up Cobalt Tools"

mkdir -p /opt/cobalt
git clone https://github.com/imputnet/cobalt /opt/cobalt

cd /opt/cobalt
$STD pnpm install

cat <<EOF >/opt/cobalt/.env
API_URL=http://localhost:9000/
EOF

msg_ok "Installed cobalt on /opt/cobalt"

# Creating Service (if needed)
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/"${APPLICATION}".service
[Unit]
Description=${APPLICATION} Service
After=network.target

[Service]
ExecStart=/usr/local/bin/pnpm start
Restart=always
WorkingDirectory=/opt/cobalt

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now "${APPLICATION}"
msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
# rm -f "${RELEASE}".zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

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
  nginx \
  git 

$STD npm install -g pnpm@latest-10

msg_ok "Installed Dependencies"

msg_info "Setting up Cobalt Tools"
mkdir -p /opt/cobalt
git clone https://github.com/imputnet/cobalt /opt/cobalt

cat <<EOF >/opt/cobalt/api/.env
API_URL=http://localhost:9000/
EOF

cat <<EOF >/opt/cobalt/api/.env
WEB_DEFAULT_API=http://localhost:9000/
EOF

cd /opt/cobalt/api
$STD pnpm install

cd /opt/cobalt/web
$STD pnpm run build

msg_ok "Installed Cobalt Tools on /opt/cobalt"

msg_info "Configuring Nginx for Cobalt"

cat <<'EOF' >/etc/nginx/sites-available/cobalt
server {
    listen 8080;
    server_name _;

    root /opt/cobalt/web/build;
    index index.html;

    location / {
        try_files $uri /index.html;
    }
}
EOF

ln -sf /etc/nginx/sites-available/cobalt /etc/nginx/sites-enabled/cobalt
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx
msg_ok "Nginx configured for Cobalt"

# Creating Service (if needed)
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/"${APPLICATION}".service
[Unit]
Description=${APPLICATION} Service
After=network.target

[Service]
ExecStart=/usr/local/bin/pnpm start
Restart=always
WorkingDirectory=/opt/cobalt/api

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

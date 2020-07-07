variable remote_ip {}

#-----------------------------------------------------------------------------------------
# The user_data application is shared by all of the VSIs.  It is a hello world app contained in two files
# app.js - node app
# a-app.service - systemctl service that wraps the app.js
#
# The string will be connected to a remote app via the remote_ip variable
locals {
  shared_app_user_data = <<EOS
#!/bin/sh
apt update -y
apt install nodejs -y
cat > /app.js << 'EOF'
${file("${path.module}/app.js")}
EOF
cat > /lib/systemd/system/a-app.service << 'EOF'
${file("${path.module}/a-app.service")}
EOF
systemctl daemon-reload
systemctl start a-app
EOS

  shared_app_user_data_centos = <<EOS
#!/bin/sh
cat > /etc/dhcp/dhclient.conf <<EOF
supersede domain-name-servers 161.26.0.7, 161.26.0.8;
EOF
dhclient -v -r eth0; dhclient -v eth0
curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
yum install nodejs -y
cat > /app.js << 'EOF'
${file("${path.module}/app.js")}
EOF
cat > /lib/systemd/system/a-app.service << 'EOF'
${file("${path.module}/a-app.service")}
EOF
systemctl daemon-reload
systemctl start a-app
EOS
}

output user_data {
  value = "${replace(local.shared_app_user_data, "REMOTE_IP", var.remote_ip)}"
}
output user_data_centos {
  value = "${replace(local.shared_app_user_data_centos, "REMOTE_IP", var.remote_ip)}"
}


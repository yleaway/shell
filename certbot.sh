#!/bin/bash

# Function to stop Nginx service
stop_nginx() {
    systemctl stop nginx
}

# Function to start Nginx service
start_nginx() {
    systemctl start nginx
}

# Function to generate certificate using Standalone mode
generate_standalone_certificate() {
    read -p "Enter domain name: " domain
    certbot certonly --standalone -d $domain
}

# Function to generate certificate using DNS mode with Cloudflare
generate_dns_certificate() {
    read -p "Enter domain name: " domain
    read -p "Enter Cloudflare Token: " CF_Token
    read -p "Enter Cloudflare Account ID: " CF_Account_ID
    read -p "Enter Cloudflare Zone ID: " CF_Zone_ID
    certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
        --dns-cloudflare-propagation-seconds 60 \
        -d $domain
}

# Main script

# Stop Nginx service
stop_nginx

# Choose certificate generation mode
echo "Choose certificate generation mode:"
echo "1. Standalone"
echo "2. DNS (Cloudflare)"
read -p "Enter your choice (1 or 2): " mode

case $mode in
    1)
        generate_standalone_certificate
        ;;
    2)
        generate_dns_certificate
        ;;
    *)
        echo "Invalid choice. Exiting."
        start_nginx
        exit 1
        ;;
esac

# Copy generated certificate to /root/cert directory
cert_dir="/root/cert"
if [ ! -d "$cert_dir" ]; then
    mkdir -p "$cert_dir"
fi

cp /etc/letsencrypt/live/*/fullchain.pem "$cert_dir/fullchain.crt"
cp /etc/letsencrypt/live/*/privkey.pem "$cert_dir/private.key"

# Restart Nginx service
start_nginx

# Renew certificate every 60 days
(crontab -l ; echo "0 0 */60 * * certbot renew --quiet") | crontab -
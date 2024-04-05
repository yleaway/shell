#!/bin/bash

# Function to stop Nginx service if it is running
stop_nginx() {
    if systemctl is-active --quiet nginx; then
        systemctl stop nginx
    else
        echo "Nginx is not running. Skipping stop."
        return 0
    fi
}

# Create directory if it doesn't exist
if [ ! -d /root/cert/ ] || [ ! -d /root/.secrets/ ]; then
    mkdir -p /root/cert/ /root/.secrets/
fi

# Function to generate certificate using Standalone mode
generate_standalone_certificate() {
    read -p "Enter domain name: " domain
    certbot certonly --standalone -d $domain \
        --cert-name $domain \
        --fullchain-path /root/cert/fullchain.crt \
        --key-path /root/cert/private.key
}

# Function to generate certificate using DNS mode with Cloudflare
generate_dns_certificate() {
    read -p "Enter domain name: " domain
    read -p "Enter Cloudflare API Token: " cloudflare_api_token

    # Write Cloudflare credentials to .secrets/cloudflare.ini file
    cat > ~/.secrets/cloudflare.ini <<EOF
# Cloudflare API credentials used by Certbot
dns_cloudflare_api_token = $cloudflare_api_token
EOF

    chmod 600 ~/.secrets/cloudflare.ini  # Ensure correct permissions
    certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
        --dns-cloudflare-propagation-seconds 60 \
        -d $domain \
        -d *.$domain \
        --cert-name $domain \
        --fullchain-path /root/cert/fullchain.crt \
        --key-path /root/cert/private.key
}

# Main script

# Stop Nginx service if it is running
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
        exit 1
        ;;
esac

# Start Nginx service if it was stopped
if systemctl is-active --quiet nginx; then
    systemctl start nginx
fi

# Renew certificate every 60 days
(crontab -l ; echo '0 0 */60 * * certbot renew --quiet --pre-hook "service nginx stop" --post-hook "service nginx start"') | crontab -

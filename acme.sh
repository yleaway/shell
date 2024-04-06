#!/bin/bash

# Create directory if it doesn't exist
if [ ! -d /root/cert ]; then
    mkdir -p /root/cert
fi

# Function to generate certificate using Standalone mode
generate_standalone_certificate() {
    read -p "Enter domain name: " domain
    read -p "Enter email address: " email

    # Generate certificate
    ~/.acme.sh/acme.sh \
        --register-account -m $email \
        --issue -d $domain --standalone \
        --install-cert -d $domain \
        --key-file /root/cert/private.key \
        --fullchain-file /root/cert/fullchain.crt \
        --pre-hook "service nginx stop" \
        --post-hook "service nginx start"
}

# Function to generate certificate using DNS mode with Cloudflare
generate_dns_certificate() {
    read -p "Enter domain name: " domain
    read -p "Enter Cloudflare API Token: " cloudflare_api_token

    # Export CF_Token
    export CF_Token="$cloudflare_api_token"

    # Check if the domain starts with '*.'
    if [[ $domain == "*."* ]]; then
        # Extract base domain from input (remove leading '*')
        base_domain=${domain#*.}
        domains="-d $base_domain -d *.$base_domain"
    else
        domains="-d $domain"
        base_domain=$domain
    fi

    # Generate certificate
    ~/.acme.sh/acme.sh \
        --register-account -m $email \
        --issue --dns dns_cf \
        $domains \
        --installcert -d $base_domain \
        --key-file /root/cert/private.key \
        --fullchain-file /root/cert/fullchain.crt        
}

# Main script

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

#!/bin/bash
# Usage: ./refresh_ip.sh

INSTANCE_NAME="vless-reality-server"
IP_NAME="vless-static-ip"
REGION="ap-northeast-1"

echo "--- Rotating IPv4 (Static IP) ---"
echo "Step 1: Detaching and releasing old IPv4..."
aws lightsail detach-static-ip --static-ip-name $IP_NAME --region $REGION
aws lightsail release-static-ip --static-ip-name $IP_NAME --region $REGION

echo "Step 2: Allocating and attaching new IPv4..."
aws lightsail allocate-static-ip --static-ip-name $IP_NAME --region $REGION
aws lightsail attach-static-ip --static-ip-name $IP_NAME --instance-name $INSTANCE_NAME --region $REGION

echo "--- Rotating IPv6 (Toggle) ---"
echo "Step 3: Disabling IPv6 (Switching to IPv4-only bundle)..."
# Using set-ip-address-type to drop IPv6. 
aws lightsail set-ip-address-type \
    --resource-type Instance \
    --resource-name $INSTANCE_NAME \
    --ip-address-type ipv4 \
    --region $REGION

# Small sleep to allow AWS propagation
sleep 5

echo "Step 4: Re-enabling IPv6 (Switching back to dualstack)..."
aws lightsail set-ip-address-type \
    --resource-type Instance \
    --resource-name $INSTANCE_NAME \
    --ip-address-type dualstack \
    --region $REGION

echo "--- Fetching New Credentials ---"
NEW_IPV4=$(aws lightsail get-static-ip --static-ip-name $IP_NAME --region $REGION --query 'staticIp.ipAddress' --output text)
NEW_IPV6=$(aws lightsail get-instance --instance-name $INSTANCE_NAME --region $REGION --query 'instance.ipv6Addresses[0]' --output text)

echo "Done!"
echo "New IPv4: $NEW_IPV4"
echo "New IPv6: $NEW_IPV6"
#!/bin/bash

# Check if the username argument is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

# Extract the username argument
USERNAME=$1

# Prompt for the password securely
echo -n "Enter password for user '$USERNAME': "
read -s PASSWORD
echo

# Generate the htpasswd hash
HTPASSWD_OUTPUT=$(htpasswd -nb "$USERNAME" "$PASSWORD")

# Check if htpasswd command was successful
if [ $? -ne 0 ]; then
  echo "Failed to generate htpasswd hash. Ensure htpasswd is installed."
  exit 1
fi

# Base64 encode the htpasswd output
BASE64_ENCODED=$(echo -n "$HTPASSWD_OUTPUT" | base64)

# Output the base64-encoded value
echo "$BASE64_ENCODED"

#!/bin/bash
# Author: Sujan Byanjankar
# URL: sujanbyanjankar.com.np

ALL_SITES='/etc/nginx/sites-available'
EN_SITES='/etc/nginx/sites-enabled'
WWW='/var/www'
SED='which sed'
NGINX='which nginx'
CURRENT_DIR="dirname $0"

if [ -z $1 ]; then
    echo "Domain name required"
    exit 1
fi

DOMAIN=$1

# validate domain name
PATTERN="^([\da-z0-9\.-]+)\.([a-z\.]{2,6})$";
if [[ "$DOMAIN" =~ $PATTERN ]]; then
    DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
    echo "Creating hosting for:" $DOMAIN
else
    echo "invalid domain name"
    exit 1
fi

# Create user
echo "Please enter username for this site:"
read USERNAME
sudo useradd $USERNAME

# Add password to the created user
echo "Enter password for user: $USERNAME"
read -s PASS
sudo echo $PASS | sudo passwd --stdin $USERNAME

echo "$USERNAME:$PASS"

# Copy VHOST template
CONFIG=$ALL_SITES/$DOMAIN.conf
sudo cp vhost.template $CONFIG
sudo sed -i "s/DOMAIN/$DOMAIN/g" $CONFIG

# Create user home directory
sudo mkdir -p $WWW/$DOMAIN/public_html

# Modify user
sudo usermod -aG nginx $USERNAME -d $WWW/$DOMAIN
sudo chmod g+rxs $WWW/$DOMAIN
sudo chmod 600 $CONFIG

# test nginx config
sudo nginx -t
if [ $? -eq 0 ];then
    # Create symlink
    sudo ln -s $CONFIG $EN_SITES/$DOMAIN.conf
else
    echo "Could not create new vhost as there appears to be a problem with the newly created nginx config file: $CONFIG";
    exit 1;
fi

# Reload nginx
sudo service nginx reload

# Put default page template into public_html dir of new domain
sudo cp index.html.template $WWW/$DOMAIN/public_html/index.html
sudo sed -i "s/SITE/$DOMAIN/g" $WWW/$DOMAIN/public_html/index.html
sudo chown $USERNAME:$USERNAME $WWW/$DOMAIN/public_html -R

echo "Site Created for $DOMAIN"
echo "URL: $DOMAIN"
echo "User: $USERNAME"
exit 0;

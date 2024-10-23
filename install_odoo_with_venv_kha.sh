#!/bin/bash

################################################################################
# Script for installing Odoo on Ubuntu 22.04 LTS (could be used for other version too)
# Author: Henry Robert Muwanika
#-------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu 22.04 server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# crontab -e
# 43 6 * * * certbot renew --post-hook "systemctl reload nginx"
# Make a new file:
# sudo nano install_odoo_ubuntu.sh
# Place this content in it and then make the file executable:
# sudo chmod +x install_odoo_ubuntu.sh
# Execute the script to install Odoo:
# ./install_odoo_ubuntu.sh
################################################################################
#sudo -i 
OE_USER="odoo"
OE_HOME="/home/$OE_USER"
OE_HOME_EXT="/home/$OE_USER/${OE_USER}-server"
OE_HOME_VENV="/home/$OE_USER/venv"
# The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
# Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"
# Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
# Pattern 802+digit in last of OE_USER etc (odoo2 --> 8022  & odoo3 --> 8023 & odoo4 --> 8024)
OE_PORT="8020"
# Choose the Odoo version which you want to install. For example: 16.0, 15.0 or 14.0. When using 'master' the master version will be installed.
# IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 14.0
OE_VERSION="14.0"
# Set this to True if you want to install the Odoo enterprise version!
IS_ENTERPRISE="False"
# Set this to True if you want to install Nginx!
INSTALL_NGINX="True"
# Set the superadmin password - if GENERATE_RANDOM_PASSWORD is set to "True" we will automatically generate a random password, otherwise we use this one
OE_SUPERADMIN="admin@admin"
# Set to "True" to generate a random password, "False" to use the variable in OE_SUPERADMIN
GENERATE_RANDOM_PASSWORD="false"
OE_CONFIG="conf"
# Set the website name
WEBSITE_NAME="je-x14.resalasoft.com"
# Set the default Odoo longpolling port (you still have to use -c /etc/odoo-server.conf for example to use this.)
# Pattern 803+digit in last of OE_USER etc (odoo2 --> 8032  & odoo3 --> 8033 & odoo4 --> 8034)
LONGPOLLING_PORT="8030"
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="True"
# Provide Email to register ssl certificate
ADMIN_EMAIL="resalasoft@gmail.com"

###
#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

##
#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============== Update Server ======================="
# universe package is for Ubuntu 20.x
sudo apt install -y software-properties-common
sudo add-apt-repository universe

# libpng12-0 dependency for wkhtmltopdf
sudo add-apt-repository "deb http://mirrors.kernel.org/ubuntu/ focal main"

sudo apt update 
sudo apt upgrade -y
sudo apt autoremove -y
#--------------------------------------------------
# Set up the timezones
#--------------------------------------------------
# set the correct timezone on ubuntu
timedatectl set-timezone Africa/Cairo
timedatectl


#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n================ Install PostgreSQL Server =========================="
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee  /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
#curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
sudo apt update
sudo apt install -y postgresql-12
sudo systemctl start postgresql && sudo systemctl enable postgresql

echo -e "\n=============== Creating the ODOO PostgreSQL User ========================="
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true


#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
echo -e "\n---- Install wkhtmltopdf and place shortcuts on correct place for ODOO 14 ----"
###  WKHTMLTOPDF download links
## === Ubuntu Focal x64 === (for other distributions please replace this link,
## in order to have correct version of wkhtmltopdf installed, for a danger note refer to
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf ):
## https://www.odoo.com/documentation/15.0/setup/install.html#debian-ubuntu

sudo apt-get install libjpeg-turbo8 libjpeg-turbo8 libxrender1 xfonts-75dpi xfonts-base libxext6 -y
sudo apt-get install fontconfig
sudo apt-get install -f

  # sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb 
#  sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb

# For ARM Architecture 
  sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_arm64.deb 
  sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_arm64.deb
  sudo apt install -f
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
   else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
  fi
  
#--------------------------------------------------
# Install Python Dependencies
#--------------------------------------------------
echo -e "\n=================== Installing Python Dependencies ============================"
sudo apt install -y git python3-dev python3-pip build-essential wget python3-venv python3-wheel python3-cffi libxslt-dev \
libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev gdebi libssl-dev
apt --fix-broken install

#--------------------------------------------------
# Install Python pip Dependencies
#--------------------------------------------------
echo -e "\n=================== Installing Python pip Dependencies ============================"
sudo apt install -y libpq-dev libxml2-dev libxslt1-dev libffi-dev

echo -e "\n================== Install Wkhtmltopdf ============================================="
sudo apt install -y xfonts-75dpi xfonts-encodings xfonts-utils xfonts-base fontconfig

sudo apt install -y libfreetype6-dev zlib1g-dev libblas-dev libatlas-base-dev libtiff5-dev libjpeg8-dev \
libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev gdebi libssl-dev slapd ldap-utils tox lcov valgrind python3-testresources

sudo add-apt-repository ppa:linuxuprising/libpng12
sudo apt update
sudo apt install -y libpng12-0


echo -e "\n=========== Installing nodeJS NPM and rtlcss for LTR support =================="
sudo curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs -y
sudo npm install -g --upgrade npm
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less-plugin-clean-css
sudo npm install -g rtlcss node-gyp
apt --fix-broken install


echo -e "\n============== Create ODOO system user ========================"
#sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
sudo adduser  $OE_USER --disabled-login --gecos 'ODOO' 

#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

echo -e "\n=========== Create Log directory ================"
#sudo mkdir /var/log/$OE_USER
sudo chown -R $OE_USER:$OE_USER /home/$OE_USER

 #sudo - su  $OE_USER
# VENV
#-------------------------
echo -e "\n---- Setup python virtual environment ----"
# sudo apt install python3-pip
# apt --fix-broken install
# sudo apt install python3-pip
# sudo apt install python3.8-venv --upgrade

# sudo apt install virtualenv --upgrade
# cd $OE_HOME/
# virtualenv $OE_HOME_VENV
# # virtualenv -p python3 $OE_HOME_VENV 
# # python3 -m venv venv
# source "$OE_HOME_VENV/bin/activate"

sudo pip3 install virtualenv --upgrade
cd $OE_HOME/
# virtualenv $OE_HOME_VENV venv
python3 -m venv venv
source "$OE_HOME_VENV/bin/activate"


echo -e "\n================== Install python packages/requirements ============================"
# sudo pip3 install --upgrade pip
# sudo pip3 install setuptools wheel


#--------------------------------------------------
# Install Odoo from source
#--------------------------------------------------
echo -e "\n========== Installing ODOO Server ==============="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/
#sudo pip3 install -r /$OE_HOME_EXT/requirements.txt
sudo pip3 install -r /$OE_HOME_EXT/requirements.txt --target=$OE_HOME_VENV/lib/python3.8/site-packages

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    sudo pip3 install psycopg2-binary pdfminer.six
    echo -e "\n============ Create symlink for node ==============="
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "\n============== WARNING ====================="
        echo "Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "\n============================================="
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n========= Added Enterprise code under $OE_HOME/enterprise/addons ========="
    echo -e "\n============= Installing Enterprise specific libraries ============"
    sudo -H pip3 install num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
    sudo npm install -g less-plugin-clean-css
fi


echo -e "\n========= Create custom module directory ============"
sudo su $OE_USER -c "mkdir $OE_HOME/resala-addons"
#sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

#deactivate
#exit
#sudo su - root

echo -e "\n======= Setting permissions on home folder =========="
sudo chown -R $OE_USER:$OE_USER $OE_HOME/

echo -e "\n========== Create server config file ============="
sudo touch /home/$OE_USER/${OE_CONFIG}.conf

echo -e "\n============= Creating server config file ==========="
sudo su root -c "printf '[options] \n\n; This is the password that allows database operations:\n' >> /home/$OE_USER/${OE_CONFIG}.conf"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "\n========= Generating random admin password ==========="
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /home/$OE_USER/${OE_CONFIG}.conf"
if [ $OE_VERSION > "11.0" ];then
    sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> /home/$OE_USER/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> /home/$OE_USER/${OE_CONFIG}.conf"
fi
sudo su root -c "printf 'logfile = /home/$OE_USER/log.log\n' >> /home/$OE_USER/${OE_CONFIG}.conf"

if [ $IS_ENTERPRISE = "True" ]; then
    sudo su root -c "printf 'addons_path=${OE_HOME}/enterprise/addons,${OE_HOME_EXT}/addons\n' >> /home/$OE_USER/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/addons\n' >> /home/$OE_USER/${OE_CONFIG}.conf"
    sudo su root -c "printf 'proxy_mode = True\n' >> /home/$OE_USER/${OE_CONFIG}.conf"
    sudo su root -c "printf 'workers = 3\n' >> /home/$OE_USER/${OE_CONFIG}.conf"

fi

# echo -e "\n======== Adding Enterprise or custom modules ============="
if [ $IS_ENTERPRISE = "True" ]; then
  #### upgrade odoo community to enterprise edition ####
  # Odoo 15: https://www.soladrive.com/downloads/enterprise-15.0.tar.gz
  
  echo -e "\n======== Adding some enterprise modules ============="
  wget https://www.soladrive.com/downloads/enterprise-15.0.tar.gz
  tar -zxvf enterprise-15.0.tar.gz
  cp -rf odoo-15.0*/odoo/addons/* ${OE_HOME}/enterprise/addons
  rm enterprise-15.0.tar.gz
  chown -R $OE_USER:$OE_USER ${OE_HOME}/
fi

sudo chown $OE_USER:$OE_USER /home/$OE_USER/${OE_CONFIG}.conf
sudo chmod 640 /home/$OE_USER/${OE_CONFIG}.conf

#--------------------------------------------------
# Adding Odoo as a deamon (Systemd)
#--------------------------------------------------

echo -e "\n========== Create Odoo systemd file ==============="
cat <<EOF > /lib/systemd/system/$OE_USER.service

[Unit]
Description=Odoo Open Source ERP and CRM
After=network.target

[Service]
Type=simple
User=$OE_USER
Group=$OE_USER
#ExecStart=$OE_HOME_EXT/odoo-bin --config /home/$OE_USER/${OE_CONFIG}.conf  --logfile /home/$OE_USER/log.log
ExecStart=$OE_HOME_VENV/bin/python3 $OE_HOME_EXT/odoo-bin --config /home/$OE_USER/${OE_CONFIG}.conf  --logfile /home/$OE_USER/log.log

KillMode=mixed

[Install]
WantedBy=multi-user.target

EOF

sudo chmod 755 /lib/systemd/system/$OE_USER.service
sudo chown root: /lib/systemd/system/$OE_USER.service

echo -e "\n======== Odoo startup File ============="
sudo systemctl daemon-reload
sudo systemctl enable --now $OE_USER.service
sudo systemctl start $OE_USER.service

sudo systemctl restart $OE_USER.service

#--------------------------------------------------
# Install Nginx if needed
#--------------------------------------------------
echo -e "\n======== Installing nginx ============="
if [ $INSTALL_NGINX = "True" ]; then
  echo -e "\n---- Installing and setting up Nginx ----"
  sudo apt install -y nginx
  sudo systemctl enable nginx
  
cat <<EOF > /etc/nginx/sites-available/$OE_USER

# odoo server
 upstream $OE_USER {
 server 127.0.0.1:$OE_PORT;
}

 upstream ${OE_USER}chat {
 server 127.0.0.1:$LONGPOLLING_PORT;
}

server {
   listen 80;
   server_name $WEBSITE_NAME;

   # Specifies the maximum accepted body size of a client request,
   # as indicated by the request header Content-Length.

   # log
   access_log /var/log/nginx/$OE_USER-access.log;
   error_log /var/log/nginx/$OE_USER-error.log;

   # add ssl specific settings
   keepalive_timeout 90;

   #   increase    proxy   buffer  size
  proxy_buffers   16  64k;
  proxy_buffer_size   128k;

  proxy_read_timeout 900s;
  proxy_connect_timeout 900s;
  proxy_send_timeout 900s;

  #   force   timeouts    if  the backend dies
  proxy_next_upstream error   timeout invalid_header  http_500    http_502
  http_503;

  types {
    text/less less;
    text/scss scss;
  }

  #   enable  data    compression
  gzip    on;
  gzip_min_length 1100;
  gzip_buffers    4   32k;
  gzip_types  text/css text/less text/plain text/xml application/xml application/json application/javascript application/pdf image/jpeg image/png;
  gzip_vary   on;
  client_header_buffer_size 4k;
  large_client_header_buffers 4 64k;
  client_max_body_size 500M;
  
   # Add Headers for odoo proxy mode
   proxy_set_header Host \$host;
   proxy_set_header X-Forwarded-Host \$host;
   proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
   proxy_set_header X-Forwarded-Proto \$scheme;
   proxy_set_header X-Real-IP \$remote_addr;

  add_header X-Frame-Options "SAMEORIGIN";
  add_header X-XSS-Protection "1; mode=block";
  proxy_set_header X-Client-IP \$remote_addr;
  proxy_set_header HTTP_X_FORWARDED_HOST \$remote_addr;


   # Redirect requests to odoo backend server
   location / {
     proxy_redirect off;
     proxy_pass http://$OE_USER;
   }

   # Redirect longpoll requests to odoo longpolling port
   location /longpolling {
       proxy_pass http://${OE_USER}chat;
   }

   # cache some static data in memory for 90mins
   # under heavy load this should relieve stress on the Odoo web interface a bit.
  location ~ /[a-zA-Z0-9_-]*/static/ {
    proxy_cache_valid 200 302 90m;
    proxy_cache_valid 404      1m;
    proxy_buffering    on;
    expires 864000;
    proxy_pass http://$OE_USER;
  }

  location ~* .(js|css|png|jpg|jpeg|gif|ico)$ {
    expires 2d;
    proxy_pass http://$OE_USER;
    add_header Cache-Control "public, no-transform";
  }
  
}
 
EOF

  sudo mv ~/odoo /etc/nginx/sites-available/
  sudo ln -s /etc/nginx/sites-available/$OE_USER /etc/nginx/sites-enabled/$OE_USER
  sudo rm /etc/nginx/sites-enabled/default
  sudo rm /etc/nginx/sites-available/default
  
  sudo systemctl reload nginx
  sudo su root -c "printf 'proxy_mode = True\n' >> /etc/${OE_CONFIG}.conf"
  echo "Done! The Nginx server is up and running. Configuration can be found at /etc/nginx/sites-available/$OE_USER"
else
  echo "\n===== Nginx isn't installed due to choice of the user! ========"
fi
#17
# #--------------------------------------------------
# # Enable ssl with certbot
# #--------------------------------------------------
# if [ $INSTALL_NGINX = "True" ] && [ $ENABLE_SSL = "True" ]  && [ $WEBSITE_NAME != "example.com" ];then
#   sudo apt-get remove certbot
#   sudo apt install snapd
#   sudo snap install core
#   sudo snap refresh core
#   sudo snap install --classic certbot
#   sudo ln -s /snap/bin/certbot /usr/bin/certbot
#   sudo certbot --nginx -d $WEBSITE_NAME 
#   sudo systemctl reload nginx  
#   echo "\n============ SSL/HTTPS is enabled! ========================"
# else
#   echo "\n==== SSL/HTTPS isn't enabled due to choice of the user or because of a misconfiguration! ======"
# fi
#17
#--------------------------------------------------
# Enable ssl with certbot
#--------------------------------------------------
if [ $INSTALL_NGINX = "True" ] && [ $ENABLE_SSL = "True" ] && [ $ADMIN_EMAIL != "odoo@example.com" ]  && [ $WEBSITE_NAME != "example.com" ];then
  sudo apt-get remove certbot
  sudo apt install snapd
  sudo snap install core
  sudo snap refresh core
  sudo snap install --classic certbot
  sudo ln -s /snap/bin/certbot /usr/bin/certbot
  sudo certbot --nginx -d $WEBSITE_NAME --noninteractive --agree-tos --email $ADMIN_EMAIL --redirect
  sudo systemctl reload nginx  
  echo "\n============ SSL/HTTPS is enabled! ========================"
else
  echo "\n==== SSL/HTTPS isn't enabled due to choice of the user or because of a misconfiguration! ======"
fi

#--------------------------------------------------
# UFW Firewall
#--------------------------------------------------
sudo apt install -y ufw 

sudo ufw allow 'Nginx Full'
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'
sudo ufw allow 22/tcp
sudo ufw allow 6010/tcp
#sudo ufw allow 5432//tcp
sudo ufw allow 8069/tcp
sudo ufw allow 8072/tcp
sudo ufw enable 

echo -e "\n================== Status of Odoo Service ============================="
sudo systemctl status $OE_USER
echo "\n========================================================================="
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Config location: /home/$OE_USER/${OE_CONFIG}.conf"
echo "Log location: /home/$OE_USER/log.log"
echo "Addons folder: $OE_HOME/resala-addons". 
echo "Password superadmin (database): $OE_SUPERADMIN"
echo "Start Odoo service: sudo systemctl start $OE_USER"
echo "Stop Odoo service: sudo systemctl stop $OE_USER"
echo "Restart Odoo service: sudo systemctl restart $OE_USER"
if [ $INSTALL_NGINX = "True" ]; then
  echo "Nginx configuration file: /etc/nginx/sites-available/$OE_USER"
fi
echo -e "\n========================================================================="
echo " now open nano /home/$OE_USER/.bashrc and add this line at the end of file // source /home/$OE_USER/venv/bin/activate \\ then sudo passwd $OE_USER"
echo " now open nano /etc/postgresql/17/main/postgresql.conf and uncomment 2 parameters log_rotation_age = 1d & log_truncate_on_rotation = on"

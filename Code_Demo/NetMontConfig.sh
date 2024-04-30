#!/bin/bash/
echo "------------------------------------Network Monitor Configuration------------------------------------"
cd
echo "------------------Installing Apache2 Server------------------"
sudo apt update
#sudo apt upgrade -y
sudo apt install apache2      #Downloading apache2
sudo systemctl enable apache2 #Enabling apache2
sudo systemctl start apache2  #starting apache2

echo "Installing website files..."
cd Desktop
sudo unzip /home/kali/Desktop/Website.zip
#Moving the files in the Website directory to the apache server directory
sudo mv /home/kali/Desktop/Website/* /var/www/html/  
sudo systemctl restart apache2

echo "------------------Installing SSH Server------------------"
#sudo rm /etc/ssh/ssh_host_* # Removes existing SSH host keys
#sudo dpkg-reconfigure openssh-server # Reconfigures OpenSSH server
#sudo service ssh restart #Restarts the SSH service

cd
mkdir NetMonitor #Makes a new directory called NetNonitor
cd NetMonitor    #Changes directory to NetMonitor

echo "------------------Installing Zerotier------------------"
#sudo wget https://download.zerotier.com/debian/buster/pool/main/z/zerotier-one/zerotier-one_1.4.6_arm64.deb #Downloads the ZeroTier package
#sudo dpkg -i zerotier-one_1.4.6_arm64.deb #Installs the downloaded ZeroTier package.
#sudo update-rc.d zerotier-one enable      #Enables ZeroTier to start automatically during system boot.
#sudo zerotier-cli join 60ee7c034a09759a   #Joins RaspberryPi to the specified ZeroTier network with the given network ID.

echo "------------------------------------Installing Prometheus------------------------------------"
wget https://github.com/prometheus/prometheus/releases/download/v2.51.1/prometheus-2.51.1.linux-arm64.tar.gz   #Download prometheus form GitHub
tar xvf prometheus-2.51.1.linux-arm64.tar.gz   #Extracting the archive file

cd
cd NetMonitor/prometheus-2.51.1.linux-arm64   #Changes directory to prometheus-2.51.1.linux-arm64

echo "global:
  scrape_interval: 15s 
  

scrape_configs:
  # The job name is added as a label \`job=<job_name>\` to any timeseries scraped from this config.
  - job_name: \"prometheus\"
    static_configs:
      - targets: [\"localhost:9090\"] " > prometheus.yml  #Writing initial config to prometheus.yml

echo "Firewall configuration..."
sudo apt install firewalld  #Download firewalld which is a firewall management tool for linux operating systems
sudo systemctl start firewalld   #Start firewalld
sudo systemctl enable firewalld  #Enable firewalld
#sudo systemctl status firewalld #Check the status of firewalld
 
sudo firewall-cmd --permanent --zone=public --add-port=9090/tcp	 #To allow Prometheus
sudo firewall-cmd --permanent --add-service=http		 #to allow Webpage
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload  #Reload the firewall configuration to apply any changes that have been made

      
echo "------------------------------------Installing Node-Exporter------------------------------------"
cd
cd NetMonitor #Change directory to NetMonitor
wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-arm64.tar.gz   #Download Node-exporter from Github
tar -xvf node_exporter-1.0.1.linux-arm64.tar.gz    #Extracting the archive file

echo "Creating a Node Exporter user, required directories, and making prometheus user as the owner of those directories."
sudo groupadd -f node_exporter   #Adding a new group to the system called node-exporter
#Create a new user and assign it to the group node-exporter, without creating a home directory for the new user to disable its ability to log to the system
sudo useradd -g node_exporter --no-create-home --shell /bin/false node_exporter
sudo mkdir /etc/node_exporter    #Create a new dirctory
sudo chown node_exporter:node_exporter /etc/node_exporter  #Change the ownership to the user and the group, so they have necessary permissions

echo "Copying files..."
mv node_exporter-1.0.1.linux-arm64 node_exporter-files  #Move the directory node_exporter-1.0.1.linux-arm64 to node_exporter-files 
sudo cp node_exporter-files/node_exporter /usr/bin/  #Copy the file node-exporter from directory node_exporter-files to the /usr/bin/ directory
sudo chown node_exporter:node_exporter /usr/bin/node_exporter #Change the ownership to the user and the group, so they have necessary permissions

echo "Creating Service..."
sudo touch /usr/lib/systemd/system/node_exporter.service  #Creating a service file
sudo chmod 777 /usr/lib/systemd/system/node_exporter.service #Give the node-exporter.service file premission to read, write and execute

sudo echo "[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/bin/node_exporter \
  --web.listen-address=:9200

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/node_exporter.service

echo "Permission configuration..."
sudo chmod 664 /usr/lib/systemd/system/node_exporter.service  #Give read and write permission to the owner and the group while the other have only read permission

echo "Prometheus Configuration..."
cd
cd NetMonitor/prometheus-2.51.1.linux-arm64  #Change directory to prometheus-2.51.1.linux-arm64
sudo echo " 
  - job_name: \"node\"
    static_configs:
      - targets: [\"localhost:9200\"] " >> prometheus.yml  #Appending to prometheus.yml file

sudo firewall-cmd --permanent --zone=public --add-port=9200/tcp  #Add a rule to the firewall to allow incoming TCP traffic on port 9200, and it makes the rule permanent 
sudo firewall-cmd --reload  #Reload the firewall configuration to apply any changes that have been made


echo "------------------------------------Installing SNMP-Exporter------------------------------------"
cd
cd NetMonitor #Change directory to NetMonitor
wget https://github.com/prometheus/snmp_exporter/releases/download/v0.19.0/snmp_exporter-0.19.0.linux-arm64.tar.gz #Download snmp-exporter from GitHub 
tar xzf snmp_exporter-0.19.0.linux-arm64.tar.gz #Extracting the archive file

cd snmp_exporter-0.19.0.linux-arm64 #Change directory to snmp_exporter-0.19.0.linux-arm64
sudo cp ./snmp_exporter /usr/local/bin/snmp_exporter  #Copy snmp-exporter to /usr/local/bin/
sudo cp ./snmp.yml /usr/local/bin/snmp.yml  #Copy snmp.yml to /usr/local/bin/

cd /usr/local/bin/ 
./snmp_exporter -h #to Check for the snmp port (9116)

echo "adding user (prometheus)..."
#you can check if you already have prometheus user: grep '^prometheus:' /etc/passwd
#Otherwise
sudo useradd --system prometheus #Create a new user

echo "Creating Service..."
sudo touch /etc/systemd/system/snmp-exporter.service     #Creating service file  
sudo chmod 777 /etc/systemd/system/snmp-exporter.service #Give the snmp-exporter.service file premission to read, write and execute


sudo echo "[Unit]
Description=Prometheus SNMP Exporter Service
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/snmp_exporter --config.file=\"/usr/local/bin/snmp.yml\"

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/snmp-exporter.service


echo "Configuring Prometheus..."
cd 
cd NetMonitor/prometheus-2.51.1.linux-arm64  #Change directory to prometheus-2.51.1.linux-arm64
sudo echo " 
  - job_name: \"snmp\" # Service
    static_configs:
      - targets: ['127.0.0.1:9116']" >> prometheus.yml  #Appending to prometheus.yml file
echo "target ip: 127.0.0.1"

sudo firewall-cmd --permanent --zone=public --add-port=9116/tcp  #To allow SNMP-Exporter
sudo firewall-cmd --reload  #Reload the firewall configuration to apply any changes that have been made

echo "------------------------------------Installing Blackbox-Exporter------------------------------------"
cd 
cd NetMonitor  #Change directory to NetMonitor
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.14.0/blackbox_exporter-0.14.0.linux-arm64.tar.gz #Download blackbox-exporter from GitHub 
tar xvzf blackbox_exporter-0.14.0.linux-arm64.tar.gz #Extracting the archive file

cd blackbox_exporter-0.14.0.linux-arm64 #Change directory to blackbox_exporter-0.14.0.linux-arm64
./blackbox_exporter -h   #To check for the port (9115)

echo "Setting up files..."
sudo mv blackbox_exporter /usr/local/bin #Move blackbox-exporter to /usr/local/bin
sudo mkdir -p /etc/blackbox              #Make a new directory
sudo mv blackbox.yml /etc/blackbox  #Move blackbox.yml to the new directory that has been created
sudo useradd -rs /bin/false blackbox #create a new user called blackbox
sudo chown blackbox:blackbox /usr/local/bin/blackbox_exporter  #Change the ownership of the file to the new user
sudo chown -R blackbox:blackbox /etc/blackbox/*  #Change the ownership of all files and directories in /etc/blackbox/ to the user the group blackbox

echo "BlackBox Service Configuration..."
cd /lib/systemd/system  #Change directory to /lib/systemd/system 
sudo touch blackbox.service #Creating a service file
sudo chmod 777 blackbox.service #Give the snmp-exporter.service file premission to read, write and execute

#Writing COnfiguration to the blackbox service file
sudo echo "[Unit]
Description=Blackbox Exporter Service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=blackbox
Group=blackbox
ExecStart=/usr/local/bin/blackbox_exporter \
  --config.file=/etc/blackbox/blackbox.yml \
  --web.listen-address=\":9115\"

Restart=always

[Install]
WantedBy=multi-user.target " > blackbox.service  


echo "Prometheus configuratinon..."
cd
cd NetMonitor/prometheus-2.51.1.linux-arm64/
echo "
  - job_name: \"blackbox\"
    static_configs:
      - targets: ['127.0.0.1:9115'] " >> prometheus.yml  #Appending to prometheus.yml file
echo "target: 127.0.0.1"

sudo firewall-cmd --permanent --zone=public --add-port=9115/tcp  #To allow Blackbox-Exporter
sudo firewall-cmd --reload  #Reload the firewall configuration to apply any changes that have been made

echo "------------------------------------Installing Grafana------------------------------------"
cd
cd NetMonitor  #Changes directory to NetMonitor
echo "Unpacking..."
#Installs necessary packages without prompting for confirmation
sudo apt-get install -y adduser libfontconfig1 musl
#Downloads Grafana package from official source
wget https://dl.grafana.com/oss/release/grafana_10.4.2_arm64.deb

echo "Setting up Grafana..."
#Installs Grafana package
sudo dpkg -i grafana_10.4.2_arm64.deb

sudo firewall-cmd --permanent --zone=public --add-port=3000/tcp  #To allow Grafana
sudo firewall-cmd --reload  #Reload the firewall configuration to apply any changes that have been made


echo "------------------------Network Monitor Configuration Completed!----------------------------"
 

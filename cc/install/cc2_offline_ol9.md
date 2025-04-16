# Instructions on how to install CC 2.X on Oracle Linux 9 (OL9).

##### References
* https://docs.severalnines.com/docs/clustercontrol/installation/offline-installation/

#### Set some environment variables
NOTE: you need to have actual values for the variables in curly brackets below.
```
export CONTROLLER_HOST_IPV4_ADDR={HOST_IPV4_ADDR}
export CONTROLLER_HOSTNAME=$HOSTNAME
export CONTROLLER_ID=$(uuidgen)
export RPC_TOKEN=$(uuidgen | tr -d '-')
export DB_ROOT_USER_PASSWORD="{DB_ROOT_USER_PASSWORD}"
export DB_CMON_USER_PASSWORD="{DB_CMON_USER_PASSWORD}"
# echo the env variables
echo $CONTROLLER_HOST_IPV4_ADDR
echo $CONTROLLER_HOSTNAME
echo $CONTROLLER_ID
echo $RPC_TOKEN
echo $DB_ROOT_USER_PASSWORD
echo $DB_CMON_USER_PASSWORD
```

```
sudo sed -i 's|SELINUX=enforcing|SELINUX=disabled|g' /etc/selinux/config
sudo setenforce 0
sudo systemctl stop firewalld 
sudo systemctl disable firewalld
sudo systemctl status firewalld 
```

```
# OEL9
sudo dnf install -y oracle-epel-release-el9
sudo dnf config-manager --set-enabled ol9_developer_EPEL
sudo dnf update -y
sudo dnf config-manager --set-enabled ol9_codeready_builder
```

```
# OEL9
sudo yum -y install wget dmidecode hostname python3 mariadb mariadb-server httpd mod_ssl net-tools
```

**NOTE** Please watch the changelog for latest binary names and update the `wget` to pull-down the latest from the changelog

[ClusterControl changelog](https://support.severalnines.com/hc/en-us/articles/212425943-ChangeLog)

[Link to package list](https://severalnines.com/downloads/cmon/)
```
mkdir packages
cd packages
wget https://severalnines.com/downloads/cmon/clustercontrol-clud-2.3.2-423-x86_64.rpm
wget https://severalnines.com/downloads/cmon/clustercontrol-cloud-2.3.2-423-x86_64.rpm
wget https://severalnines.com/downloads/cmon/clustercontrol-controller-2.3.2-12518-x86_64.rpm
wget https://severalnines.com/downloads/cmon/clustercontrol2-2.3.2-1949.x86_64.rpm
wget https://severalnines.com/downloads/cmon/clustercontrol-ssh-2.3.2-213-x86_64.rpm
wget https://severalnines.com/downloads/cmon/clustercontrol-notifications-2.3.2-373-x86_64.rpm
wget https://repo.severalnines.com/s9s-tools/CentOS_9/x86_64/s9s-tools-1.9-31.1.x86_64.rpm
#wget https://severalnines.com/downloads/cmon/clustercontrol-controller-dbg-2.2.0-10707-x86_64.rpm
#wget https://severalnines.com/downloads/cmon/clustercontrol-proxy-2.2.5-49-x86_64.rpm
```

```
sudo dnf -y install clustercontrol*
sudo dnf -y install s9s-tools*
```

```
sudo systemctl start mariadb
sudo systemctl status mariadb
sudo systemctl enable mariadb
sudo mysqladmin -uroot password "$DB_ROOT_USER_PASSWORD"
# Test connecting
mysql -uroot -p$DB_ROOT_USER_PASSWORD -e 'SHOW DATABASES'
```

**STOP!!!** Collect the DB_CMON_USER_PASSWORD, CONTROLLER_HOST_IPV4_ADDR and CONTROLLER_HOSTNAME
```
# NOTE: Please substitute actual values for DB_CMON_USER_PASSWORD, CONTROLLER_HOST_IPV4_ADDR
mysql -uroot -p$DB_ROOT_USER_PASSWORD -e 'GRANT ALL PRIVILEGES ON *.* TO "cmon"@"localhost" IDENTIFIED BY "{DB_CMON_USER_PASSWORD}" WITH GRANT OPTION'
mysql -uroot -p$DB_ROOT_USER_PASSWORD -e 'GRANT ALL PRIVILEGES ON *.* TO "cmon"@"127.0.0.1" IDENTIFIED BY "{DB_CMON_USER_PASSWORD}" WITH GRANT OPTION'
mysql -uroot -p$DB_ROOT_USER_PASSWORD -e 'GRANT ALL PRIVILEGES ON *.* TO "cmon"@"{CONTROLLER_HOST_IPV4_ADDR}" IDENTIFIED BY "{DB_CMON_USER_PASSWORD}" WITH GRANT OPTION'
mysql -uroot -p$DB_ROOT_USER_PASSWORD -e 'GRANT ALL PRIVILEGES ON *.* TO "cmon"@"{CONTROLLER_HOSTNAME}" IDENTIFIED BY "{DB_CMON_USER_PASSWORD}" WITH GRANT OPTION'
mysql -uroot -p$DB_ROOT_USER_PASSWORD -e 'FLUSH PRIVILEGES'
```

##### Initialize CMON

1st attempt:
```
sudo cmon --init \
          --mysql-hostname="127.0.0.1" \
          --mysql-port="3306" \
          --mysql-username="cmon" \
          --mysql-password="$DB_CMON_USER_PASSWORD" \
          --mysql-database="cmon" \
          --hostname="$CONTROLLER_HOSTNAME" \
          --rpc-token="$RPC_TOKEN" \
          --controller-id="$CONTROLLER_ID"
#
sudo cat /etc/cmon.cnf
```

Clean the database in preperation for attempt #2.
```
mysql -uroot -p$DB_ROOT_USER_PASSWORD -e 'DROP DATABASE cmon'
sudo rm /etc/cmon.cnf
```

2nd attempt:
```
sudo cmon --init \
          --mysql-hostname="127.0.0.1" \
          --mysql-port="3306" \
          --mysql-username="cmon" \
          --mysql-password="$DB_CMON_USER_PASSWORD" \
          --mysql-database="cmon" \
          --hostname="$CONTROLLER_HOSTNAME" \
          --rpc-token="$RPC_TOKEN" \
          --controller-id="$CONTROLLER_ID"
#
sudo cat /etc/cmon.cnf
```

##### Configure services
```
sudo vi /etc/default/cmon
EVENTS_CLIENT="http://127.0.0.1:9510"
CLOUD_SERVICE="http://127.0.0.1:9518"
```

##### Setup CERT names
```
mkdir  -p /tmp/ssl
cat > /tmp/ssl/v3.ext << EOF
basicConstraints = CA:FALSE
#authorityKeyIdentifier=keyid,issuer
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = DNS:dev.severalnines.local
EOF
```

##### Setup CERTs
```
openssl genrsa -out /tmp/ssl/server.key 2048
openssl req -new -key /tmp/ssl/server.key -out /tmp/ssl/server.csr \
        -addext "subjectAltName = DNS:dev.severalnines.local" \
        -subj "/C=SE/ST=Stockholm/L=Stockholm/O='Severalnines AB'/OU=Severalnines/CN=*.severalnines.local/emailAddress=support@severalnines.com"
openssl x509 -req -extfile /tmp/ssl/v3.ext -days 1825 -sha256 -in /tmp/ssl/server.csr -signkey /tmp/ssl/server.key -out /tmp/ssl/server.crt
sudo mkdir -p /etc/ssl/private
sudo cp -f /tmp/ssl/server.crt /etc/ssl/certs/s9server.crt
sudo cp -f /tmp/ssl/server.key /etc/ssl/private/s9server.key
```

##### Setup webserver security config
```
#sudo su -
#
cat > /tmp/security.conf << EOF
Header set X-Frame-Options: "sameorigin"
EOF
#
sudo mv /tmp/security.conf /etc/httpd/conf.d/security.conf
#
sudo cp /usr/share/cmon/apache/cc-frontend.conf /etc/httpd/conf.d/cc-webapp.conf
#
sudo sed -i "s|cc2.severalnines.local|$CONTROLLER_HOSTNAME|g" /etc/httpd/conf.d/cc-webapp.conf
sudo sed -i "s|severalnines.local|$CONTROLLER_HOSTNAME.local|g" /etc/httpd/conf.d/cc-webapp.conf
sudo sed -i "s|Listen 9443|#Listen 443|g" /etc/httpd/conf.d/cc-webapp.conf
sudo sed -i "s|9443|443|g" /etc/httpd/conf.d/cc-webapp.conf
#
#exit
```

##### Enable daemon auto start on reboots
```
sudo systemctl enable cmon cmon-ssh cmon-events cmon-cloud httpd
sudo systemctl start cmon
watch sudo ls -ltr /var/lib/cmon/ca/cmon
# Wait for rpc_tls.* files to appear in the above directory
CTRL-C
sudo systemctl start cmon-ssh cmon-events cmon-cloud httpd
netstat -lntpd |grep 9501
```

#### create dba user
```
s9s user --create \
  --generate-key \
  --controller="https://localhost:9501" \
  --group=admins dba
```

#### create ccsetup user
```
export S9S_USER_CONFIG=/tmp/ccsetup.conf
s9s user --create \
  --generate-key \
  --controller="https://localhost:9501" \
  --email-address="cc@example.com" \
  --group=admins ccsetup
rm $S9S_USER_CONFIG
unset S9S_USER_CONFIG
```

```
s9s user --list
# You must see the following users listed.
system
nobody
admin
ccsetup
dba
```

##### Point the browser to the host and register
https://{CONTROLLER_HOST_IPV4_ADDR}

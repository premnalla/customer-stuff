# PXC 5.7 Installation and configuration on CentOS 7

### References
[Medium article](https://medium.com/swlh/percona-xtradb-cluster-5-7-b17e2aa55bbe)

### Cloud image
[CentOS7 Cloud image](https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2) 

### Openstack image creation
```shell
openstack image create --progress --disk-format qcow2 --file ./CentOS-7-x86_64-GenericCloud.qcow2 "CentOS (7) Generic Cloud (2022-11-12)"
```

**NOTE**: CentOS 7 VM on Openstack - Requires at least 10GB of storage

## The real deal starts now...

Take inventory of hosts. We assume PXC setup on three target hosts namely,
1. HOST 1 - (Env variable NODE1_IP=10.0.0.152) (hostname: pxc57-cent7-1)
2. HOST 2 - (Env variable NODE1_IP=10.0.0.235) (hostname: pxc57-cent7-2)
3. HOST 3 - (Env variable NODE1_IP=10.0.0.187) (hostname: pxc57-cent7-3)

Getting to the hosts: `from jumphost: ssh centos@<host>`

### On ALL hosts, do the following
#### Fixing mirror list after VM starts with cloud image
```shell
#sudo su -
sudo sed -i 's/mirror\.centos\.org/vault.centos.org/g' /etc/yum.repos.d/CentOS-*.repo
sudo sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/CentOS-*.repo
sudo sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/CentOS-*.repo
sudo yum update -y
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
sudo reboot
```

#### Install PXC 5.7 from repos
```shell
sudo yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
sudo percona-release enable pxc-57 release
sudo percona-release setup -y pxc-57
sudo yum install -y Percona-XtraDB-Cluster-57
mysql --version
#sudo systemctl cat mysql
```

### On host #1, do the following
#### Setup my.cnf and secrets-backup.cnf
NOTE: the [secrets-backup.cnf](./secrets-backup.cnf) and [my.cnf](./my.cnf) TEMPLATES are available in this github directory.
Copy the contents of the files to the target host by editing the respective files as shown below.
```shell
sudo vi /etc/my.cnf.d/secrets-backup.cnf
sudo vi /etc/my.cnf
sudo rm /var/log/mysqld.log
sudo mkdir /var/log/mysql
sudo mkdir -p /etc/mysql/certs
sudo chown -R mysql /etc/my.cnf /etc/my.cnf.d /var/log/mysql /etc/mysql
sudo ls -ld /etc/my.cnf /etc/my.cnf.d /var/log/mysql /etc/mysql
```

Change my.cnf and secrets-backup.cnf params...
Make a copy of [env.sh](./env.sh) in `/tmp`
```shell
vi /tmp/env.sh
source /tmp/env.sh
sudo sudo sed -i 's/^wsrep_node_address=.*/wsrep_node_address='"$NODE_IP"'/g' /etc/my.cnf
sudo sudo sed -i 's/^wsrep_cluster_name=.*/wsrep_cluster_name='"$CLUSTER_NAME"'/g' /etc/my.cnf
sudo sudo sed -i 's/^wsrep_node_name=.*/wsrep_node_name='"$NODE_NAME"'/g' /etc/my.cnf
```

#### Start mysql and make some changes and additions... 
```shell
sudo ls -l /var/lib/mysql
sudo systemctl start mysql
sudo systemctl status mysql
sudo ls -l /var/lib/mysql
sudo systemctl stop mysql
sudo su - mysql
mv /var/lib/mysql/*.pem /etc/mysql/certs
ls -l /etc/mysql/certs
tar cvfz /tmp/certs.tgz /etc/mysql/certs
exit
```

```shell
source /tmp/env.sh
sudo sudo sed -i '/encrypt=/s/^#//g' /etc/my.cnf
sudo sudo sed -i '/ssl-key=/s/^#//g' /etc/my.cnf
sudo sudo sed -i '/ssl-ca=/s/^#//g' /etc/my.cnf
sudo sudo sed -i '/ssl-cert=/s/^#//g' /etc/my.cnf
#
sudo sudo sed -i '/ssl_cert=/s/^#//g' /etc/my.cnf
sudo sudo sed -i '/ssl_key=/s/^#//g' /etc/my.cnf
sudo sudo sed -i '/ssl_ca=/s/^#//g' /etc/my.cnf
#
sudo systemctl start mysql
sudo systemctl status mysql
sudo vi /var/log/mysql/mysqld.log
# search for any SSL or TLS errors
```

#### Change root password and create backup user and password...
```shell
source /tmp/env.sh
export MYSQLTMPROOTPW=$(sudo grep 'temporary password' /var/log/mysql/mysqld.log | awk 'NF{ print $NF }')
mysql --connect-expired-password -u root -p$MYSQLTMPROOTPW -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '"$MYSQLROOTPW"';"
mysql -u root -p$MYSQLROOTPW -e "select version();"
mysql -u root -p$MYSQLROOTPW -e "CREATE USER '"$BACKUPUSER"'@'localhost' IDENTIFIED BY '"$BACKUPUSER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '"$BACKUPUSER"'@'localhost';"
mysql -u root -p$MYSQLROOTPW -e "FLUSH PRIVILEGES;"
sudo systemctl stop mysql
```

#### Update wsrep_cluster_address
**NOTE**: You MUST update NODE2_IP and NODE3_IP values below...
```shell
export NODE2_IP=10.0.0.227
export NODE3_IP=10.0.0.20
sudo sudo sed -i 's/^wsrep_cluster_address=.*/wsrep_cluster_address='gcomm:\\/\\/"$NODE_IP","$NODE2_IP","$NODE3_IP"'/g' /etc/my.cnf
```

#### Bootstrap the first node
```shell
source /tmp/env.sh
sudo systemctl start mysql@bootstrap.service
sudo systemctl status mysql@bootstrap.service
mysql -u root -p$MYSQLROOTPW -e "show status like 'wsrep_cluster_size';"
mysql -u $BACKUPUSER -p$BACKUPUSER_PW -e "select version();"
```

#### Push the config files and certs/keys fron 1st host to the 2nd and 3rd hosts
```shell
sudo scp /etc/my.cnf centos@$NODE2_IP:/tmp
sudo scp /etc/my.cnf.d/secrets-backup.cnf centos@$NODE2_IP:/tmp
sudo scp /etc/my.cnf centos@$NODE3_IP:/tmp
sudo scp /etc/my.cnf.d/secrets-backup.cnf centos@$NODE3_IP:/tm
```

### On hosts 2 and 3, do the following...
**NOTE**: perform the following steps on **2nd** and **3rd** hosts
```shell
source /tmp/env.sh
sudo mv /tmp/my.cnf to /etc
sudo mv /tmp/secrets-backup.cnf /etc/my.cnf.d
sudo sudo sed -i 's/^wsrep_node_address=.*/wsrep_node_address='"$NODE_IP"'/g' /etc/my.cnf
sudo sudo sed -i 's/^wsrep_node_name=.*/wsrep_node_name='"$NODE_NAME"'/g' /etc/my.cnf
sudo rm /var/log/mysqld.log
sudo mkdir /var/log/mysql
sudo mkdir -p /etc/mysql/certs
sudo chown -R mysql /etc/my.cnf /etc/my.cnf.d /var/log/mysql
sudo ls -ld /etc/my.cnf /etc/my.cnf.d /var/log/mysql /etc/mysql
```

### Start mysql on the 2nd host
Start mysql and check the status of the cluster size. Make sure it is **> 1**
```shell
source /tmp/env.sh
sudo systemctl start mysql
sudo systemctl status mysql
mysql -u root -p$MYSQLROOTPW -e "show status like 'wsrep_cluster_size';"
```

### Start mysql on the 3rd host
**NOTE**: Make sure the **2nd** host has **successfully joined the cluster** prior to attmpting to start the 3rd node
```shell
source /tmp/env.sh
sudo systemctl start mysql
sudo systemctl status mysql
mysql -u root -p$MYSQLROOTPW -e "show status like 'wsrep_cluster_size';"
```

### Take host 1 out of bootstrap and start it in normal mode
**NOTE**: Make sure the **2nd** and 3rd hosts have **successfully joined the cluster** prior to attmpting this step
```shell
source /tmp/env.sh
sudo systemctl stop mysql@bootstrap.service
sudo systemctl start mysql
sudo systemctl status mysql
mysql -u root -p$MYSQLROOTPW -e "show status like 'wsrep_cluster_size';"
```




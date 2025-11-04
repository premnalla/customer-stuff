# PXC 5.7 Installation and configuration on Rocky 8

**NOTE**: Rocky 8 VM on Openstack - Requires at least 10GB of storage

## The real deal starts now...

Take inventory of hosts. We assume PXC setup on three target hosts namely,
1. HOST 1 - (Env variable NODE1_IP=10.0.0.152) (hostname: pxc57-rocky8)

Getting to the hosts: `from jumphost: ssh centos@<host>`

### On ALL hosts, do the following
#### Install PXC 5.7 from repos
```shell
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
sudo yum update -y
sudo reboot
```

#### Install PXC 5.7 from repos
```shell
sudo yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
sudo percona-release enable pxc-57 release
sudo percona-release setup -y pxc-57
sudo yum clean all
sudo yum module disable mysql -y
sudo yum list Percona*
sudo yum install -y Percona-XtraDB-Cluster-57
mysql --version
#sudo systemctl cat mysql
```

### On host #1, do the following
#### Setup my.cnf and secrets-backup.cnf and env.sh
NOTE: the [secrets-backup.cnf](./secrets-backup.cnf) and [my.cnf](./my.cnf) TEMPLATES are available in this github directory.
Copy the contents of the files to the target host by editing the respective files as shown below.

**IMPORTANT**: 
1. Create `/tmp/env.sh` file. You must change the values of passwords and users as appropriate in this file !!!
2. **Merge** values of **my.cnf** with what you may currently have, especially the `innodb` parameters, `wsrep_*` params, etc !!!

```shell
sudo vi /etc/my.cnf.d/secrets-backup.cnf
sudo vi /etc/my.cnf
sudo rm /var/log/mysqld.log
sudo mkdir /var/log/mysql
sudo mkdir -p /etc/mysql/certs
sudo chown -R mysql /etc/my.cnf /etc/my.cnf.d /var/log/mysql /etc/mysql
sudo ls -ld /etc/my.cnf /etc/my.cnf.d /var/log/mysql /etc/mysql
```

Make a copy of template [env.sh](../upgrade_supporting_material/env.sh) in `/tmp`. Then make the changes to env variables in it.
```shell
vi /tmp/env.sh          # IMPORTANT: make the necessary changes here !!!
```

Change my.cnf and secrets-backup.cnf params...
```shell
source /tmp/env.sh
#export CLUSTER_NAME="pxc57_80-cluster" # NOTE: even though we are installing PXC 5.7, we will be upgrading it to 8.0
#export SERVER_ID=12000
sudo sudo sed -i 's/^wsrep_node_address=.*/wsrep_node_address='"$NODE_IP"'/g' /etc/my.cnf
sudo sudo sed -i 's/^wsrep_node_name=.*/wsrep_node_name='"$NODE_NAME"'/g' /etc/my.cnf
sudo sudo sed -i 's/^wsrep_cluster_name=.*/wsrep_cluster_name='"$CLUSTER_NAME"'/g' /etc/my.cnf
sudo sudo sed -i 's/^server_id=.*/server_id='"$SERVER_ID"'/g' /etc/my.cnf
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
sudo systemctl stop mysql
sudo systemctl status mysql
```

# STOP here for PXC 5.7 to 8.0 upgrade on this host... If not for upgrade, please continue.

#### Change root password and create backup user and password...
**NOTE**: generate a root password from a password generator and replace below.
```shell
source /tmp/env.sh
sudo systemctl start mysql
sudo systemctl status mysql
export MYSQLTMPROOTPW=$(sudo grep 'temporary password' /var/log/mysql/mysqld.log | awk 'NF{ print $NF }')
mysql --connect-expired-password -u root -p$MYSQLTMPROOTPW -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '"$MYSQLROOTPW"';"
mysql -u root -p$MYSQLROOTPW -e "select version();"
mysql -u root -p$MYSQLROOTPW -e "CREATE USER '"$BACKUPUSER"'@'localhost' IDENTIFIED BY '"$BACKUPUSER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO '"$BACKUPUSER"'@'localhost';"
mysql -u root -p$MYSQLROOTPW -e "FLUSH PRIVILEGES;"
sudo systemctl stop mysql
```

#### Update wsrep_cluster_address
Nothing to do here...
```shell
#export NODE2_IP=10.0.0.235
#export NODE3_IP=10.0.0.187
#sudo sudo sed -i 's/^wsrep_cluster_address=.*/wsrep_cluster_address='gcomm:\\/\\/"$NODE_IP","$NODE2_IP","$NODE3_IP"'/g' /etc/my.cnf
#sudo sudo sed -i 's/^wsrep_cluster_address=.*/wsrep_cluster_address='gcomm:\\/\\/'/g' /etc/my.cnf
```

#### Bootstrap the first node
```shell
source /tmp/env.sh
sudo systemctl start mysql@bootstrap.service
sudo systemctl status mysql@bootstrap.service
mysql -u root -p$MYSQLROOTPW -e "show status like 'wsrep_cluster_size';"
mysql -u $BACKUPUSER -p$BACKUPUSER_PW -e "select version();"
```

### Take host 1 out of bootstrap and start it in normal mode
**NOTE**: Make sure the **2nd** and 3rd hosts have **successfully joined the cluster** prior to attmpting this step
```shell
sudo systemctl stop mysql@bootstrap.service
sudo systemctl start mysql
sudo systemctl status mysql
```

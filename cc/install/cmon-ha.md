# CMON-HA setup

## References

## Platform details
1. Operating System: Ubuntu 22.04
2. MariaDB version 10.6

## Steps

### Note passwords
mysql root: foo2Bar#Top!
CMON user password: foo2Bar#Top!
CC UI: foo2Bar#Top!Zoo

### Setup name resolution on hosts
**NOTE: Make sure the hosts can resolve with name***
```shell
10.0.0.164 cmon-ha-1 cmon-ha-1
10.0.0.41 cmon-ha-2 cmon-ha-2
10.0.0.114 cmon-ha-3 cmon-ha-3
```

### Setup 1st ClusterControl
#### cmon-ha-1:
```shell
sudo apt update && sudo apt upgrade -y && sudo apt install -y net-tools
wget https://severalnines.com/downloads/cmon/install-cc
chmod +x install-cc
sed -i 's/mysql-server/mariadb-server/g' install-cc
sed -i 's/mysql-client/mariadb-client/g' install-cc
sudo S9S_CMON_PASSWORD='foo2Bar#Top!' S9S_ROOT_PASSWORD='foo2Bar#Top!' S9S_DB_PORT=3306 HOST=cmon-ha-1 ./install-cc --ccv2
```

**Register user via UI**

```shell
sudo systemctl status cmon
sudo systemctl status mariadb

sudo systemctl stop cmon
sudo systemctl status cmon

sudo systemctl stop mariadb
sudo systemctl status mariadb
```

```shell
sudo cat /etc/default/cmon
echo 'RPC_BIND_ADDRESSES="0.0.0.0"' | sudo tee -a /etc/default/cmon
sudo cat /etc/default/cmon
```

**Record the value of cmon_password attribute**

```shell
sudo cat /etc/s9s.conf |grep cmon_password
# example
cmon_password = "ac85b528-adf2-4ce1-8196-6bc6b704a87c"
```

```shell
sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.orig
sudo vi /etc/mysql/my.cnf
[mysqld]
wsrep_on               = ON
wsrep_node_address     = cmon-ha-1   # cmon1 primary IP address
wsrep_node_name        = 'cmon-ha-1'
wsrep_provider         = '/usr/lib/galera/libgalera_smm.so'
wsrep_provider_options = 'gcache.size=1024M;gmcast.segment=0;gcache.recover=yes'
wsrep_cluster_address  = gcomm://cmon-ha-1,cmon-ha-2,cmon-ha-3   # All nodes' IP addresses
wsrep_cluster_name     = 'CMON_HA_Galera'
wsrep_sst_method       = rsync
binlog_format          = 'ROW'
log_error              = /var/log/mysql/error.log
```

```shell
sudo galera_new_cluster
```

```shell
sudo systemctl start mariadb
sudo systemctl status mariadb

sudo systemctl start cmon
sudo systemctl status cmon
```

```shell
s9s user --create \
--generate-key \
--controller="https://localhost:9501" \
--group=admins dba

s9s clusters --list --long

s9s controller --enable-cmon-ha
s9s controller --list --long
```

**NOTE: should see an output like the following**
```
S VERSION     OWNER  GROUP  NAME      IP         PORT COMMENT
l 2.3.2.13372 system admins cmon-ha-1 10.0.0.226 9501 CmonHA just become enabled, starting as leader.
Total: 1 controller(s)
```

#### cmon-ha-2:
```shell
sudo apt update && sudo apt upgrade -y && sudo apt install -y net-tools
wget https://severalnines.com/downloads/cmon/install-cc
chmod +x install-cc
sed -i 's/mysql-server/mariadb-server/g' install-cc
sed -i 's/mysql-client/mariadb-client/g' install-cc
sudo S9S_CMON_PASSWORD='foo2Bar#Top!' S9S_ROOT_PASSWORD='foo2Bar#Top!' S9S_DB_PORT=3306 HOST=cmon-ha-2 ./install-cc --ccv2
```

```shell
sudo systemctl status cmon
sudo systemctl status mariadb

sudo systemctl stop cmon
sudo systemctl status cmon

sudo systemctl stop mariadb
sudo systemctl status mariadb
```

```shell
sudo cat /etc/default/cmon
echo 'RPC_BIND_ADDRESSES="0.0.0.0"' | sudo tee -a /etc/default/cmon
sudo cat /etc/default/cmon
```

**NOTE: replace cmon_password with the value obtained from `cmon-ha-1` host**
```shell
sudo cp /etc/s9s.conf /etc/s9s.conf.1
sudo vi /etc/s9s.conf
# Replace to match that of cmon-ha-1 value !!!
cmon_password = "<REPLACE-ME>"
```

```shell
sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.orig
sudo vi /etc/mysql/my.cnf
[mysqld]
wsrep_on               = ON
wsrep_node_address     = cmon-ha-2   # cmon1 primary IP address
wsrep_node_name        = 'cmon-ha-2'
wsrep_provider         = '/usr/lib/galera/libgalera_smm.so'
wsrep_provider_options = 'gcache.size=1024M;gmcast.segment=0;gcache.recover=yes'
wsrep_cluster_address  = gcomm://cmon-ha-1,cmon-ha-2,cmon-ha-3   # All nodes' IP addresses
wsrep_cluster_name     = 'CMON_HA_Galera'
wsrep_sst_method       = rsync
binlog_format          = 'ROW'
log_error              = /var/log/mysql/error.log
```

```shell
sudo rm -f /var/lib/mysql/grastate.dat

sudo systemctl start mariadb
sudo systemctl status mariadb

sudo systemctl start cmon
sudo systemctl status cmon
```

#### cmon-ha-3:
```shell
sudo apt update && sudo apt upgrade -y && sudo apt install -y net-tools
wget https://severalnines.com/downloads/cmon/install-cc
chmod +x install-cc
sed -i 's/mysql-server/mariadb-server/g' install-cc
sed -i 's/mysql-client/mariadb-client/g' install-cc
sudo S9S_CMON_PASSWORD='foo2Bar#Top!' S9S_ROOT_PASSWORD='foo2Bar#Top!' S9S_DB_PORT=3306 HOST=cmon-ha-3 ./install-cc --ccv2
```

```shell
sudo systemctl status cmon
sudo systemctl status mariadb

sudo systemctl stop cmon
sudo systemctl status cmon

sudo systemctl stop mariadb
sudo systemctl status mariadb
```

```shell
sudo cat /etc/default/cmon
echo 'RPC_BIND_ADDRESSES="0.0.0.0"' | sudo tee -a /etc/default/cmon
sudo cat /etc/default/cmon
```

**NOTE: Replac cmon_password with that from `cmon-ha-1` host**

```shell
sudo cp /etc/s9s.conf /etc/s9s.conf.1
sudo vi /etc/s9s.conf
# Replace to match that of cmon-ha-1 value !!!
cmon_password = "<REPLACE-ME>"
```

```shell
sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.orig
sudo vi /etc/mysql/my.cnf
[mysqld]
wsrep_on               = ON
wsrep_node_address     = cmon-ha-3   # cmon1 primary IP address
wsrep_node_name        = 'cmon-ha-3'
wsrep_provider         = '/usr/lib/galera/libgalera_smm.so'
wsrep_provider_options = 'gcache.size=1024M;gmcast.segment=0;gcache.recover=yes'
wsrep_cluster_address  = gcomm://cmon-ha-1,cmon-ha-2,cmon-ha-3   # All nodes' IP addresses
wsrep_cluster_name     = 'CMON_HA_Galera'
wsrep_sst_method       = rsync
binlog_format          = 'ROW'
log_error              = /var/log/mysql/error.log
```

````shell
sudo rm -f /var/lib/mysql/grastate.dat

sudo systemctl start mariadb
sudo systemctl status mariadb

sudo systemctl start cmon
sudo systemctl status cmon
````

#### From `jumphost`:
```shell
scp -rp cmon-ha-1:/home/ubuntu/.s9s cmon-ha-2:/home/ubuntu
scp -rp cmon-ha-1:/home/ubuntu/.s9s cmon-ha-3:/home/ubuntu
```

#### From `cmon-ha-2`:
```shell
s9s clusters --list --long
s9s controller --list --long
```

#### From `cmon-ha-3`:
```shell
s9s clusters --list --long
s9s controller --list --long
```

#### From `cmon-ha-1`:
```shell
s9s controller --list --long
```
```shell
S VERSION     OWNER  GROUP  NAME             IP            PORT COMMENT
l 2.2.0.10973 system admins ip-172-31-18-151 172.31.18.151 9501 CmonHA just become enabled, starting as leader.
f 2.2.0.10973 system admins ip-172-31-30-229 172.31.30.229 9501 Responding to heartbeats.
f 2.2.0.10973 system admins ip-172-31-28-190 172.31.28.190 9501 Responding to heartbeats.
Total: 3 controller(s)
```

#### From `cmon-ha-2`:
```shell
s9s clusters --list --long
Redirect notification.
```

#### From `cmon-ha-3`:
```shell
s9s clusters --list --long
Redirect notification.
```

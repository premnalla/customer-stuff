# Offline installation and setup of PG using RPMs on RHEL9

#### References
1. [Installing from RPMs](https://medium.com/@guemandeuhassler96/manually-install-postgresql-server-on-linux-a8358d85ec51)

2. [ClusterControl CLI reference guide](https://docs.severalnines.com/clustercontrol/latest/reference-manuals/components/clustercontrol-cli/)

3. [Offline Database Deployment using ClusterControl (Prometheus exporters)](https://docs.severalnines.com/clustercontrol/latest/getting-started/tutorials/day-1-operations/deploy-database-cluster-offline-environment/#offline-database-deployment-using-clustercontrol)

#### Downloads

[Download site for PG - postgresq.org](https://yum.postgresql.org/rpmchart/)

[PG 16 downloads](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/)

As of May 2, 2025

[postgresql16-server](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/postgresql16-server-16.8-1PGDG.rhel9.x86_64.rpm)

[postgresql16](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/postgresql16-16.8-1PGDG.rhel9.x86_64.rpm)

[postgresql16-contrib](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/postgresql16-contrib-16.8-1PGDG.rhel9.x86_64.rpm)

[postgresql16-libs](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/postgresql16-libs-16.8-1PGDG.rhel9.x86_64.rpm)

[pg_stat_monitor](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pg_stat_monitor_16-2.1.1-1PGDG.rhel9.x86_64.rpm)

[pg_partman](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pg_partman_16-5.2.4-1PGDG.rhel9.x86_64.rpm)

[pg_cron](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pg_cron_16-1.6.5-1PGDG.rhel9.x86_64.rpm)

[pg_permissions](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pg_permissions_16-1.3-2PGDG.rhel9.noarch.rpm)

[pgaudit](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pgaudit_16-16.1-1PGDG.rhel9.x86_64.rpm)

[sslutils](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/sslutils_16-1.4-1PGDG.rhel9.x86_64.rpm)

[system_stats](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/system_stats_16-3.2-1PGDG.rhel9.x86_64.rpm)

[set_user](https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/set_user_16-4.1.0-1PGDG.rhel9.x86_64.rpm)

## Decide on the naming convention for the Postgres instance
Example:
1. _**PG_VERSION**_ - (PostgreSQL version: "16")
2. _**PG_INSTANCE_ID**_ - (PostgreSQL instance identifier: "6432" (**NOTE: this can by any string. E.g. it can be "app1" instead of "6432"))
3. _**PG_INSTANCE_DATA_DIR**_ - The postgres instance's data directory


## Setup the target database host(s)

### Download RPMs
```
mkdir pg16rpms
cd pg16rpms
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/postgresql16-server-16.8-1PGDG.rhel9.x86_64.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/postgresql16-16.8-1PGDG.rhel9.x86_64.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/postgresql16-contrib-16.8-1PGDG.rhel9.x86_64.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/postgresql16-libs-16.8-1PGDG.rhel9.x86_64.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pg_stat_monitor_16-2.1.1-1PGDG.rhel9.x86_64.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pg_partman_16-5.2.4-1PGDG.rhel9.x86_64.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pg_cron_16-1.6.5-1PGDG.rhel9.x86_64.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pg_permissions_16-1.3-2PGDG.rhel9.noarch.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/pgaudit_16-16.1-1PGDG.rhel9.x86_64.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/sslutils_16-1.4-1PGDG.rhel9.x86_64.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/system_stats_16-3.2-1PGDG.rhel9.x86_64.rpm
wget https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-9-x86_64/set_user_16-4.1.0-1PGDG.rhel9.x86_64.rpm
```

```
ll
total 10208
-rw-r--r--. 1 cloud-user cloud-user   45798 Dec 15 18:13 pg_cron_16-1.6.5-1PGDG.rhel9.x86_64.rpm
-rw-r--r--. 1 cloud-user cloud-user  212305 Jan  2 18:54 pg_partman_16-5.2.4-1PGDG.rhel9.x86_64.rpm
-rw-r--r--. 1 cloud-user cloud-user   13540 Jul 30  2024 pg_permissions_16-1.3-2PGDG.rhel9.noarch.rpm
-rw-r--r--. 1 cloud-user cloud-user   41645 Feb 24 06:26 pg_stat_monitor_16-2.1.1-1PGDG.rhel9.x86_64.rpm
-rw-r--r--. 1 cloud-user cloud-user   28435 Mar  3 06:44 pgaudit_16-16.1-1PGDG.rhel9.x86_64.rpm
-rw-r--r--. 1 cloud-user cloud-user 1855625 Feb 18 07:51 postgresql16-16.8-1PGDG.rhel9.x86_64.rpm
-rw-r--r--. 1 cloud-user cloud-user  747912 Feb 18 07:51 postgresql16-contrib-16.8-1PGDG.rhel9.x86_64.rpm
-rw-r--r--. 1 cloud-user cloud-user  342564 Feb 18 07:51 postgresql16-libs-16.8-1PGDG.rhel9.x86_64.rpm
-rw-r--r--. 1 cloud-user cloud-user 7055789 Feb 18 07:51 postgresql16-server-16.8-1PGDG.rhel9.x86_64.rpm
-rw-r--r--. 1 cloud-user cloud-user   27133 Sep  9  2024 set_user_16-4.1.0-1PGDG.rhel9.x86_64.rpm
-rw-r--r--. 1 cloud-user cloud-user   24976 Aug 16  2024 sslutils_16-1.4-1PGDG.rhel9.x86_64.rpm
-rw-r--r--. 1 cloud-user cloud-user   29186 Aug 28  2024 system_stats_16-3.2-1PGDG.rhel9.x86_64.rpm
```

### Install RPMs
```
sudo dnf install -y *.rpm
```

### Post-installation
#### Create service unit
**Let's assume the Postgres server will be listening on port _6432_**

**STOP!!!** - Make the appropriate substitution for _PG_VERSION_ and _PG_INSTANCE_ID_ and _PG_INSTANCE_DATA_DIR_

```
export PG_VERSION=16

# NOTE: this is any unique identifying string such as "app1" instead of "6432". "6432" has been used here for convenience
export PG_INSTANCE_ID=app1 

# The following is the default data dir for RHEL 8 and 8
export PG_INSTANCE_DATA_DIR=/var/lib/pgsql/$PG_VERSION/$PG_INSTANCE_ID
```

```
sudo su - 
cd /etc/systemd/system
# STOP!!! - Make the appropriate substitution for PG_VERSION and PG_INSTANCE_ID
export PG_VERSION=16
export PG_INSTANCE_ID=app1
export PG_SERVICE_UNIT="postgresql-$PG_VERSION-$PG_INSTANCE_ID.service"
echo $PG_SERVICE_UNIT
cp /lib/systemd/system/postgresql-$PG_VERSION.service ./$PG_SERVICE_UNIT 
mkdir -p $PG_SERVICE_UNIT.d
vi $PG_SERVICE_UNIT.d/override.conf
[Service]
# Make sure the directory is accurate. Make changes if necessary 
Environment=PGDATA=/var/lib/pgsql/16/app1
SendSIGKILL=no
:wq

exit
```

```
# Make sure the PG service is accurate!!!
echo $PG_VERSION      # make sure it is set
echo $PG_INSTANCE_ID  # make sure it is set
export PG_SERVICE="postgresql-$PG_VERSION-$PG_INSTANCE_ID" # NOTE: it doesn't have he ".service" extension
echo $PG_SERVICE
sudo postgresql-$PG_VERSION-setup initdb $PG_SERVICE
# You should see an output like the following...
Initializing database ... OK
```

```
sudo su - postgres
# STOP!!! - Make the appropriate substitution for PG_VERSION and PG_INSTANCE_ID
export PG_VERSION=16
export PG_INSTANCE_ID=app1
vi $PG_VERSION/$PG_INSTANCE_ID/postgresql.conf
# Make sure the directory prefix is accurate. Make changes if necessary 
data_directory = '/var/lib/pgsql/16/app1'               # use data in another directory
hba_file = '/var/lib/pgsql/16/app1/pg_hba.conf' # host-based authentication file
ident_file = '/var/lib/pgsql/16/app1/pg_ident.conf'     # ident configuration file

listen_addresses = '*'          # what IP address(es) to listen on;

# Make sure the port is the correct one
port = 6432                             # (change requires restart)

# Make sure the cluster_name matches the PG_VERSION and PG_INSTANCE_ID
cluster_name = '16/app1'                       # added to process titles if nonempty

:wq

exit
```

```
echo $PG_VERSION      # make sure it is set
echo $PG_INSTANCE_ID  # make sure it is set
sudo systemctl enable postgresql-$PG_VERSION-$PG_INSTANCE_ID.service
sudo systemctl start postgresql-$PG_VERSION-$PG_INSTANCE_ID.service
sudo systemctl status postgresql-$PG_VERSION-$PG_INSTANCE_ID.service
```

```
sudo su - postgres
psql -p 6432
ALTER USER postgres PASSWORD 'aBc.123';
\q

exit
```


## On the ClusterControl host

### Import cluster into ClusterControl using S9S CLI

Make sure the S9S CLI is installed and accessible
```
s9s user --list # make sure you can see the users
```

If not installed or if a default CLI user isn't created yet, go ahead and create one.
```
s9s user --create \
  --generate-key \
  --controller="https://localhost:9501" \
  --group=admins dba

#
s9s user --list # make sure you can see the users
```

**STOP!!!** - Make sure you changed the following env variables to reflect your setup.
```
export PG_VERSION=16
export PG_INSTANCE_ID=app1
export NODES="10.0.0.52:6432"
# export NODES="10.0.0.52?master;10.0.0.53?slave;"
export DB_ADMIN=postgres
export DB_ADMIN_PW="aBc.123"
export OS_USER=cloud-user
#export OS_USER_PW="XXXXX"  
export SSH_PRIV_KEY=/home/ubuntu/.ssh/id_rsa
export CC_CLUSTER_NAME="mypg-$PG_VERSION-$PG_INSTANCE_ID"
export DATA_DIR="/var/lib/pgsql/$PG_VERSION/$PG_INSTANCE_ID"
#
s9s cluster --register \
    --cluster-type=postgresql \
    --nodes=$NODES \
    --vendor=postgresql \
    --provider-version=$PG_VERSION \
    --db-admin=$DB_ADMIN \
    --db-admin-passwd=$DB_ADMIN_PW \
    --os-user=$OS_USER \
    --os-key-file=$SSH_PRIV_KEY \
    --cluster-name=$CC_CLUSTER_NAME \
    --datadir=$DATA_DIR \
    --no-install \
    --use-internal-repos \
    --with-ssl \
    --wait
#    --os-password=$OS_USER_PW \
```

### Download and move the prometheus exporter packages to ClusterControl
[Reference documentation](https://docs.severalnines.com/clustercontrol/latest/getting-started/tutorials/day-1-operations/deploy-database-cluster-offline-environment/#offline-database-deployment-using-clustercontrol)

Go to the section **"Setting up Prometheus exporters"**

```
# As of May 5, 2025
cd /var/cache/cmon/packages
wget https://github.com/prometheus/prometheus/releases/download/v2.29.2/prometheus-2.29.2.linux-amd64.tar.gz
wget https://github.com/prometheus/haproxy_exporter/releases/download/v0.9.0/haproxy_exporter-0.9.0.linux-amd64.tar.gz
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.0/mysqld_exporter-0.15.0.linux-amd64.tar.gz
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.13.2/postgres_exporter-0.13.2.linux-amd64.tar.gz
wget https://github.com/prometheus-community/pgbouncer_exporter/releases/download/v0.4.0/pgbouncer_exporter-0.4.0.linux-amd64.tar.gz
wget https://github.com/percona/proxysql_exporter/releases/download/v1.1.2/proxysql_exporter_linux_amd64.tar.gz
wget https://github.com/kedazo/process_exporter/releases/download/0.10.10/process_exporter-0.10.10.linux-amd64.tar.gz
wget https://github.com/kedazo/mongodb_exporter/releases/download/v0.11.0/mongodb_exporter-v0.11.0.linux-amd64.tar.gz
wget https://github.com/oliver006/redis_exporter/releases/download/v1.52.0/redis_exporter-v1.52.0.linux-amd64.tar.gz
wget https://github.com/severalnines/mssql_exporter/releases/download/0.6.0b/mssql_exporter-0.6.0-beta.0.linux-amd64.tar.gz
#mkdir -p /tmp/s9s/prometheus
#wget https://downloads.mariadb.com/files/MaxScale/2.5.7/packages/rhel/8/maxscale-2.5.7-1.rhel.8.x86_64.rpm
#wget http://www.haproxy.org/download/1.8/src/haproxy-1.8.9.tar.gz
#wget http://www.keepalived.org/software/keepalived-1.2.24.tar.gz
#wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
#wget http://libslack.org/daemon/download/daemon-0.6.4-1.x86_64.rpm
```

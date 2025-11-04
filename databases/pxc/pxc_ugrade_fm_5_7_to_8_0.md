# Upgrading Percona XtraDB cluster from 5.7 (CentOS 7) to 8.0 (Rocky 9.5)
Instructions on how to upgrade PXC setup.

#### References

#### Highlevel Steps
[Slides](https://docs.google.com/presentation/d/1cR5mIyaIe819HiGTdHV4IEXl-tto5DQshsjwcUGiEiQ/edit)

### NOTE: Replace anything in curly brackets with relevant values

## Step 0 : Deploy CC2 
### Step 0-1: Deploy CC2 (beyond the scope of this document)
[Installation Guide](https://docs.severalnines.com/clustercontrol/latest/getting-started/installation/online-installation/)

### Step 0-1: [IMPORTANT] Update env.sh with your values
Download [env.sh](./upgrade_supporting_material/env.sh) file to your laptop and make necessary changes to the env variable values.
Refer to description of the values in [file](./upgrade_supporting_material/supporting_items_for_upgrade.md).

## Step 1 : Setup current Production cluster to serve as (Replication) Master to Intermediate

### Step 1-1: Create replication user credentials on current Prod cluster (PXC 5.7 - CentOS 7)

SSH to `ssh centos@$CURR_PROD_MASTER_HOST`. And copy the contents of the MODIFIED env.sh on your laptop to `/tmp/env.sh` 

```shell
vi /tmp.env.sh
```

On **CURR_PROD_MASTER_HOST**:

```shell
source /tmp/env.sh
#sudo su - mysql
source /tmp/env.sh
mysql -u root -p$MYSQLROOTPW -e "select now();"
mysql -u root -p$MYSQLROOTPW -e "select host,user from mysql.user where user like '%"$MIGRATION_REPL_USER"%';"
mysql -u root -p$MYSQLROOTPW -e "CREATE USER '"$MIGRATION_REPL_USER"'@'"$INTERMEDIATE_HOST"' IDENTIFIED BY '"$MIGRATION_REPL_USER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "CREATE USER '"$MIGRATION_REPL_USER"'@'"$INTERMEDIATE_IP"' IDENTIFIED BY '"$MIGRATION_REPL_USER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "select host,user from mysql.user where user like '%"$MIGRATION_REPL_USER"%';"
#mysql -u root -p$MYSQLROOTPW -e "GRANT REPLICATION SLAVE ON *.* TO '"$MIGRATION_REPL_USER"'@'"$INTERMEDIATE_HOST"' IDENTIFIED BY '"$MIGRATION_REPL_USER_PW"';"
#mysql -u root -p$MYSQLROOTPW -e "GRANT REPLICATION SLAVE ON *.* TO '"$MIGRATION_REPL_USER"'@'"$INTERMEDIATE_IP"' IDENTIFIED BY '"$MIGRATION_REPL_USER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "GRANT REPLICATION SLAVE ON *.* TO '"$MIGRATION_REPL_USER"'@'"$INTERMEDIATE_HOST"' ;"
mysql -u root -p$MYSQLROOTPW -e "GRANT REPLICATION SLAVE ON *.* TO '"$MIGRATION_REPL_USER"'@'"$INTERMEDIATE_IP"' ;"
mysql -u root -p$MYSQLROOTPW -e "FLUSH PRIVILEGES;"
mysql -u root -p$MYSQLROOTPW -e "SHOW GRANTS FOR '"$MIGRATION_REPL_USER"'@'"$INTERMEDIATE_HOST"';"
mysql -u root -p$MYSQLROOTPW -e "SHOW GRANTS FOR '"$MIGRATION_REPL_USER"'@'"$INTERMEDIATE_IP"';"
#exit
```

### Step 1-2 : Create binary backup of current Production

On **CURR_PROD_MASTER_HOST**:

```shell
# source /tmp/env.sh
# NOTE: change the location of the backup and make sure mysql user has privs to write to the location.
sudo su - mysql
source /tmp/env.sh
rm $BACKUP_FILE_COMPRESSED
LC_ALL=C innobackupex --defaults-file=/etc/my.cnf --galera-info --slave-info --no-timestamp \
    --parallel=1 --stream=xbstream . | gzip -6 - > "$BACKUP_FILE_COMPRESSED"  2>&1
exit
#
#sudo chown $CURR_PROD_HOST_SHELL_USER:$CURR_PROD_HOST_SHELL_USER $BACKUP_FILE_COMPRESSED
```

## Step 2 : Create Intermediate (PXC 5.7 on Rocky 8) Replica (single node PXC)

On **INTERMEDIATE_HOST**:

### Step 2-1 : Create Intermediate (PXC 5.7 on Rocky 8) Replica manually
[Setup this up manually](./5_7/pxc57_Rocky8.md).

### Step 2-2 : Transfer binary backup from Prod host to this (intermediate) host

```shell
vi /tmp/env.sh # Copy the contents of env.sh to this host
source /tmp/env.sh
ls -l $BACKUP_FILE_COMPRESSED
```

### Step 2-3 : Restore Binary backup of Prod on Intermediate

#### Stop the node (i.e., the single node galera cluster)

This will stop the PXC server on the single node PXC. Verify that it is indeed stopped by:

```shell
sudo systemctl stop mysql
sudo systemctl stop mysql@bootstrap.service
sudo systemctl status mysql
sudo systemctl status mysql@bootstrap.service
```

#### Restore backup
Now you are ready start restore. Unzip and extract the backup first

```shell
source /tmp/env.sh
#cd /tmp
gunzip $BACKUP_FILE_COMPRESSED 
mkdir -p $BACKUP_RESTORE_STAGING_LOC
cd $BACKUP_RESTORE_STAGING_LOC
xbstream -x < $BACKUP_FILE
ls -l
total 102464
-rw-r-----. 1 rocky rocky       493 Oct 31 13:53 backup-my.cnf
-rw-r-----. 1 rocky rocky       194 Oct 31 13:53 binlog.000010
-rw-r-----. 1 rocky rocky       298 Oct 31 13:53 ib_buffer_pool
-rw-r-----. 1 rocky rocky 104857600 Oct 31 13:53 ibdata1
drwxr-x---. 2 rocky rocky      4096 Oct 31 13:53 mysql
drwxr-x---. 2 rocky rocky      8192 Oct 31 13:53 performance_schema
drwxr-x---. 2 rocky rocky      8192 Oct 31 13:53 sys
-rw-r-----. 1 rocky rocky        60 Oct 31 13:53 xtrabackup_binlog_info
-rw-r-----. 1 rocky rocky       135 Oct 31 13:53 xtrabackup_checkpoints
-rw-r-----. 1 rocky rocky       609 Oct 31 13:53 xtrabackup_info
-rw-r-----. 1 rocky rocky      8704 Oct 31 13:53 xtrabackup_logfile
-rw-r-----. 1 rocky rocky         0 Oct 31 13:53 xtrabackup_slave_info
```

```shell
mv $BACKUP_FILE $BACKUP_FILE.pxc57
cat $BACKUP_RESTORE_STAGING_LOC/xtrabackup_info
cat $BACKUP_RESTORE_STAGING_LOC/xtrabackup_binlog_info
cat $BACKUP_RESTORE_STAGING_LOC/xtrabackup_slave_info
```

```shell
cat $BACKUP_RESTORE_STAGING_LOC/xtrabackup_binlog_info
binlog.000010	194	640af5af-4a3e-ee0f-5993-a9a2602b38ad:1-16
```

##### Prepare the backup

```shell
source /tmp/env.sh
sudo chown -R mysql $BACKUP_RESTORE_STAGING_LOC
sudo su - mysql
source /tmp/env.sh
innobackupex --apply-log $BACKUP_RESTORE_STAGING_LOC
exit
```

##### Copy back the backup to datadir of PXC

```shell
source /tmp/env.sh
sudo mv /var/lib/mysql /var/lib/mysql.57
sudo mkdir -p /var/lib/mysql
sudo chown -R mysql:mysql /var/lib/mysql
sudo chown -R mysql:mysql $BACKUP_RESTORE_STAGING_LOC
sudo su - mysql
source /tmp/env.sh
innobackupex --copy-back $BACKUP_RESTORE_STAGING_LOC
exit
```

##### Start the node

```shell
sudo systemctl start mysql@bootstrap.service
sudo systemctl status mysql@bootstrap.service
sudo vi /var/log/mysql/mysqld.log
# check for any ERROR s.
#sudo systemctl status mysql
```

### Step 2-4 : Setup replication from Prod to this (Intermediate) host

```shell
source /tmp/env.sh
sudo cat $BACKUP_RESTORE_STAGING_LOC/xtrabackup_binlog_info # Get the binlog file and position...E.g. bilong file and position shown below
binlog.000011	194	640af5af-4a3e-ee0f-5993-a9a2602b38ad:1-16
# UPDATE binlog file and pos below
export MASTER_LOG_FILE=binlog.000011
export MASTER_LOG_POS=194
mysql -u root -p$MYSQLROOTPW -e "select now();"
mysql -u root -p$MYSQLROOTPW -e "SHOW SLAVE STATUS \G"
mysql -u root -p$MYSQLROOTPW -e "CHANGE MASTER TO MASTER_HOST='"$CURR_PROD_MASTER_HOST"', MASTER_USER='"$MIGRATION_REPL_USER"', MASTER_PASSWORD='"$MIGRATION_REPL_USER_PW"', MASTER_LOG_FILE='"$MASTER_LOG_FILE"', MASTER_LOG_POS="$MASTER_LOG_POS" ;"
#mysql -u root -p$MYSQLROOTPW -e "CHANGE MASTER TO MASTER_HOST='"$MASTER_HOST"', MASTER_USER='"$MIGRATION_REPL_USER"', MASTER_PASSWORD='"$MIGRATION_REPL_USER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "SHOW SLAVE STATUS \G"
mysql -u root -p$MYSQLROOTPW -e "START SLAVE;"
mysql -u root -p$MYSQLROOTPW -e "SHOW SLAVE STATUS \G"
```

**NOTE: SLAVE should be running without any connection or SQL errors**

### Step 2-5 : Create a backup before upgrading to PXC 8.0 

```shell
sudo su - mysql
source /tmp/env.sh
export TMP_57_BACKUP_BEFORE_UPGRADE=$BACKUP_FILE.57_rocky8_b4_upgrade.gz
LC_ALL=C innobackupex --defaults-file=/etc/my.cnf --galera-info --slave-info --no-timestamp \
    --parallel=1 --stream=xbstream . | gzip -6 - > "$TMP_57_BACKUP_BEFORE_UPGRADE"  2>&1
ls -l $TMP_57_BACKUP_BEFORE_UPGRADE
exit
```

## Step 3 - Upgrade PXC 5.7 to 8.0 (In-place upgrade)

On **INTERMEDIATE_HOST**:

### Step 3-1 : Remove PXC 5.7 packages and disable PXC 5.7 repositories

```shell
sudo tar cvfz ~/configs.tgz /etc/my.cnf /etc/my.cnf.d/secrets-backup.cnf /etc/mysql/certs
#sudo cp /etc/my.cnf ~
#sudo cp /etc/my.cnf.d/secrets-backup.cnf ~
```

```shell
sudo systemctl status mysql@bootstrap.service
sudo systemctl stop mysql@bootstrap.service
sudo systemctl status mysql@bootstrap.service
sudo yum autoremove -y Percona-XtraDB-Cluster-57 
sudo percona-release disable pxc-57 release
sudo yum clean all
#sudo yum list Percona*
mysql --version                           # Should not exist
#sudo systemctl cat mysql
```

### Step 3-2 : Install PXC 8.0

```shell
#### Install PXC 5.7 from repos
sudo percona-release enable pxc-80 release
sudo percona-release setup -y pxc-80
sudo yum module disable mysql -y
sudo yum clean all
#sudo yum list Percona*
sudo yum install -y percona-xtradb-cluster percona-xtrabackup-80
mysql --version
#sudo systemctl cat mysql
```

### Step 3-3 : Update config files (my.cnf, secrets-backup.cnf)

```shell
source /tmp/env.sh
sudo yum install iputils -y # ping
sudo yum install bind-utils -y # host
host $CMON_HOST # if this returns host not found, it indicates you will beed to set skip_name_resolve=ON in the [mysqld] section and restart
```

Copy [my.cnf](./8_0/my.cnf)
**VERY IMPORTANT**: `skip_name_resolve` - Make sure the target DB host, in this case the INTERMEDIATE_HOST, can resolve the CCv2 host by name.
If not, you must set `skip_name_resolve=ON` in the `[MYSQLD]` section. Use the `host` command as shown below to determine if DNS is setup in your network.

```shell
sudo mv /etc/my.cnf ~
sudo vi /etc/my.cnf
```

Copy [secrets-backup.cnf](./8_0/secrets-backup.cnf)

```shell
sudo mv /etc/my.cnf.d/secrets-backup.cnf ~
sudo vi /etc/my.cnf.d/secrets-backup.cnf
sudo rm /var/log/mysqld.log
sudo chown -R mysql /etc/my.cnf /etc/my.cnf.d
```

```shell
source /tmp/env.sh
sudo sudo sed -i 's/^wsrep_node_address=.*/wsrep_node_address='"$NODE_IP"'/g' /etc/my.cnf
sudo sudo sed -i 's/^wsrep_cluster_name=.*/wsrep_cluster_name='"$CLUSTER_NAME"'/g' /etc/my.cnf
sudo sudo sed -i 's/^wsrep_node_name=.*/wsrep_node_name='"$NODE_NAME"'/g' /etc/my.cnf
sudo sudo sed -i 's/^server_id=.*/server_id='"$SERVER_ID"'/g' /etc/my.cnf
#
sudo sudo sed -i '/encrypt=/s/^#//g' /etc/my.cnf
sudo sudo sed -i '/ssl-key=/s/^#//g' /etc/my.cnf
sudo sudo sed -i '/ssl-ca=/s/^#//g' /etc/my.cnf
sudo sudo sed -i '/ssl-cert=/s/^#//g' /etc/my.cnf
#
sudo sudo sed -i '/ssl_cert=/s/^#//g' /etc/my.cnf
sudo sudo sed -i '/ssl_key=/s/^#//g' /etc/my.cnf
sudo sudo sed -i '/ssl_ca=/s/^#//g' /etc/my.cnf
```

### Step 3-4 : Start the MySQL service

#### Start mysql and make some changes and additions...

```shell
sudo systemctl start mysql@bootstrap.service
sudo systemctl status mysql@bootstrap.service
#sudo systemctl stop mysql@bootstrap.service
#sudo systemctl start mysql
#sudo systemctl status mysql
#
source /tmp/env.sh
mysql -u root -p$MYSQLROOTPW -e "show status like 'wsrep_cluster_size';"
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 1     |
+--------------------+-------+

mysql -u root -p$MYSQLROOTPW -e "select version();"
+-------------+
| version()   |
+-------------+
| 8.0.43-34.1 |
+-------------+
#
mysql -u root -p$MYSQLROOTPW -e "GRANT SELECT ON performance_schema.* TO '"$BACKUPUSER"'@'localhost';"
mysql -u root -p$MYSQLROOTPW -e "FLUSH PRIVILEGES;"
mysql -u root -p$MYSQLROOTPW -e "SHOW GRANTS FOR '"$BACKUPUSER"'@'localhost';"
mysql -u root -p$MYSQLROOTPW -e "SHOW SLAVE STATUS \G"
```

**NOTE: SLAVE should be running without any connection or SQL errors**

### Step 3-5 : Create replication user for new target (the new Prod cluster)

```shell
source /tmp/env.sh
mysql -u root -p$MYSQLROOTPW -e "select now();"
mysql -u root -p$MYSQLROOTPW -e "select host,user from mysql.user where user like '%"$MIGRATION_REPL_USER"%';"
mysql -u root -p$MYSQLROOTPW -e "DROP USER '"$MIGRATION_REPL_USER"'@'"$NEW_PROD_MASTER_HOST"' ;"  # IGNORE any errors
mysql -u root -p$MYSQLROOTPW -e "DROP USER '"$MIGRATION_REPL_USER"'@'"$NEW_PROD_MASTER_IP"' ;"    # IGNORE any errors
mysql -u root -p$MYSQLROOTPW -e "DROP USER '"$MIGRATION_REPL_USER"'@'"$INTERMEDIATE_HOST"' ;"  # IGNORE any errors
mysql -u root -p$MYSQLROOTPW -e "DROP USER '"$MIGRATION_REPL_USER"'@'"$INTERMEDIATE_IP"' ;"    # IGNORE any errors
# NOTE: mysql_native_password is required for non-SSL based replication setup.
mysql -u root -p$MYSQLROOTPW -e "CREATE USER '"$MIGRATION_REPL_USER"'@'"$NEW_PROD_MASTER_HOST"' IDENTIFIED WITH mysql_native_password BY '"$MIGRATION_REPL_USER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "CREATE USER '"$MIGRATION_REPL_USER"'@'"$NEW_PROD_MASTER_IP"' IDENTIFIED WITH mysql_native_password BY '"$MIGRATION_REPL_USER_PW"';"
#mysql -u root -p$MYSQLROOTPW -e "GRANT REPLICATION SLAVE ON *.* TO '"$MIGRATION_REPL_USER"'@'"$NEW_PROD_MASTER_HOST"' IDENTIFIED BY '"$MIGRATION_REPL_USER_PW"';"
#mysql -u root -p$MYSQLROOTPW -e "GRANT REPLICATION SLAVE ON *.* TO '"$MIGRATION_REPL_USER"'@'"$NEW_PROD_MASTER_IP"' IDENTIFIED BY '"$MIGRATION_REPL_USER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "GRANT REPLICATION SLAVE ON *.* TO '"$MIGRATION_REPL_USER"'@'"$NEW_PROD_MASTER_HOST"' ;"
mysql -u root -p$MYSQLROOTPW -e "GRANT REPLICATION SLAVE ON *.* TO '"$MIGRATION_REPL_USER"'@'"$NEW_PROD_MASTER_IP"' ;"
mysql -u root -p$MYSQLROOTPW -e "FLUSH PRIVILEGES;"
mysql -u root -p$MYSQLROOTPW -e "select host,user from mysql.user where user like '%"$MIGRATION_REPL_USER"%';"
```

## Step 4 - Import PXC 8 on (Rocky 8) into CCv2

### Step 4-1 : Import PXC 8 into CCv2 using CCv2
Use the MySQL `root` user's password from [env](./upgrade_supporting_material/env.sh) file. 

### Step 4-2 : Take backup (xtrabackupfull) from CCv2

#### Take backup (xtrabackupfull) from CCv2
Take a xtrabackupfull backup from the CCv2 UI

#### Step 4-3 : Take manual backup from host

On **INTERMEDIATE_HOST**:

```shell
source /tmp/env.sh
sudo rm $BACKUP_FILE_COMPRESSED   # IGNORE any errors
sudo rm $BACKUP_FILE              # IGNORE any errors
sudo su - mysql
source /tmp/env.sh
LC_ALL=C xtrabackup --defaults-file=/etc/my.cnf --backup --galera-info --parallel=1 --slave-info \
  --stream=xbstream | gzip -6 - > "$BACKUP_FILE_COMPRESSED"  2>&1
#
ls -al $BACKUP_FILE_COMPRESSED
#
exit
```

## Step 5 - Deploy new Production PXC 8.0 cluster (single node) on Rocky 9 using CCv2

### Step 5-1: Deploy the new PXC 8.0 Prod (single node) cluster on Rocky 9 through CCv2
Perform this from the CCv2 UI. Deploy a single node PX 8 cluster on **NEW_PROD_MASTER_HOST** host using CCv2.

**NOTE** the **Cluster-ID** assigned to this cluster by CCv2.

#### Stop the node
Use CCv2 UI to stop the single node PXC 8.0 Prod cluster on Rocky 9 (`Stop node` operation from the UI).

## Step 6: Restore backup from PXC 8 (Rocky 8) (intermediate host) on this node PXC 8 on Rocky 9

On **NEW_PROD_MASTER_HOST**:

### Step 6-1 : Transfer the backup made on PXC 8 (Rocky 8) (intermediate host) to this Prod PXC 8 (Rocky 9) host
1. Transfer backup
2. Create the `/tmp/env.sh` [file](./upgrade_supporting_material/env.sh)

```shell
vi /tmp/env.sh
```

### Step 6-2 : Start backup restoration procedure

```shell
source /tmp/env.sh
#cd /tmp
gunzip $BACKUP_FILE_COMPRESSED 
mkdir -p $BACKUP_RESTORE_STAGING_LOC
cd $BACKUP_RESTORE_STAGING_LOC
xbstream -x < $BACKUP_FILE
#sudo chown -R mysql:mysql $BACKUP_RESTORE_STAGING_LOC
ls -l
total 167992
-rw-r-----. 1 rocky rocky       453 Oct 31 16:56 backup-my.cnf
-rw-r-----. 1 rocky rocky       197 Oct 31 16:56 binlog.000020
-rw-r-----. 1 rocky rocky        16 Oct 31 16:56 binlog.index
-rw-r-----. 1 rocky rocky       300 Oct 31 16:56 ib_buffer_pool
-rw-r-----. 1 rocky rocky 104857600 Oct 31 16:56 ibdata1
drwxr-x---. 2 rocky rocky      4096 Oct 31 16:56 mysql
-rw-r-----. 1 rocky rocky  33554432 Oct 31 16:56 mysql.ibd
drwxr-x---. 2 rocky rocky      8192 Oct 31 16:56 performance_schema
drwxr-x---. 2 rocky rocky        28 Oct 31 16:56 sys
-rw-r-----. 1 rocky rocky  16777216 Oct 31 16:56 undo_001
-rw-r-----. 1 rocky rocky  16777216 Oct 31 16:56 undo_002
drwxr-x---. 2 rocky rocky        20 Oct 31 16:56 xtrabackup_backupfiles
-rw-r-----. 1 rocky rocky       102 Oct 31 16:56 xtrabackup_binlog_info
-rw-r-----. 1 rocky rocky       134 Oct 31 16:56 xtrabackup_checkpoints
-rw-r-----. 1 rocky rocky       631 Oct 31 16:56 xtrabackup_info
-rw-r-----. 1 rocky rocky      2560 Oct 31 16:56 xtrabackup_logfile
-rw-r-----. 1 rocky rocky        70 Oct 31 16:56 xtrabackup_slave_info
-rw-r-----. 1 rocky rocky        39 Oct 31 16:56 xtrabackup_tablespaces
```

```shell
#mv $BACKUP_FILE $BACKUP_FILE.pxc80
cat $BACKUP_RESTORE_STAGING_LOC/xtrabackup_info
cat $BACKUP_RESTORE_STAGING_LOC/xtrabackup_binlog_info
cat $BACKUP_RESTORE_STAGING_LOC/xtrabackup_slave_info
```

```shell
cat $BACKUP_RESTORE_STAGING_LOC/xtrabackup_binlog_info
binlog.000020	197	3d4dff97-b662-11f0-9145-faecd086aa44:1-11,640af5af-4a3e-ee0f-5993-a9a2602b38ad:1-16
```

##### Prepare the backup
```shell
source /tmp/env.sh
xtrabackup --prepare --target-dir=$BACKUP_RESTORE_STAGING_LOC
#sudo su - mysql
#exit
```

##### Copy back the backup to datadir of PXC
```shell
source /tmp/env.sh
sudo mv /var/lib/mysql /var/lib/mysql.80
sudo mkdir /var/lib/mysql
sudo chown -R mysql:mysql /var/lib/mysql $BACKUP_RESTORE_STAGING_LOC
sudo su - mysql
source /tmp/env.sh
xtrabackup --copy-back --target-dir=$BACKUP_RESTORE_STAGING_LOC
exit
```

##### Make necessary changes to my.cnf to match that of INTERMEDIATE's

```shell
source /tmp/env.sh
sudo yum install iputils -y # ping
sudo yum install bind-utils -y # host
host $CMON_HOST # if this returns host not found, it indicates you will beed to set skip_name_resolve=ON in the [mysqld] section and restart
```

**VERY IMPORTANT**: `skip_name_resolve` - Make sure the target DB host, in this case the INTERMEDIATE_HOST, can resolve the CCv2 host by name.
If not, you must set `skip_name_resolve=ON` in the `[MYSQLD]` section in `/etc/my.cnf`. Use the `host` command as shown below to determine if DNS is setup in your network.

```shell
sudo cp /etc/my.cnf ~
sudo vi /etc/my.cnf
```

##### Change the credentials in secrets-backup.cnf to match INTERMEDIATE's

Copy contents of [secrets-backup.cnf](./8_0/secrets-backup.cnf)

```shell
sudo cp /etc/my.cnf.d/secrets-backup.cnf ~
sudo su - mysql
sudo vi /etc/my.cnf.d/secrets-backup.cnf        # Copy contents here...
exit
#sudo chown -R mysql /etc/my.cnf /etc/my.cnf.d
```

## Step 7: Start the node from the CCv2 UI; Grant some privileges to CCv2 user; Setup replication from Intermediate to this...
Start the node through CCv2 UI.

**IMPORTANT**: 
* select the `bootstrap` option
* Do **NOT** select the `initial start` option

**NOTE**: the new PXC 8 (Rocky 9) cluster will show up in Orange/Unmanaged/Status-unknown in the CCv2 UI, but will be fixed by the following steps.

### Step 7-1 : Grant privileges for CCv2 to manage the PXC 8 (Rocky 9) cluster
Recall the earlier noted the Cluster_ID (CID) assigned by CCv2 to this cluster. 

Find the `cmon` user's database password used by CCv2 by following the steps below. SSH to the CCv2 host and:
Replcase `CID` below with the earlier noted numeric value.
```shell
sudo cat /etc/cmon.d/cmon_CID.cnf | grep "mysql_password="
```
**Note** the value of `mysql_password` from above. You will need to use it below.

On **NEW_PROD_MASTER_HOST**:

```shell
sudo su - mysql
source /tmp/env.sh
export CMON_USER_PW='cTs84XheV750Nhp/POw0%+!ct9g3FJLX'      # The value of `mysql_password` from cmon_CID.cnf file
#
mysql -u root -p$MYSQLROOTPW -e "select now();"
mysql -u root -p$MYSQLROOTPW -e "select host,user from mysql.user where user like '%"$CMON_USER"%';"
mysql -u root -p$MYSQLROOTPW -e "DROP USER '"$CMON_USER"'@'"$CMON_HOST"' ;"                                     # IGNORE any errors
mysql -u root -p$MYSQLROOTPW -e "DROP USER '"$CMON_USER"'@'"$CMON_HOST_IP"';"
mysql -u root -p$MYSQLROOTPW -e "select host,user from mysql.user where user like '%"$CMON_USER"%';"
mysql -u root -p$MYSQLROOTPW -e "CREATE USER '"$CMON_USER"'@'"$CMON_HOST"' IDENTIFIED BY '"$CMON_USER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "CREATE USER '"$CMON_USER"'@'"$CMON_HOST_IP"' IDENTIFIED BY '"$CMON_USER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "GRANT ALL PRIVILEGES ON *.* TO '"$CMON_USER"'@'"$CMON_HOST"' ;"                 # IGNORE any errors
mysql -u root -p$MYSQLROOTPW -e "GRANT ALL PRIVILEGES ON *.* TO '"$CMON_USER"'@'"$CMON_HOST_IP"';"
mysql -u root -p$MYSQLROOTPW -e "FLUSH PRIVILEGES;"
mysql -u root -p$MYSQLROOTPW -e "select host,user from mysql.user where user like '%"$CMON_USER"%';"
mysql -u root -p$MYSQLROOTPW -e "SHOW GRANTS FOR '"$CMON_USER"'@'"$CMON_HOST"';"
mysql -u root -p$MYSQLROOTPW -e "SHOW GRANTS FOR '"$CMON_USER"'@'"$CMON_HOST_IP"';"
#
exit
```

### Step 7-2:  Setup replication from PXC 8 (Rocky 8) to Production PXC 8 (Rocky 9)

```shell
source /tmp/env.sh
sudo cat $BACKUP_RESTORE_STAGING_LOC/xtrabackup_binlog_info # Get the binlog file and position to start replication from...EXAMPLE values below
binlog.000017	237	640af5af-4a3e-ee0f-5993-a9a2602b38ad:1-44,d163d6a0-b8f5-11f0-a052-0fed90d53bdd:1-22
```

```shell
sudo su - mysql
source /tmp/env.sh
export MASTER_LOG_FILE=binlog.000017
export MASTER_LOG_POS=197
#sudo systemctl status mysql
mysql -u root -p$MYSQLROOTPW -e "select now();"
mysql -u root -p$MYSQLROOTPW -e "SHOW SLAVE STATUS \G"
mysql -u root -p$MYSQLROOTPW -e "STOP SLAVE;"
#mysql -u root -p$MYSQLROOTPW -e "RESET MASTER;"
mysql -u root -p$MYSQLROOTPW -e "CHANGE MASTER TO MASTER_HOST='"$INTERMEDIATE_IP"', MASTER_USER='"$MIGRATION_REPL_USER"', MASTER_PASSWORD='"$MIGRATION_REPL_USER_PW"', MASTER_LOG_FILE='"$MASTER_LOG_FILE"', MASTER_LOG_POS="$MASTER_LOG_POS" ;"
#mysql -u root -p$MYSQLROOTPW -e "CHANGE MASTER TO MASTER_HOST='"$MASTER_HOST"', MASTER_USER='"$MIGRATION_REPL_USER"', MASTER_PASSWORD='"$MIGRATION_REPL_USER_PW"';"
mysql -u root -p$MYSQLROOTPW -e "START SLAVE;"
mysql -u root -p$MYSQLROOTPW -e "SHOW SLAVE STATUS \G"
exit
```

**NOTE: SLAVE should be running without any connection or SQL errors**

### Step 7-3:  Take a backup of PXC 8 (Rocky 8) to Production PXC 8 (Rocky 9) from CCv2

#### Kick of a xtrabackupfull backup from CCv2



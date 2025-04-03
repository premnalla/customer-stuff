# Upgrading Postgres11-Timescale1_7_5 to Postgres13-Timescale2_15_3 (Ubuntu 20.04 LTS)
Instructions on how to upgrade.

- (PG11-Timescale 1.7.5)
- (PG11-Timescale 2.3.1)
- (PG13-Timescale 2.3.1)
- (PG13-Timescale 2.15.3)

Ubuntu 20.04 LTS (Jan 28, 2025) release

# Phase (I) - Upgrade PG(11)-Timescale(1_7_x) to PG(13)-Timescale(2.15.3)

## Step 0 : Prepare configuration files from a PG(13)-Timescale(2_15_3) cluster
### Step 0 - 1a : Setup a single-node PG(13)-Timescale(2_15_3) cluster through ClusterControl (CC)
Host/Node: Temporary/TMP
```
sudo su - postgres
psql
psql (13.20 (Ubuntu 13.20-1.pgdg20.04+1))
Type "help" for help.

postgres=# \dx
List of installed extensions
Name        | Version |   Schema   |                                      Description                                      
--------------------+---------+------------+---------------------------------------------------------------------------------------
pg_stat_statements | 1.8     | public     | track planning and execution statistics of all SQL statements executed
plpgsql            | 1.0     | pg_catalog | PL/pgSQL procedural language
timescaledb        | 2.15.3  | public     | Enables scalable inserts and complex queries for time-series data (Community Edition)
(3 rows)

postgres=# select * from pg_available_extensions where name like '%timescale%';
        name         | default_version | installed_version |                                        comment                                        
---------------------+-----------------+-------------------+---------------------------------------------------------------------------------------
 timescaledb_toolkit | 1.19.0          |                   | Library of analytical hyperfunctions, time-series pipelining, and other SQL utilities
 timescaledb         | 2.15.3          | 2.15.3            | Enables scalable inserts and complex queries for time-series data (Community Edition)
(2 rows)

postgres=# select version();
                                                               version                                                               
-------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 13.20 (Ubuntu 13.20-1.pgdg20.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0, 64-bit
(1 row)
```

### Step 0 - 1b : Copy PG(13)-Timescale(2_15_3) configuration files to a common host (or, nfs location)
### Step 0 - 2a : Remove the cluster from ClusterControl
### Step 0 - 2b : Decommission the host (return it to the available pool)
### Step 0 - 3 : Create replication user on replica (R1)
Host/Node: R1
```
sudo su - postgres
psql
postgres=# CREATE USER repuser PASSWORD '{REPLICATION_USER_PW}' REPLICATION;
postgres=# \du
postgres=# \q

# edit postgresql configuration file and change listen_address to '* from 'localhhost'
vi /etc/postgresql/11/main/postgresql.conf
listen_addresses = '*'

# edit pg_hba.conf add the ability for the repuser to connect from host other than localhost
vi /etc/postgresql/11/main/pg_hba.conf
# NOTE: make sure to change 10.0.0.0/24 with appropriate host/CIDR 
host    replication     all             10.0.0.0/24            md5
exit

# restart postgres
sudo systemctl restart postgresql@11-main
sudo systemctl status postgresql@11-main
```

## Step 1 - Create a single-node PG(11)-Timescale(1.7.5) cluster and import it into CC
### Step 1 - 1 : Install PG11-Timescale(1.7.5)
#### Step 1 - 1a : Install PG11 on (R2)
Host/Node: R2
```
sudo apt update
cat /etc/lsb-release
sudo apt upgrade -y
sudo apt install -y net-tools vim wget unzip

curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list

sudo apt update
sudo apt list postgresql-11
sudo apt -y install postgresql-11

sudo ss -tunelp | grep 5432
netstat -lntpd |grep 5432
sudo systemctl status postgresql
pg_lsclusters
sudo systemctl status postgresql*
sudo systemctl status postgresql@11-main.service
sudo systemctl status postgresql@11-main

ps -ef |grep postgresql
— /usr/lib/postgresql/11/bin/postgres -D /var/lib/postgresql/11/main -c config_file=/etc/postgresql/11/main/postgresql.conf
sudo ls -al /etc/postgresql/11/main/postgresql.conf
sudo ls -al /usr/lib/postgresql/11/bin/postgres
sudo ls -al /usr/lib/postgresql/11/bin/
sudo ls -al /var/lib/postgresql/11/main

sudo su - postgres
psql
postgres=# select version();
-  PostgreSQL 11.22 (Ubuntu 11.22-9.pgdg20.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0, 64-bit
postgres=# \q

# edit postgresql configuration file and change listen_address to '* from 'localhhost'
vi /etc/postgresql/11/main/postgresql.conf
listen_addresses = '*'
exit

# restart postgres
sudo systemctl restart postgresql@11-main
sudo systemctl status postgresql@11-main
```

#### Step 1 - 1b : Install Timescale(1.7.5) - (R2)
Host/Node: R2
```
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 55EE6BF7698E3D58D72C0DD9ECB3980CC59E610B
sudo sh -c 'echo "deb https://ppa.launchpadcontent.net/timescale/timescaledb-ppa/ubuntu/ focal main" >> /etc/apt/sources.list.d/timescale-ubuntu-timescaledb-ppa-focal.list'

sudo apt update
sudo apt install timescaledb-postgresql-11

sudo timescaledb-tune --quiet --yes
sudo systemctl restart postgresql@11-main
sudo systemctl status postgresql@11-main

sudo su - postgres
psql
postgres=# select version();
-  PostgreSQL 11.22 (Ubuntu 11.22-9.pgdg20.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0, 64-bit
postgres=# select * from pg_available_extensions where name like '%timescale%';
- timescaledb | 1.7.5           |                   | Enables scalable inserts and complex queries for time-series data
postgres=# create database test_db;
postgres=# \c test_db
CREATE EXTENSION timescaledb WITH VERSION '1.7.5' CASCADE;
test_db=# \dx
- plpgsql     | 1.0     | pg_catalog | PL/pgSQL procedural language
- timescaledb | 1.7.5   | public     | Enables scalable inserts and complex queries for time-series data
test_db=# \q
exit
# backup configuration files as OS user (e.g. ubuntu)
mkdir -p ./postgresql/11/main/
sudo cp -rp /etc/postgresql/11/main/*.conf ./postgresql/11/main/
sudo chown -R ubuntu:ubuntu ./postgresql/11/main/
```

### Step 1 - 2 : Take backup on replica (R1)
Host/Node: R1
```
pg_basebackup -h {hostname-or-ip-of-R1} -U repuser --checkpoint=fast -D /tmp/staging_db/ -R -P -F t -z -v --port=5432 
# Enter the password for repuser
pg_basebackup: initiating base backup, waiting for checkpoint to complete
...
pg_basebackup: base backup completed

cd /tmp
tar cvfz staging_db.tgz ./staging_db
/bin/rm -rf ./staging_db
ls -alh
```

### Step 1 - 3 : Restore backup on replica (R2)
Host/Node: R2
```
# Stop postgres
sudo systemctl status postgresql@11-main
sudo systemctl stop postgresql@11-main
sudo systemctl status postgresql@11-main

# Apply backup to data directory
sudo su - postgres
cd 11
/bin/rm -rf main
tar xvf /tmp/staging_db.tgz 
mv staging_db main
cd main
tar xvf base.tar.gz 
rm base.tar.gz 
cd pg_wal
tar xvf ../pg_wal.tar.gz
cd ..
rm ./pg_wal.tar.gz

# Inspect the recovery.conf to make sure the connect string (HOST and PW) look ok
cat recovery.conf

exit

# Start postgres
sudo systemctl start postgresql@11-main
sudo tail -f /var/log/postgresql/postgresql-11-main.log
sudo systemctl status postgresql@11-main
```

### Step 1 - 4 : Import (R2) into CC (using the CC UI)

## Step 2 : Add HAProxy using CC UI

## Step 3 : Upgrade Timescale to 2.3.1 (PG11) - (R2)
Host/Node: R2
```
sudo apt update
sudo apt list timescaledb-2-postgresql-11
sudo apt install timescaledb-2-postgresql-11

#
sudo timescaledb-tune --quiet --yes --pg-version 11
Using postgresql.conf at this path:
/etc/postgresql/11/main/postgresql.conf

Writing backup to:
/tmp/timescaledb_tune.backup202502241652

Recommendations based on 1.95 GB of available memory and 1 CPUs for PostgreSQL 11
success: all settings tuned, no changes needed
Saving changes to: /etc/postgresql/11/main/postgresql.conf
```

```
#
sudo systemctl restart postgresql@11-main
sudo systemctl status postgresql@11-main
```

**NOTE** Replace `test_db` used below with your database
```
sudo su - postgres
psql
postgres=# select * from pg_available_extensions where name like '%timescale%';
- timescaledb | 2.3.1           |                   | Enables scalable inserts and complex queries for time-series data

postgres=# \c test_db
test_db=# \dx
 plpgsql     | 1.0     | pg_catalog | PL/pgSQL procedural language
 timescaledb | 1.7.5   | public     | Enables scalable inserts and complex queries for time-series data

test_db=# select * from pg_available_extensions where name like '%timescale%';
    name     | default_version | installed_version |                              comment                              
-------------+-----------------+-------------------+-------------------------------------------------------------------
 timescaledb | 2.3.1           | 1.7.5             | Enables scalable inserts and complex queries for time-series data

test_db=# \q
psql
postgres=# \c test_db
test_db=# ALTER EXTENSION timescaledb UPDATE;
test_db=# \dx
                                      List of installed extensions
    Name     | Version |   Schema   |                            Description                            
-------------+---------+------------+-------------------------------------------------------------------
 plpgsql     | 1.0     | pg_catalog | PL/pgSQL procedural language
 timescaledb | 2.3.1   | public     | Enables scalable inserts and complex queries for time-series data
(2 rows)

test_db=# select * from pg_available_extensions where name like '%timescale%';
    name     | default_version | installed_version |                              comment                              
-------------+-----------------+-------------------+-------------------------------------------------------------------
 timescaledb | 2.3.1           | 2.3.1             | Enables scalable inserts and complex queries for time-series data
test_db=# SELECT   time_bucket('1 hour', time) AS bucket,   first(price,time), last(price, time)   FROM stocks_real_time srt   WHERE time > now() - INTERVAL '30 days'   GROUP BY bucket, symbol  LIMIT 10;
test_db=# \q

#
exit
```

```
sudo systemctl stop postgresql@11-main
sudo systemctl status postgresql@11-main
```

## Step 4 - Upgrade to PG13 (Timescale 2.3.1) - (R2)

### Step 4 - 1 : Install Timescale 2.3.1 for PG13
#### Step 4 - 1a : Replace timescale repository
Current repository
```
sudo cat /etc/apt/sources.list.d/timescaledb.list 
deb https://ppa.launchpadcontent.net/timescale/timescaledb-ppa/ubuntu/ focal main
```

Replace current repository with the following
```
sudo mv /etc/apt/sources.list.d/timescaledb.list /tmp
# This is for Timescale (1.7.5 and 2.3.1) for PG11

# Setup repo and key for Timescale 2.3.1 for PG13
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/timescale.keyring
sudo sh -c "echo 'deb [signed-by=/usr/share/keyrings/timescale.keyring] https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main' > /etc/apt/sources.list.d/timescaledb.list"
#
```

#### Step 4 - 1b : Install Timescale 2.3.1 for PG13
```
sudo apt update
sudo apt list timescaledb-2-postgresql-13
sudo apt install timescaledb-2-postgresql-13
dpkg -l | grep timescale
ii  timescaledb-2-2.3.1-postgresql-13  2.3.1~ubuntu20.04                 amd64        An open-source time-series database based on PostgreSQL, as an extension.
ii  timescaledb-2-loader-postgresql-11 2.3.1~ubuntu20.04                 amd64        The loader for TimescaleDB to load individual versions.
ii  timescaledb-2-loader-postgresql-13 2.15.3~ubuntu20.04                amd64        The loader for TimescaleDB to load individual versions.
ii  timescaledb-2-postgresql-11        2.3.1~ubuntu20.04                 amd64        An open-source time-series database based on PostgreSQL, as an extension.
ii  timescaledb-tools                  0.11.0~ubuntu20.04                amd64        A suite of tools that can be used with TimescaleDB.

dpkg -l | grep postgres
ii  postgresql-11                      11.22-9.pgdg20.04+1               amd64        The World's Most Advanced Open Source Relational Database
ii  postgresql-13                      13.19-1.pgdg20.04+1               amd64        The World's Most Advanced Open Source Relational Database
ii  postgresql-client-11               11.22-9.pgdg20.04+1               amd64        front-end programs for PostgreSQL 11
ii  postgresql-client-13               13.19-1.pgdg20.04+1               amd64        front-end programs for PostgreSQL 13
ii  postgresql-client-common           273.pgdg20.04+1                   all          manager for multiple PostgreSQL client versions
ii  postgresql-common                  273.pgdg20.04+1                   all          PostgreSQL database-cluster manager
ii  postgresql-common-dev              273.pgdg20.04+1                   all          extension build tool for multiple PostgreSQL versions
ii  timescaledb-2-2.3.1-postgresql-13  2.3.1~ubuntu20.04                 amd64        An open-source time-series database based on PostgreSQL, as an extension.
ii  timescaledb-2-loader-postgresql-11 2.3.1~ubuntu20.04                 amd64        The loader for TimescaleDB to load individual versions.
ii  timescaledb-2-loader-postgresql-13 2.15.3~ubuntu20.04                amd64        The loader for TimescaleDB to load individual versions.
ii  timescaledb-2-postgresql-11        2.3.1~ubuntu20.04                 amd64        An open-source time-series database based on PostgreSQL, as an extension.
```

#### Step 4 - 1c : Tune timescale
```
#
sudo timescaledb-tune --quiet --yes --pg-version 13
Using postgresql.conf at this path:
/etc/postgresql/13/main/postgresql.conf

Writing backup to:
/tmp/timescaledb_tune.backup202502191836

Recommendations based on 1.95 GB of available memory and 1 CPUs for PostgreSQL 13
shared_preload_libraries = 'timescaledb'	# (change requires restart)
shared_buffers = 510592kB
effective_cache_size = 1495MB
maintenance_work_mem = 255296kB
work_mem = 12764kB
wal_buffers = 15317kB
min_wal_size = 512MB
default_statistics_target = 500
random_page_cost = 1.1
checkpoint_completion_target = 0.9
max_connections = 20
max_locks_per_transaction = 64
autovacuum_max_workers = 10
autovacuum_naptime = 10
effective_io_concurrency = 200
timescaledb.last_tuned = '2025-02-19T18:36:30Z'
timescaledb.last_tuned_version = '0.11.0'
Saving changes to: /etc/postgresql/13/main/postgresql.conf
```

Start Postgres 13
```
sudo systemctl status postgresql@13-main
sudo systemctl start postgresql@13-main
sudo systemctl status postgresql@13-main
```

#### Step 4 - 1d : Check Postgres (13) and Timescale (2.3.1) versions
```
sudo su - postgres
psql -p 6432
postgres=# select version();
                                                               version                                                               
-------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 13.20 (Ubuntu 13.20-1.pgdg20.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0, 64-bit

postgres=# select * from pg_available_extensions where name like '%timescale%';
        name         | default_version | installed_version |                                        comment                                        
---------------------+-----------------+-------------------+---------------------------------------------------------------------------------------
 timescaledb_toolkit | 1.19.0          |                   | Library of analytical hyperfunctions, time-series pipelining, and other SQL utilities
 timescaledb         | 2.15.3          |                   | Enables scalable inserts and complex queries for time-series data (Community Edition)

postgres=# create database foo;
postgres=# \c foo
foo=# CREATE EXTENSION timescaledb WITH VERSION '2.3.1' CASCADE;
WARNING:  
WELCOME TO
 _____ _                               _     ____________  
|_   _(_)                             | |    |  _  \ ___ \ 
  | |  _ _ __ ___   ___  ___  ___ __ _| | ___| | | | |_/ / 
  | | | |  _ ` _ \ / _ \/ __|/ __/ _` | |/ _ \ | | | ___ \ 
  | | | | | | | | |  __/\__ \ (_| (_| | |  __/ |/ /| |_/ /
  |_| |_|_| |_| |_|\___||___/\___\__,_|_|\___|___/ \____/
               Running version 2.3.1
For more information on TimescaleDB, please visit the following links:

 1. Getting started: https://docs.timescale.com/timescaledb/latest/getting-started
 2. API reference documentation: https://docs.timescale.com/api/latest
 3. How TimescaleDB is designed: https://docs.timescale.com/timescaledb/latest/overview/core-concepts

Note: TimescaleDB collects anonymous reports to better understand and assist our users.
For more information and how to disable, please see our docs https://docs.timescale.com/timescaledb/latest/how-to-guides/configuration/telemetry.

CREATE EXTENSION

foo=# \c postgres
postgres=# drop database foo;
postgres=# \q
exit
```

### Step 4 - 2 : Upgrade to PG13 keeping Timescale at version 2.3.1

```
sudo systemctl status postgres*
sudo systemctl stop postgres*
sudo systemctl status postgres*
```

#### Step 4 - 2a : Run upgrade-check
```
sudo su - postgres
ln -s /etc/postgresql/11/main/postgresql.conf ./11/main/postgresql.conf
mkdir ./11/main/conf.d
```

```
/usr/lib/postgresql/13/bin/pg_upgrade -B /usr/lib/postgresql/13/bin -b /usr/lib/postgresql/11/bin -D /var/lib/postgresql/13/main -d /var/lib/postgresql/11/main -c
Performing Consistency Checks
-----------------------------
Checking cluster versions                                   ok
Checking database user is the install user                  ok
Checking database connection settings                       ok
Checking for prepared transactions                          ok
Checking for system-defined composite types in user tables  ok
Checking for reg* data types in user tables                 ok
Checking for contrib/isn with bigint-passing mismatch       ok
Checking for removed "abstime" data type in user tables     ok
Checking for removed "reltime" data type in user tables     ok
Checking for removed "tinterval" data type in user tables   ok
Checking for tables WITH OIDS                               ok
Checking for invalid "sql_identifier" user columns          ok
Checking for presence of required libraries                 ok
Checking database user is the install user                  ok
Checking for prepared transactions                          ok
Checking for new cluster tablespace directories             ok

*Clusters are compatible*
```

#### Step 4 - 2b : Run upgrade (**NOTE** ONLY if there were no errors in the previous step)
```
/usr/lib/postgresql/13/bin/pg_upgrade -B /usr/lib/postgresql/13/bin -b /usr/lib/postgresql/11/bin -D /var/lib/postgresql/13/main -d /var/lib/postgresql/11/main
Performing Consistency Checks
-----------------------------
Checking cluster versions                                   ok
Checking database user is the install user                  ok
Checking database connection settings                       ok
Checking for prepared transactions                          ok
Checking for system-defined composite types in user tables  ok
Checking for reg* data types in user tables                 ok
Checking for contrib/isn with bigint-passing mismatch       ok
Checking for removed "abstime" data type in user tables     ok
Checking for removed "reltime" data type in user tables     ok
Checking for removed "tinterval" data type in user tables   ok
Checking for tables WITH OIDS                               ok
Checking for invalid "sql_identifier" user columns          ok
Creating dump of global objects                             ok
Creating dump of database schemas
                                                            ok
Checking for presence of required libraries                 ok
Checking database user is the install user                  ok
Checking for prepared transactions                          ok
Checking for new cluster tablespace directories             ok

If pg_upgrade fails after this point, you must re-initdb the
new cluster before continuing.

Performing Upgrade
------------------
Analyzing all rows in the new cluster                       ok
Freezing all rows in the new cluster                        ok
Deleting files from new pg_xact                             ok
Copying old pg_xact to new server                           ok
Setting oldest XID for new cluster                          ok
Setting next transaction ID and epoch for new cluster       ok
Deleting files from new pg_multixact/offsets                ok
Copying old pg_multixact/offsets to new server              ok
Deleting files from new pg_multixact/members                ok
Copying old pg_multixact/members to new server              ok
Setting next multixact ID and offset for new cluster        ok
Resetting WAL archives                                      ok
Setting frozenxid and minmxid counters in new cluster       ok
Restoring global objects in the new cluster                 ok
Restoring database schemas in the new cluster
                                                            ok
Copying user relation files
                                                            ok
Setting next OID for new cluster                            ok
Sync data directory to disk                                 ok
Creating script to analyze new cluster                      ok
Creating script to delete old cluster                       ok
Checking for extension updates                              notice

Your installation contains extensions that should be updated
with the ALTER EXTENSION command.  The file
    update_extensions.sql
when executed by psql by the database superuser will update
these extensions.


Upgrade Complete
----------------
Optimizer statistics are not transferred by pg_upgrade so,
once you start the new server, consider running:
    ./analyze_new_cluster.sh

Running this script will delete the old cluster's data files:
    ./delete_old_cluster.sh

```

#### Step 4 - 2c : Backup the generated files...
```
mkdir upgrade_fm_11_to_13
mv update_extensions.sql analyze_new_cluster.sh delete_old_cluster.sh upgrade_fm_11_to_13/

#
exit
```

#### Step 4 - 2d : Start Postgres and check version
```
sudo systemctl start postgresql@13-main
sudo systemctl status postgres*
```

**NOTE** Replace `test_db` below with your database
```
sudo su - postgres
psql -p 6432
postgres=# select version();
                                                               version                                                               
-------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 13.20 (Ubuntu 13.20-1.pgdg20.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0, 64-bit

postgres=# select * from pg_available_extensions where name like '%timescale%';
        name         | default_version | installed_version |                                        comment                                        
---------------------+-----------------+-------------------+---------------------------------------------------------------------------------------
 timescaledb_toolkit | 1.19.0          |                   | Library of analytical hyperfunctions, time-series pipelining, and other SQL utilities
 timescaledb         | 2.15.3          |                   | Enables scalable inserts and complex queries for time-series data (Community Edition)

postgres=# \l
                                                   List of databases
   Name    |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
-----------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 postgres  | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
 template0 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =c/postgres          +
           |          |          |                 |         |         |            |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | postgres=CTc/postgres+
           |          |          |                 |         |         |            |           | =c/postgres
 test_db   | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 

postgres=# \c test_db
test_db=# \dx
                                      List of installed extensions
    Name     | Version |   Schema   |                            Description                            
-------------+---------+------------+-------------------------------------------------------------------
 plpgsql     | 1.0     | pg_catalog | PL/pgSQL procedural language
 timescaledb | 2.3.1   | public     | Enables scalable inserts and complex queries for time-series data
(2 rows)

test_db=# select * from pg_available_extensions where name like '%timescale%';
        name         | default_version | installed_version |                                        comment                                        
---------------------+-----------------+-------------------+---------------------------------------------------------------------------------------
 timescaledb_toolkit | 1.19.0          |                   | Library of analytical hyperfunctions, time-series pipelining, and other SQL utilities
 timescaledb         | 2.15.3          | 2.3.1             | Enables scalable inserts and complex queries for time-series data (Community Edition)

test_db=# \d
              List of relations
 Schema |       Name       | Type  |  Owner   
--------+------------------+-------+----------
 public | company          | table | postgres
 public | stocks_real_time | table | postgres

test_db=# select count(*) from stocks_real_time ;
  count  
---------
 3096768

test_db=# SELECT   time_bucket('1 hour', time) AS bucket,   first(price,time), last(price, time)   FROM stocks_real_time srt   WHERE time > now() - INTERVAL '30 days'   GROUP BY bucket  LIMIT 10;
         bucket         |  first  |  last  
------------------------+---------+--------
 2025-01-21 12:00:00+00 |  145.32 | 435.62
 2025-01-21 13:00:00+00 |   62.82 | 226.01
 2025-01-21 14:00:00+00 |  139.07 |  51.72
 2025-01-21 15:00:00+00 | 200.975 | 200.68
 2025-01-21 16:00:00+00 |  107.24 |  39.21
 2025-01-21 17:00:00+00 |  200.73 | 220.26
 2025-01-21 18:00:00+00 |  323.31 |    110
 2025-01-21 19:00:00+00 |  221.21 |  10.63
 2025-01-21 20:00:00+00 |  21.995 | 21.765
 2025-01-21 21:00:00+00 |  428.53 |  174.9
(10 rows)

test_db=# \q

#
exit
```
Stop Postgres 13
```
sudo systemctl stop postgresql@13-main
```

#### Step 4 - 2e : Stop and disable Postgres 11
```
sudo systemctl stop postgresql@11-main
sudo systemctl status postgresql@11-main
sudo systemctl disable postgresql@11-main
```

#### Step 4 - 2f : Start Postgres 13
##### Change port number of Postgres 13
Edit /etc/postgres/13/main/postgresql.conf and change port to 5432

```
sudo systemctl start postgresql@13-main
sudo systemctl enable postgresql@13-main
sudo systemctl status postgresql@13-main
```

## Step 5 : Upgrade Timescale 2.3.1 to Timescale 2.15.3

```
sudo su - postgres
psql
postgres=# select version();
                                                               version                                                               
-------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 13.19 (Ubuntu 13.19-1.pgdg20.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0, 64-bit

postgres=# select * from pg_available_extensions where name like '%timescale%';
    name     | default_version | installed_version |                                        comment                                        
-------------+-----------------+-------------------+---------------------------------------------------------------------------------------
 timescaledb | 2.15.3          |                   | Enables scalable inserts and complex queries for time-series data (Community Edition)

postgres=# \l
                              List of databases
   Name    |  Owner   | Encoding | Collate |  Ctype  |   Access privileges   
-----------+----------+----------+---------+---------+-----------------------
 test_db   | postgres | UTF8     | C.UTF-8 | C.UTF-8 | 

postgres=# \c test_db

test_db=# \dx
                                      List of installed extensions
    Name     | Version |   Schema   |                            Description                            
-------------+---------+------------+-------------------------------------------------------------------
 plpgsql     | 1.0     | pg_catalog | PL/pgSQL procedural language
 timescaledb | 2.3.1   | public     | Enables scalable inserts and complex queries for time-series data

test_db=# select * from pg_available_extensions where name like '%timescale%';
        name         | default_version | installed_version |                                        comment                                        
---------------------+-----------------+-------------------+---------------------------------------------------------------------------------------
 timescaledb_toolkit | 1.19.0          |                   | Library of analytical hyperfunctions, time-series pipelining, and other SQL utilities
 timescaledb         | 2.15.3          | 2.3.1             | Enables scalable inserts and complex queries for time-series data (Community Edition)

test_db=# \q
```

Upgrade Timescale. Replace `test_db` below with your database
```
psql
postgres=# \c test_db
test_db=# ALTER EXTENSION timescaledb UPDATE TO '2.15.3';
ALTER EXTENSION

test_db=# \dx
                                      List of installed extensions
    Name     | Version |   Schema   |                            Description                            
-------------+---------+------------+-------------------------------------------------------------------
 plpgsql     | 1.0     | pg_catalog | PL/pgSQL procedural language
 timescaledb | 2.15.3  | public     | Enables scalable inserts and complex queries for time-series data
(2 rows)

test_db=# select * from pg_available_extensions where name like '%timescale%';
        name         | default_version | installed_version |                                        comment                                        
---------------------+-----------------+-------------------+---------------------------------------------------------------------------------------
 timescaledb_toolkit | 1.19.0          |                   | Library of analytical hyperfunctions, time-series pipelining, and other SQL utilities
 timescaledb         | 2.15.3          | 2.15.3            | Enables scalable inserts and complex queries for time-series data (Community Edition)

test_db=# select count(*) from stocks_real_time ;
  count  
---------
 3096768

test_db=# SELECT   time_bucket('1 hour', time) AS bucket,   first(price,time), last(price, time)   FROM stocks_real_time srt   WHERE time > now() - INTERVAL '30 days'   GROUP BY bucket, symbol  LIMIT 10;
         bucket         | first  |  last   
------------------------+--------+---------
 2025-01-21 12:00:00+00 | 225.26 |  225.44
 2025-01-21 12:00:00+00 |  193.5 | 193.875
 2025-01-21 12:00:00+00 | 122.43 |  122.43
 2025-01-21 12:00:00+00 |  51.79 |   51.79
 2025-01-21 12:00:00+00 |  62.85 |   62.82
 2025-01-21 12:00:00+00 | 145.32 |  146.33
 2025-01-21 12:00:00+00 | 106.34 |  106.03
 2025-01-21 12:00:00+00 | 865.64 |  866.38
 2025-01-21 12:00:00+00 | 138.33 |  138.33
 2025-01-21 12:00:00+00 | 435.28 |  435.62

test_db=# \q
exit
```

# End of Phase (I)

## Prem

## Install PG 13
### Install PG13
```
sudo apt update
sudo apt list postgresql-13
sudo apt install postgresql-13
```

## Initialize PG13 
### Initialize PG13
```
sudo su - postgres
/usr/lib/postgresql/13/bin/pg_ctl -D /var/lib/postgresql/13/main initdb
...
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

initdb: warning: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    /usr/lib/postgresql/13/bin/pg_ctl -D /var/lib/postgresql/13/main -l logfile start

exit
```

## Configure PG13 
### Configure PG13
```
sudo su - postgres
mkdir pg13_config_backup
mkdir -p /etc/postgresql/13/main/conf.d
pushd /etc/postgresql/13/main
cp ~/pg13_configs/*.conf .
popd
mkdir ~/13/main/conf.d
pushd ~/13/main/
mv pg_hba.conf postgresql.conf pg_ident.conf ~/pg13_config_backup
ln -s /etc/postgresql/13/main/postgresql.conf .
ln -s /etc/postgresql/13/main/pg_hba.conf .
ln -s /etc/postgresql/13/main/pg_ident.conf .
chmod -R go-w /etc/postgresql/13
vi postgresql.conf
# change port number (e.g. 6432)
port = 6432                             # (change requires restart)

#
exit
```

## Test PG13
### Test PG13
```
pg_lsclusters 
Ver Cluster Port Status Owner     Data directory              Log file
11  main    5432 online postgres  /var/lib/postgresql/11/main /var/log/postgresql/postgresql-11-main.log
13  main    6432 down   <unknown> /var/lib/postgresql/13/main /var/log/postgresql/postgresql-13-main.log

sudo systemctl status postgresql@13-main
sudo systemctl start postgresql@13-main
sudo systemctl status postgresql@13-main

sudo su - postgres
psql -p 6432
postgres=# select version();
                                                               version                                                               
-------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 13.20 (Ubuntu 13.20-1.pgdg20.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0, 64-bit

postgres=# \q
#
exit
sudo systemctl stop postgresql@13-main
sudo systemctl status postgresql@13-main
```

### Transfer PG13 config files to host
Make sure the following sub-dirs exist in the home dir of the `postgres` user
```
sudo su - postgres
postgres@timescale-upgrade:~$ ls -al pg1?_configs
pg13_configs:
total 56
drwxrwxr-x 2 postgres postgres  4096 Feb 24 19:22 .
drwxr-xr-x 5 postgres postgres  4096 Feb 24 19:22 ..
-rw-r--r-- 1 postgres postgres   143 Feb 18 22:58 pg_ctl.conf
-rw-r----- 1 postgres postgres  4933 Feb 18 22:58 pg_hba.conf
-rw-r----- 1 postgres postgres  1636 Feb 18 22:58 pg_ident.conf
-rw-r--r-- 1 postgres postgres 28345 Feb 18 22:58 postgresql.conf
-rw-r--r-- 1 postgres postgres   317 Feb 18 22:58 start.conf

exit
```



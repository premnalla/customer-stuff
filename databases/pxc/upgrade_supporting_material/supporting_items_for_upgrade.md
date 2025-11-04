# Upgrading Percona XtraDB cluster from 5.7 (CentOS 7) to 8.0 (Rocky 9.5) - Supporting Items

## Take inventory

### Hosts used in the migration

| HOST             | OS       | Hostname        | IP | Shell user | PXC version | PURPOSE/DESCRIPTION                             |
|------------------|----------|-----------------|----|---------|-------------|-------------------------------------------------|
| Current Prod (cp) | CentOS 7 |    |  | centos  | PXC 5.7     | Current production cluster                      |
| Intermediate     | Rocky 8  |  |  | rocky   | PXC 5.7     | Intermediate host to help with migration easier |
| New Prod (np) #1 | Rocky 9  |  | | rocky   | PXC 8.0     | New production cluster                          |

### Environment variables

| Env variable      | Description                                                                      | Additional notes                                  |   |
|-------------------|----------------------------------------------------------------------------------|---------------------------------------------------|---|
| MYSQLROOTPW       | MySQL root user's password                                                       |                                                   |   |
| BACKUPUSER        | The replication user used for Master to Replica replication                      | Can be obtained from `/etc/my.cnf.d/secrets-backup.cnf` |   |
| BACKUPUSER_PW     | The replication user's password                                                  | Can be obtained from `/etc/my.cnf.d/secrets-backup.cnf` |   |
| MIGRATION_REPL_USER | The replication user used for Master to Replica replication                    | e.g. repl_user                                    |   |
| MIGRATION_REPL_USER_PW | The replication user's password                                             | Generate one                                      |   |
| CURR_PROD_MASTER_HOST | Pick a host that will serve as the Master for replication                    |                                                |   |
| INTERMEDIATE_HOSTNAME | The intermediate Rocky 8 host                                                |                                                   |   |
| INTERMEDIATE_IP   | The intermediate Rocky 8 host's IP                                               |                                                   |   |
| NEW_PROD_MASTER_HOST | The new Prod cluster host Rocky 8                                             |                                                   |   |
| NEW_PROD_MASTER_IP | The new Prod cluster host Rocky 8                                               |                                                   |   |
| BACKUP_LOC        | Configurable location of where backup will be stored                             |                                                   |   |
| BACKUP_RESTORE_STAGING_LOC | Restore staging location (configurable)                                 |                                                   |   |
| BACKUP_FILE       | Name of backup file (uncompressed)                                               |                                                   |   |
| BACKUP_FILE_COMPRESSED | Name of backup file (compressed)                                            |                                                   |   |
| CLUSTER_NAME      | Galara cluster name                                                              |                                                   |   |
| SERVER_ID         | MySQL server_id in my.cnf's `[mysqld]` section                                     |                                                   |   |
| CMON_USER         | ClusterControl user created in the target MySQL database for management purposes |                                                   |   |
| CMON_HOST         | ClusterControl host                                                              |                                                   |   |
| CMON_HOST_IP      | ClusterControl host's IP                                                         |                                                   |   |
| CURR_PROD_HOST_SHELL_USER | OS shell user on current Prod hosts. E.g. centos                         |                                                   |   |
| INTERMEDIATE_HOST_SHELL_USER | OS shell user on intermediate host. E.g. rocky                        |                                                   |   |
| NEW_PROD_HOST_SHELL_USER | OS shell user on new Prod host. E.g. rocky                                |                                                   |   |



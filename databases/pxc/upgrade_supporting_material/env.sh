#!/bin/sh

#
# Credentials
#
export MYSQLROOTPW='9ISyTrBOQneNP01rugO24y3mbiEUFXZr'           # IMPORTANT: replace
export MIGRATION_REPL_USER=repl_user
export MIGRATION_REPL_USER_PW='5DoT.tMQp}lW8EX9Ec}HnF,YGjuyJyO' # IMPORTANT: replace
export BACKUPUSER="backupuser"                                  # from secrets-backup.cnf
export BACKUPUSER_PW='dFTrC512wHk3MCG7J@089t{bm,F,Njyu'         # from secrets-backup.cnf
export CMON_USER=cmon

#
#
#
export CURR_PROD_HOST_SHELL_USER=centos         # NOTE: replace if necessary
export INTERMEDIATE_HOST_SHELL_USER=rocky       # NOTE: replace if necessary
export NEW_PROD_HOST_SHELL_USER=rocky           # NOTE: replace if necessary

#
# HOSTNAMEs and IPs
#
# NOTE: Replace with relevant values from your env.
#
export CMON_HOST=cc-tf-dev                  # IMPORTANT: replace
export CMON_HOST_IP=10.0.0.43               # IMPORTANT: replace
export CURR_PROD_MASTER_HOST=pxc57-cent7-3  # IMPORTANT: replace
export INTERMEDIATE_HOST=pxc57-80-rocky8    # IMPORTANT: replace
export INTERMEDIATE_IP=10.0.0.54           # IMPORTANT: replace
export NEW_PROD_MASTER_HOST=pxc8-rocky9-0-1 # IMPORTANT: replace
export NEW_PROD_MASTER_IP=10.0.0.109         # IMPORTANT: replace

#
# Directories and Filenames
#
export BACKUP_LOC=/tmp                                            # NOTE: replace if necessary
export BACKUP_FILE=$BACKUP_LOC/backup-full.xbstream
export BACKUP_FILE_COMPRESSED=$BACKUP_FILE.gz
export BACKUP_RESTORE_STAGING_LOC=$BACKUP_LOC/prod-backup         # NOTE: replace if necessary

#
#
#
export NODE_IP=$(hostname -I | awk '{$1=$1};1')
export NODE_NAME=$(hostname -s)
export CLUSTER_NAME="pxc57_80-cluster" # NOTE: even though we are installing PXC 5.7, we will be upgrading it to 8.0
export SERVER_ID=12000

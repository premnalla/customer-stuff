#!/bin/sh

#
# Credentials: Generate passwords for ROOT and REPLICATION USER and change below
#
export MYSQLROOTPW='9ISyTrBOQneNP01rugO24y3mbiEUFXZr'           # IMPORTANT: replace
export BACKUPUSER="backupuser"                                  # from secrets-backup.cnf
export BACKUPUSER_PW='dFTrC512wHk3MCG7J@089t{bm,F,Njyu'         # from secrets-backup.cnf

#
#
#
export NODE_IP=$(hostname -I | awk '{$1=$1};1')
export CLUSTER_NAME="pxc57-cluster"
export NODE_NAME=$(hostname -s)


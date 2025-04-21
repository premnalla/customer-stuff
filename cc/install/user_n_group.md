# Unix User and Group creation

As any user with sudo privileges:

```
export OS_USER_GROUP=cc
export OS_USER=ccuser
export OS_USER_HOME_DIR="/home/$OS_USER"
export ROOT_OS_USER=postgres
export ROOT_OS_USER_HOME_DIR="/home/$ROOT_OS_USER"

sudo groupadd $OS_USER_GROUP
sudo useradd -m -g $OS_USER_GROUP -s /bin/bash $OS_USER
#sudo passwd $OS_USER
```

**copy ssh dir contents over to new user**
```
sudo cp -rp $ROOT_OS_USER_HOME_DIR/.ssh $OS_USER_HOME_DIR
sudo chown -R $OS_USER:$OS_USER_GROUP $OS_USER_HOME_DIR/.ssh
sudo ls -al $OS_USER_HOME_DIR/.ssh
sudo su - $OS_USER
echo $PATH
exit
```

**modify sudoers file**
```
sudo vi /etc/sudoers
## Allow root to run any commands anywhere
root    ALL=(ALL)       ALL
$OS_USER ALL=(ALL) NOPASSWD: ALL
```

```
sudo su - $OS_USER
sudo ls /usr
exit
```
**make sure above don't prompt for password**

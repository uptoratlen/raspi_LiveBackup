#!/bin/bash

#run as root /sudo

# Config start
TIMESTAMP=`/bin/date +%Y%m%d%H%M%S`
BACKUPFILE="piimage_$TIMESTAMP.img" # backups will be named "piimage_YYYYMMDDHHMMSS.img"
BACKUPPATH_MOUNT=/mnt/nas-pibackup # local mount point
BACKUPPATH_REMOTE=//<IP OF SERVER>/pi/backup # the remote location (SMB)
BACKUP_USER=user1234 # the user 
BACKUP_PASSWORD=pasword1234 # the password
BACKUP_MAX_AGE=181 # days of retention
# Config end

#test line
SCRIPT_PATH=$(dirname "$(realpath $0)")

echo Mounting: ${BACKUPPATH_REMOTE} as ${BACKUPPATH_MOUNT}/
mount -t cifs -o user=${BACKUP_USER},password=${BACKUP_PASSWORD},rw,file_mode=0777,dir_mode=0777 ${BACKUPPATH_REMOTE} ${BACKUPPATH_MOUNT}/

if [ "$1" = "-d" ]; then  read -p "Press enter to continue" ; fi

if mountpoint -q "${BACKUPPATH_MOUNT}"; then
    echo "${BACKUPPATH_MOUNT} is a mountpoint - ok"
else
    echo "${BACKUPPATH_MOUNT} is not a mountpoint - exit script"
    exit 1
fi

if [ -w "${BACKUPPATH_MOUNT}" ]; then
    echo "${BACKUPPATH_MOUNT} is WRITABLE - ok";
else
    echo "${BACKUPPATH_MOUNT} is NOT WRITABLE -exit script";
    exit 2
fi

if [ -d "${BACKUPPATH_MOUNT}/piimages" ]
then
    echo "Directory ${BACKUPPATH_MOUNT}/piimages exists -ok"
else
    echo "Creating Dir ${BACKUPPATH_MOUNT}/piimages"
    mkdir ${BACKUPPATH_MOUNT}/piimages
fi

if [ "$1" = "-d" ]; then  read -p "Press enter to continue" ; fi
date
dd if=/dev/mmcblk0 bs=64K status=progress | gzip -c > ${BACKUPPATH_MOUNT}/piimages/${BACKUPFILE}.gz
date
if [ "$1" = "-d" ]; then  read -p "Press enter to continue" ; fi
date
pv ${BACKUPPATH_MOUNT}/piimages/${BACKUPFILE}.gz |gunzip > ${BACKUPPATH_MOUNT}/piimages/${BACKUPFILE}
date
if [ "$1" = "-d" ]; then  read -p "Press enter to continue" ; fi
date
${SCRIPT_PATH}/pishrink.sh -v ${BACKUPPATH_MOUNT}/piimages/${BACKUPFILE}
date

if [ "$1" = "-d" ]; then  read -p "Press enter to continue" ; fi

#Delete backups older than ${BACKUP_MAX_AGE} days
echo "Cleanup of previous backups - delete older than ${BACKUP_MAX_AGE} days"
/usr/bin/find ${BACKUPPATH_MOUNT}/piimages/ -name 'piimage_*.img*' -mtime +${BACKUP_MAX_AGE} -delete

umount ${BACKUPPATH_MOUNT}





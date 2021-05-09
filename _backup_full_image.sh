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

SCRIPT_PATH=$(dirname "$(realpath $0)")

#mount -t cifs -o user=${BACKUP_USER},password=${BACKUP_PASSWORD},rw,file_mode=0777,dir_mode=0777 ${BACKUPPATH_REMOTE} ${BACKUPPATH_MOUNT}/
mount -t cifs -o user=${BACKUP_USER},password=${BACKUP_PASSWORD},uid=1000,gid=1001 ${BACKUPPATH_REMOTE} ${BACKUPPATH_MOUNT}/

if [ -d "${BACKUPPATH_MOUNT}/piimages" ] 
then
    echo "Directory ${BACKUPPATH_MOUNT}/piimages exists." 
else
    echo "Creating Dir."
    mkdir ${BACKUPPATH_MOUNT}/piimages
fi

dd if=/dev/mmcblk0 bs=64K status=progress | gzip -c > ${BACKUPPATH_MOUNT}/piimages/${BACKUPFILE}.gz
${SCRIPT_PATH}/pishrink.sh -v ${BACKUPPATH_MOUNT}/piimages/${BACKUPFILE}


#Delete backups older than ${BACKUP_MAX_AGE} days
/usr/bin/find ${BACKUPPATH_MOUNT}/piimages/ -name 'piimage_*.img*' -mtime +${BACKUP_MAX_AGE} -delete

umount ${BACKUPPATH_MOUNT}

# raspi_LiveBackup
Create backup of Live Raspian without shutdown / shrink and cleanup

First I created nothing new, I read multiple (hundreds?) of posts, websites to collect all the info. In other words, a lot of people are involved. Some only mentioned some where a hint why or why not. But that got lost anlong the re-search wheer it was found original. But maybe others want to try it the same way as I did, so give credit to the unknown commenter, coder. I'm only the messanger.

The story goes like this:
I use a raspi which runs NodeRed, Domotiz, mosquitto, a co2 sensor and a DHT22 sensor. So by time the raspi get more important than it make sense without a backup.
Since Beginning of 2020 I created a backup script running a dailybackup of nodred and domotiz (scripts and DB), but there is the main gap of not having a backup for the complete raspi. At least I tend to make over time some chnages that got lost as undocumented. And by re-creating the same system that runs over 3 years some steps may got lost. And as you see it is more or less very vital that the system got downtime as small as possible. Preferable 0.
And there was a new update of Domotiz availabe, but I wanted to test the update first on a testsystem not the production system. A copy o fthe current system would be nice to have....

There was some time to spend on backup flows. It did not work, as I ran into the issue of ("Two SD crads of different vendors are not the same size in 'geometry - aka image to o large"). The asnwer for that is pretty simple : [piShrink](https://github.com/Drewsif/PiShrink). This script is the answer to (as I discovered 90% of restore issues of a SD Card). 

After "solving" aka use of piShrink the next issue of backup without shutdown was the target. And it turned out to be pretty easy. DD was abel to backup also a live system, some argue it doe snot make sense or it doe snot work, but at least in my env it worked very well. At least I was abel to restore the backup to a different sd card, without a issue. 

But the backup took ages (aka hours), my used SDCard uses ~ 3,5GB of the 32 GB. So I searched a bit and found a remark that gzip is faster on STDIN and OUT. After using gzip it was acceptable.
With all these parts I put all together and this is the script attached.


The backup on my Raspi 2 (yes still 2 as mentinoed there was actual backup, but now I got a good chance to replace it with a version 4) and the 3.5GB of the 32GB sdcard took 1h40m on the dd/gzip part and than 1h on the pishrink part.

The backup script also does some retention on the previous backups. This makes sense as a automatic should also do retention before space runs out, right

# Installtion
Here is asume on the rapi the user pi.
I created a subfolder 
```/home/pi/pishrink```

## pishrink 
Head over to [piShrink](https://github.com/Drewsif/PiShrink) for details.
In my usage I ddi not make the move to /usr/local/bin.
I use onyl the first 2 lines
```
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
chmod +x pishrink.sh
```
Pishrink uses some additional packages. I will name them here (based on a fresh Raspian - 2021-05-10)
* placeholder
* placeholder

Install them before using pishrink in a script. Otherwise the script will fail.
Info:
I needed to remove from pishrink.sh in the line 
```
  ...
  info "Copying $1 to $f..."
  cp --reflink=auto "$1" "$f"
  ...
```
the arguemnt ```--sparse=always```, otherwise thecp did not work. But that is something on my local system. I need to check the config.


## Copy this script
copy the script to the same folder as the pishrink.sh
In my case : ```/home/pi/pishrink```

```
cd /home/pi/pishrink
wget https://raw.githubusercontent.com/uptoratlen/raspi_LiveBackup/main/_backup_full_image.sh
chmod a+x _backup_full_image.sh
```

## crontab 
Of course the script could be used as a single execute, but I ran it on a monthly base.

Create a contab entry like:
```0 10 9 * * /home/pi/pishrink/_backup_full_image.sh```
eg. this would do a backup every month on the 9th at 10 AM. Of course that is up to you, how often this script is run.
For a easy crontab config see [corontab guru](https://crontab.guru/)

## Edit the _backup_full_image.sh
```
nano /home/pi/pishrink/_backup_full_image.sh
```

Edit the section Config

# Config start
TIMESTAMP=`/bin/date +%Y%m%d%H%M%S`
BACKUPFILE="piimage_$TIMESTAMP.img" # backups will be named "piimage_YYYYMMDDHHMMSS.img"
BACKUPPATH_MOUNT=/mnt/nas-pibackup # local mount point
BACKUPPATH_REMOTE=//<IP OF SERVER>/pi/backup # the remote location (SMB)
BACKUP_USER=user1234 # the user 
BACKUP_PASSWORD=pasword1234 # the password
BACKUP_MAX_AGE=181 # days of retention
# Config end

VAR | Value | Remark
--- | --- | ---
TIMESTAMP | `/bin/date +%Y%m%d%H%M%S` | attached to the filename
BACKUPFILE | "piimage_$TIMESTAMP.img" | the backup filename incl. the timstamp
BACKUPPATH_MOUNT | /mnt/nas-pibackup | the mount point; needs to be existing
BACKUPPATH_REMOTE | /<IP OF SERVER>/pi/backup | The remote SMB share; needs to be existing 
BACKUP_USER | user1234 | the smb user; need of course write rights
BACKUP_PASSWORD | pasword1234 | the password of the smb user 
BACKUP_MAX_AGE | 181 | the max age of the files in ${BACKUPPATH_MOUNT}/piimages/
  

## Mount
* ceate the BACKUPPATH_MOUNT folder
* make sure the remote path is accessible, eg. touch a file like ```sudo touch BACKUPPATH_REMOTE/helloworld```.

## First use
start the script by nano /home/pi/pishrink/_backup_full_image.sh
* The scritp will mount the remot epath
* create a gz file
* unpack the gz file
* shrink the uncompressed image

This may take like 3-4 hours. But the exact time depends on the sd card usage, sdcard type, network....









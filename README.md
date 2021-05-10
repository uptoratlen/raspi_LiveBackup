


# raspi_LiveBackup

# Table of contents

* TOC
{:toc}


  
  
## Overview  
* Does a live backup to a img file to SMB share  
* shrink the file with the help of pishrink  
* cleanup on a regular base   
  
So you already see:  nothing new. The only difference is that the script around [PiShrink](https://github.com/Drewsif/PiShrink) does it in one shot.  
  
## Background  
First, again I created nothing new. I read multiple (hundreds?) of posts, websites to collect all the info. In other   
words, a lot of people are involved. Some only mentioned in one of the posts a clue or a hint  why or   
why not.   
But who wrote it, to be honest that got lost a long the way of testing and trying.   
Maybe a different person will take this as a starting pint to create something better.   
In other words do not get offended by this, just ignore it in this case .  
  
## use case / why 
The story goes like this:  
I use a raspi which runs NodeRed, Domotiz, mosquitto, a co2 sensor and a DHT22 sensor. So by time the raspi get more important than it make sense without a backup.  
Since beginning of 2020 I created a backup script running a daily backup of nodred and domotiz (scripts and DB), but   
there is the main gap of not having a backup for the complete raspi. At least I tend to make over time some changes that got lost as undocumented. And by re-creating the same system that runs over 3 years some steps may got lost. And as you see it is more or less very vital that the system got downtime as small as possible. Preferable 0.  
And there was a new update of Domotiz available, but I wanted to test the update first on a testsystem not the production system. A copy o the current system would be nice to have....  
  
The first step was to get a IMG file and re-apply it to a same sdcard. (Win32DiskImager)  
It did not work, as I ran into the issue of ("Two SD cards of different vendors are not the same size in 'geometry - aka image to o large"). The answer for that is pretty simple : [PiShrink](https://github.com/Drewsif/PiShrink). This script is the answer to (as I discovered 90% of restore issues of a SD Card).   
  
After "solving" aka use of [PiShrink](https://github.%20com/Drewsif/PiShrink) the next issue of backup without shutdown was the target. And it turned out to be pretty easy. DD was abel to backup also a live system, some argue it doe snot make sense or it doe snot work, but at least in my env it worked very well. At least I was abel to restore the backup to a different sd card, without a issue.   
  
But the backup took ages (aka hours), my used SDCard uses ~ 3,5GB of the 32 GB. So I searched a bit and found a remark that gzip is faster on STDIN and OUT. After using gzip it was acceptable.  
With all these parts I put all together and this is the script attached.  
  
## Duration Time / Time Lap  
The backup on my Raspi 2 (yes still 2 as mentioned there was actual backup, but now I got a good chance to replace   
it with a version 4) showed this times:  
  
Step | Time  | Remark  
--- | --- | ---  
1 | ~140m | create the img/ZIP (~13GB file as image of a 32GB card)  
2 | ~50 m | unzip  to img  - speed test showed a better performance than direct to img file 
3 | ~5 m | phshrink  
  
This resulted in a 3.5 GB IMG file in less than 5 hours with 0 downtime.  
The dd stopped after 140minutes. The other two steps are also perfomred on the raspi. Of course if the steps 2 and 3 
are done pon eg. the remote system. It may be faster. I choose to have the raspi to do the job.
  
The backup script also does some retention on the previous backups. This makes sense as an automatic should also do   
retention before space runs out, right  

5h is pretty long, so the intention is not a daily run. But eg. a Monthly or weekly may be usefull.
At least for myself it worked this way. 
  
# Installation  
Here I assume on the raspi the user pi.  
I created a subfolder   
```/home/pi/pishrink```  
  
## pishrink 
Head over to [PiShrink](https://github.com/Drewsif/PiShrink) for details.  
In my usage I did not make the move to /usr/local/bin, I leave the [PiShrink](https://github.com/Drewsif/PiShrink) just in the subfolder of the user.  
Snip from the installation instructions.  
```  
mkdir /home/pi/pishrink  
cd /home/pi/pishrink
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh  
chmod +x pishrink.sh  
```  
[PiShrink](https://github.com/Drewsif/PiShrink) uses some additional packages. I will name them here (based on a 
fresh Raspian - 2021-05-10)
``` 
sudo apt-get install 
``` 
  
Install them before using pishrink in a script. Otherwise the script will fail.  
Info:  
I needed to remove from pishrink.sh in the line   
```  
  info "Copying $1 to $f..."
  cp --reflink=auto "$1" "$f" ...
  ```  
the argument ```--sparse=always```, otherwise the cp did not work. But that is something on my local system. I need to check the config. But that just as a note for me.  
  
## Copy this script  
copy the backup script to the same folder as the pishrink.sh  
In my case : ```/home/pi/pishrink```  
  
``` 
cd /home/pi/pishrink  
wget https://raw.githubusercontent.com/uptoratlen/raspi_LiveBackup/main/_backup_full_image.sh  
chmod a+x _backup_full_image.sh  
sudo apt-get install pv
```  
  
## Edit the _backup_full_image.sh  
```  
nano /home/pi/pishrink/_backup_full_image.sh  
```  
  
Edit the section Config  
```
# Config start  
TIMESTAMP=`/bin/date +%Y%m%d%H%M%S`  
BACKUPFILE="piimage_$TIMESTAMP.img" # backups will be named "piimage_YYYYMMDDHHMMSS.img"  
BACKUPPATH_MOUNT=/mnt/nas-pibackup # local mount point  
BACKUPPATH_REMOTE=//<IP OF SERVER>/pi/backup # the remote location (SMB)  
BACKUP_USER=user1234 # the user   
BACKUP_PASSWORD=pasword1234 # the password  
BACKUP_MAX_AGE=181 # days of retention  
# Config end  
```
  
VAR | Value | Remark  
--- | --- | ---  
TIMESTAMP | `/bin/date +%Y%m%d%H%M%S` | attached to the filename  
BACKUPFILE | "piimage_$TIMESTAMP.img" | the backup filename incl. the timstamp  
BACKUPPATH_MOUNT | /mnt/nas-pibackup | the mount point; needs to be existing  
BACKUPPATH_REMOTE | /\<IP OF SERVER\>/pi/backup | The remote SMB share; needs to be existing   
BACKUP_USER | user1234 | the smb user; need of course write rights  
BACKUP_PASSWORD | pasword1234 | the password of the smb user   
BACKUP_MAX_AGE | 181 | the max age of the files in ${BACKUPPATH_MOUNT}/piimages/  
    
  
## Mount  
* create the BACKUPPATH_MOUNT folder  in /mnt; ```sudo mkdir /mnt/nas-pibackup ```
* make sure the remote path is writeable, eg. touch a file like ```sudo touch $BACKUPPATH_REMOTE/helloworld```.  
  
## First use  
start the script by ```/home/pi/pishrink/_backup_full_image.sh```  
* The scrip will mount the remote path  
* create a gz file  
* unpack the gz file  
* shrink the uncompressed image  
  
This may take like 3-4 hours. But the exact time depends on the sd card usage, sdcard type, network....  
Let it run once so you may see if a package is missing.

## crontab
 Of course the script could be used as a single execute, but I ran it on a monthly base.  
  
Create a crontab entry like:  
```0 10 9 * * /home/pi/pishrink/_backup_full_image.sh```  
eg. this would do a backup every month on the 9th at 10 AM. Of course that is up to you, how often this script is run.  
For a easy crontab config see [corontab guru](https://crontab.guru/)  

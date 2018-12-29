# Scheduled, Encrypted, Backups with RClone and GDrive
## Outcomes
- Create a Google Drive account for storage
- Sync/Copy files (encrypting them) from a local directory to GDrive using RClone
- Create a script to run on a schedule
## Requirements
- Linux server (preferably Ubuntu) with access to file share
- Rclone https://rclone.org/
- Google Drive for Business (https://gsuite.google.com/products/drive/)
- Minimal bash scripting knowledge
## How-To
### Google Drive
I won't detail too much about Google Drive.  The point is, you need access to a GDrive with enough space to store you backups.
Google Drive for business is an effective way to have cheap, unlimited storage.  As of this writing, the cost is $10/mo/user.
They state that with less than 5 users, the storage limit is 1TB, though in practice this is not enforced.  Keep in mind that
this could change at any time and you may not want to rely on GDrive as a primary backup source.  It can be very effective for
short term uses such as migrating a file share, but for critical data you may want to pay for 5 users or have another storage
provider.
1. Get a Google Drive account
2. Create a directory in the root Drive called 'backups' (I will provide more detail later)
### Google Drive API (Optional)
This step is optional, but when we set up rclone, we will have the option to provide our own API credentials.  In my opinion,
this should be done as then we don't have to rely on rclone's API limitations.
1. Go to console.debelopers.google.com
2. Create a new project (name it whatever you want)
3. Click "Enable APIs and Services"
4. Search for Drive
5. Enable the API
6. Click credentials
7. Create a new OAuth ClientID
   - Select "Other"
8. The Client ID and Client Secret will be used when we configure rclone
### Rclone
#### Installing
Installing Rclone is fairly simple with Linux.  Use their provided install script to make it very simple: (As always, be
cautious when pasting executable commands and running foreign scripts on your machines!)
1. curl https://rclone.org/install.sh | sudo bash
#### Configuration
RClone configuration can be a little confusing and overwhelming.  With experience you can understand more of what is going on,
but I will just outline the basics.  Rclone uses what they call 'remotes' to define locations and actions for cloning files. We
will be using multiple remotes.  There will be one 'regular' remote and multiple encrypted remotes for each directory we are
copying. To create the primary remote, do the following:
1. rclone config (This will prompt for many different options, answer them as follows:
   - n/r/c/s/q> n	(new remote)
   - name> remote	(the name you want to use)
   - Storage> drive	(specify this will be a Google Drive remote)
   - client\_id> 	(Optional, paste in your client id from the google developer console)
   - client\_secret> 	(Optional, paste in your client secret from the google developer console)
   - Project\_number>   (leave this blank)
   - service\_account\_file> (leave this blank)
   - object\_acl>	(leave this blank)
   - bucket\_acl>	(leave this blank)
   - location>		(choose the location closest to you)
   - storage\_class>	(leave this blank)
   - y/n>
     - This option is for the auto config.  This is where it can get a little tricky.  If you are running this on a graphical
       desktop, you should choose yes.  It will open up a browser window and prompt for your google credentials.  If you are
       not on a graphical desktop, you should select no and it will give you a link to use.
     - When I initially configured rclone on my headless server, I tried manual but the copying the code that you get proved to
       be impossible. No matter what, it would not paste properly into my terminal.  If this is the case, you may need to do 
       some tricky SSH port forwarding to use the auto config.
     - Whichever you choose, follow the promptings and get your authorization code.
   - y/n> n		(this is for configuring a Team Drive, which we did not do. Enter no)
   - y/e/d> y		(assuming the configuration printing looks correct, enter yes)
If the configuration worked properly, running this command should list your one directory in your drive:
2. rclone lsd remote:
> user@ubuntu:~$ rclone lsd remote:
> -1 2018-01-01 12:00:00	-1 backups
The next step will be to create the encrypted remotes so that we can copy our data over in a safe format.  In this example, I
am creating an encrypted remote for my movies directory.  I will be using a different remote for each directory so that I can
keep things organized.  This example will encrypt every file and directory name except the root name (movies).  Having multiple
remotes takes time to setup, but in my opinion it is a very effective way of understanding what is going on and keeping things
organized.
3. rclone config
   - e/n/d/r/c/s/q> n			(new remote)
   - name> crypt-movies			(name this whatever you like)
   - Storage> 8				(choose Encrypted remote)
   - remote> remote:backups/movies	(specify where on the GDrive this will point. This location means in the backups/movies
                                         directory)
   - filename\_encryption> 2		(standard encryption means file names)
   - directory\_name\_encryption> 1	(encrypt directory names too, this is why we put the remote in a subdirectory of backups)
   - y/g> y				(enter a password for the encryption or use g to have rclone generate one)
   - y/g/n> y				(highly recommended, enter a salt phrase for the encryption)
   - y/e/d> y				(assuming the config looks right, enter yes)
Now we can run some simple tests to make sure everything is working correctly.  Copy over a small file and view it with each
remote to see if it is encrypted.
4. touch newfile.txt
   - rclone -q copy newfile.txt crypt-movies:
   - rclone -q ls crypt-movies:
>	1 newfile.txt
   - rclone -q ls remote:backups/movies:
>	1 lkjasdf83jhsdfg		(some gibberish, encrypted file name!)
### Initial Backup
If you have a lot of data, you probably want to back it all up first before automating the backups. This way you can make
sure that it all works properly first.  There are a lot of options to rclone commands, and many commands that you can use
for all of these tasks.  It will list a few of the commands that I use and the options that I chose.  For more details go
to https://rclone.org/docs/
#### Copy
- rclone copy
- rclone \-\-stats=5s \-\-stats\-log\-level NOTICE copy /MEDIA/movies crypt-movies:
  - This command (I run it in a tmux sessions) will copy all files in /MEDIA/movies to the remote (backups/movies) and
    will encrypt all the file names.  It will print out stats about the copy every five seconds so that you can see its
    progress.
### Automation
Automation of this task is quite simple.  In this repository I provided a couple of simple files that I use.  The effect
of these files is that every night at midnight rclone attempts to do a copy of each of my remotes and writes the results
to a log file. You can copy these files and modify them to your needs:
- rclone-cron.sh
  - This is the main script.  The first few lines check if the process is already running and exits if it is.  The next
    section simply executes rclone copy for each of my remotes, copying their directories on my MEDIA file share to the
    drive.  The \-\-min\-age command makes it so that it doesn't copy files that might be only partially copied to the
    file share at the time. (I have a lot of automated systems that write to the drive, and they might be running at
    midnight).
  - If you create or copy this file, make sure to mark the script as executable with:
    - chmod a+x rclone-cron.sh
- rclone-crontab
  - This file is what my crontab looks like.  It simply executes the shell script every night at midnight.  You can modify
    it or create a new one with either:
    - crontab rclone-crontab		(this will write rclone-crontab to your user crontab)
    - crontab -e			(this will open your crontab for editting so you can add the line there)
  - For more information on crontabs see https://crontab.guru/
There you have it!  Cron on your system will run your backup script every day at midnight! You can view the logs when you
need to in order to make sure everything ran properly!

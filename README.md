# NextcloudPi
Full Nextcloud Docker Container for Raspberry Pi 4 &amp; 5 with Collabora Online server (Nextcloud Office) behind Nginx Reverse Proxy Manager + GoAccess Charts. Supported with Redis Cache + Cron Jobs.

# NextcloudPi Image Support + 
Nextcloud image errors fixed and addon supported
- ***All Errors fixed***
- Redis Cache Server
- Nextcloud Cron Job Fix - via supervisord
- Php values editable in nextcloud.ini file
- Nginx Reverse Proxy Manager Support
- Video Thumbnail Support
- Maintenance window start support - will run jobs between 01:00am UTC and 05:00 am UTC:
- Next Cloud Office Ready - Collabora Office Server - Install separately
- opcache.memory_consumption=128 increase to opcache.memory_consumption=256
- smb client


# INSTRUCTIONS MUST BE FOLLOWED IN THIS ORDER
1. GIT CLONE
2. DOCKER COMPOSE BUILD
3. DOCKER COMPOSE UP
4. NGINX REVERSE PROXY MANAGER SETUP FOR NEXTCLOUD
5. INITIAL NEXTCLOUD USER SETUP VIA WEB BROWSER
6. NEXTCLOUD DOCKER VOLUME CONFIG.PHP UPDATE
7. RESTART NEXTCLOUD CONTAINER FOR CHANGES TO TAKE EFFECT.


# 1. GIT CLONE - In Host Machine

```
git clone https://github.com/iamjavadali/nextcloudpi.git
cd nextcloudpi/nextcloud
```

# Install NextcloudPi Container

- 4 containers
	1. nextcloud
	2. nextcloud_db
	3. nextcloud_cron
	4. nextcloud_redis

Edit the following files if you would like to make changes to php settings and database details

- nexcloudpi/nextcloud/nextcloud/Dockerfile
- nextcloudpi/nextcloud/mysql/Dockerfile

# 2-3. DOCKER COMPOSE BUILD + DOCKER COMPOSE UP

Build & run the nextcloudpi container
```
sudo docker compose build
sudo docker compose up -d
```

# 4. NGINX REVERSE PROXY MANAGER w/ GoAccess Charts Install + SETUP

- 3 containers
	1. nginxproxymanagerpi
	2. nginxproxymanagerpidb
	3. nginxproxymanagerpistats

Enter docker-compose directory

```cd nextcloudpi/nginx-proxy-manager```

Build Dockerfile

```sudo docker compose build```

Build + Run docker compose

```sudo docker compose up -d```

Port Info:

	nginx admin port: 81
	goaccess stats port: 7880
	mariadb port: 3306

After the Nginx Proxy Manager is running for the first time, the following will happen:

	GPG keys will be generated and saved in the data folder
	The database will initialize with table structures
	A default admin user will be created

This process can take a couple of minutes depending on your machine.

Default Administrator User

	Email:    admin@example.com
	Password: changeme

Immediately after logging in with this default user you will be asked to modify your details and change your password.

Nginx official documentation setup

	https://nginxproxymanager.com/setup/#using-mysql-mariadb-database


# NextcloudPi Nginx Proxy Settings

***In Nginx reverse Proxy manager, add your nextcloudpi proxy***
```
scheme = http
ip = ip of host
port = port number of nextcloud docker container
websocket support = on
block common exports = on
ssl = on
force ssl = on
HTTP/s support = on
HSTS enabled = on
HSTS subdomains = on
```
***You can use the Free LetsEncrypt SSL or upload your own to add a secure connection***

Add this to your Nginx reverse proxy settings in ***advanced - custom Nginx configuration.***

This below fixes one of the error you receive in the "Overview" tab in your "Administration settings" for .well-known/carddav and .well-known/caldav
```
location /.well-known/carddav {
    return 301 $scheme://$host/remote.php/dav;
}

location /.well-known/caldav {
    return 301 $scheme://$host/remote.php/dav;
}
```

# Go to your nextcloud IP or domain you setup and start the initial setup.
```
- enter username
- create password
```

- Go to "Personal Settings" in your nextcloud panel and add your email address to your profile
- Now go to "Administration settings" in your nextcloud panel and navigate to "Basic settings" 
- For background jobs: change from "AJAX" to "Cron (Recommended)"
- For "Email server" add your email server settings of the email account which will use to send out nextcloud-related emails from and then test the connection by pressing the button "Send email" to Test and verify email settings
- Now go to the "Overview" tab in your "Administration settings"
- Look at the addtional error codes and warnings and follow the instructions below to fix them.


***The commands below must be run in the docker host machine where the nextcloud container is installed or by accessing the config.php file from inside your nextcloud container.***

Become the root user on your ***host*** machine
```
sudo -i
```
Navigate to the docker nextcloud volume into the config directory
```
cd /var/lib/docker/volumes/nextcloudpi_nextcloud/_data/config
```
use a text editor to edit the config.php file
```
nano config.php
```

***Add the following code at the bottom of the file before the closing statement );***

This code fixes the phone code error; make sure to ***change*** to your region code
```
  'default_phone_region' => 'US',
```
This code fixes the insecure url error
```
  'overwriteprotocol' => 'https',
```
This code adds maintenance window time and fixes error
```
  'maintenance_window_start' => 1,
```
 
This whole array will allow your nextcloud to generate preview thumbnails of videos and other formats
```
  'enable_previews' => true,    
  'enabledPreviewProviders' => 
  array (
    0 => 'OC\\Preview\\Movie',
    1 => 'OC\\Preview\\PNG',
    2 => 'OC\\Preview\\JPEG',
    3 => 'OC\\Preview\\GIF',
    4 => 'OC\\Preview\\BMP',
    5 => 'OC\\Preview\\XBitmap',
    6 => 'OC\\Preview\\MP3',
    7 => 'OC\\Preview\\MP4',
    8 => 'OC\\Preview\\TXT',
    9 => 'OC\\Preview\\MarkDown',
    10 => 'OC\\Preview\\PDF',
  ),
```


# Colabora Online (Nextcloud Office) Server Installation

- 1 containers
	1. collabora

```
cd nextcloudpi/collabora
```
Edit the collabora-code.sh file
```
nano collabora-code.sh
```
Edit the following variables

Set this to the IP+Port pointing to the collabora/code server
```
domain=###.###.###.###:PORT	
``` 
Set this to the domain pointed to your collabora/code server
```
server_name=your-domain.com	
``` 
Change this username for the admin panel
```
user=admin
```
Change this password for the admin panel
```
pass=password
``` 
Change this for your local time zone	
```
tz=America/New_York	
```
Save and make the bash script file is executable
```
chmod +x collabora-code.sh
```
Run the script
```
./collabora-code.sh
```

***In Nginx reverse Proxy manager, add your Colabora Online proxy***
```
scheme = https
ip = ip of host
port = port number of collabora docker container
websocket support = on
block common exports = off
ssl = on
force ssl = on
HTTP/s support = on
HSTS enabled = on
HSTS subdomains = on
```

# In your nextcloud installation head over to administration settings -> Office

- Select "Use your own server"
- Enter URL (and Port) of collabora Online-server: example: use either domain or server_name values - https://office.solrstation.com or https://192.168.1.101:9980
- Allow list for WOPI requests: enter the following - 172.70.0.0/16, 162.158.0.0/16
	- You can find the IP range of your WOPI host by entering 0.0.0.0/16 in your WOPI allow list and then opening up a document in nextcloud to get the WOPI denied error. Upon receiving this error, you can look at the logs in your administration settings for warnings on WOPI requests denied.
	- Example: WOPI request denied from 172.70.111.138 as it does not match the configured ranges: 0.0.0.0
	- Take the denied from IP and turn it into a range by keeping the first two values. example: 172.70
	- Then enter .0.0/16 to the end of it. example: 172.70.0.0/16
	- Try opening a document again, and you will get another WOPI denied error, this time showing you another IP range.
	- Example: WOPI request denied from 162.158.154.60 as it does not match the configured ranges: 172.70.0.0/16
	- Add this IP as you did before to your WOPI allow list by keeping the first 2 parts of the IP and turning the remaining into a range: example: 162.158.0.0/16
	- Combine both IP ranges together and add them into your WOPI allow list
	- example: 172.70.0.0/16, 162.158.0.0/16
	- Open a document again in nextcloud. Now you should not have any WOPI errors, and the document should open without any further errors.


***YOU SHOULD NOW HAVE A FULLY FUNTIONAL NEXTCLOUD RUNNING ON YOUR RASPBERRY PI 4 OR 5 WITH NO ERRORS AND DOCUMENT EDITING SUPPORT BEHIND A REVERSE PROXY AND FULLY SECURED.***

# If you do not wish to build the image, you can add Dockerfile variables into the docker-compose file for Nextcloudpi & Nginx Reverse Proxy Pi and just run docker compose up -d

***If you found this how-to helpful, please share with others and provide me with any feedback with any issues.***

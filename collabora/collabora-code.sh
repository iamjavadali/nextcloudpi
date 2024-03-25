#!/bin/bash


domain=192.168.86.58:9980 # Set this to the IP pointing to the collabora/code server
server_name=office.solrstation.com #S et this to the domain pointed to your collabora/code server
user=admin # change this username for admin panel
pass=password # change this password for admin panel
tz=America/New_York # change this for your local timezone


sudo docker pull collabora/code
# sudo docker run --name collabora -t -d -p 9980:9980 -e “domain=$domain” -e “server_name=$server_name” --restart always --cap-add MKNOD collabora/code


sudo docker run --name collabora -t -d -p 9980:9980 --privileged -e username=$user -e password=$pass -e “domain=$domain” -e TZ=$tz -e “server_name=$server_name” --restart always --cap-add MKNOD collabora/code


# URL (and Port) of Collabora Online-server: https://office.solrstation.com    #change this to your url behind reverse proxy
# WPOI allow list: 172.70.0.0/16     #check your logs when connecting to document and it will give you a rejected IP. you can take the first two numbers and add .0.0/16 to the end of it.
# Use these default WOPI: 172.70.0.0/16, 162.158.0.0/16

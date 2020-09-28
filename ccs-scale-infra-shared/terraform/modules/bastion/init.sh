#! /bin/bash
#

set -e -x

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install ec2-instance-connect

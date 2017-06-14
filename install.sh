#!/bin/bash
#
# Copyright 2015, Cloudera Inc.
#
# All rights reserved - Do Not Redistribute
#

if [ $USER != "root" ]; then
  echo "install.sh must be run as root (sudo ./install.sh)"
  exit 1
fi

USER=$SUDO_USER
USER_HOME=$(eval echo ~${SUDO_USER})

# Detect OS distribution
DIST="$(lsb_release -i | gawk -F'\t' '{print $2}')"

# Install Curl and Git
if [ $DIST == "Ubuntu" ]; then
  sudo apt-get install -y curl
  sudo apt-get install -y git
elif [ $DIST == "CentOS" ]; then
  sudo yum install curl
  sudo yum install git
  # Add apache-maven to the yum repo
  wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
fi

chef_binary=/usr/bin/chef-solo
# Are we on a vanilla system?
if ! test -f "$chef_binary"; then
  export DEBIAN_FRONTEND=noninteractive
  # Install Chef
  curl -L https://omnitruck.chef.io/install.sh | bash -s -- -v 12.3.0
fi

# Get the location of this impala-setup/ repo
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run chef-solo to configure the Impala dev machine
sudo -u $USER sed -i "s/username = ''/username = '$USER'/" $REPO_DIR/cookbooks/impala/attributes/default.rb
"$chef_binary" -c $REPO_DIR/solo.rb -j $REPO_DIR/impala.json

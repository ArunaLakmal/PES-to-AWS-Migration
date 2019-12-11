#!/bin/bash
sudo apt-get update -y
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
sudo add-apt-repository ppa:eugenesan/ppa
sudo apt-get update -y
sudo apt-get install jq -y
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get install -y openjdk-8-jre-headless
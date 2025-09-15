#!/bin/bash

sudo apt install wget curl -y
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo apt update -y
sudo apt install code -y
wget https://download-cdn.jetbrains.com/python/pycharm-2025.2.1.1.tar.gz
sudo tar xzf pycharm-*.tar.gz -C /opt/
sudo apt install inkscape -y

#!/bin/bash

sudo apt install wget -y
wget "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" --no-check-certificate
sudo apt install ./code_1.104.0-1757488003_amd64.deb - y
wget https://download-cdn.jetbrains.com/python/pycharm-2025.2.1.1.tar.gz
sudo tar xzf pycharm-*.tar.gz -C /opt/
sudo apt install inkscape -y

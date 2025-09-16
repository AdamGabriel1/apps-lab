#!/bin/bash

sudo apt install neofetch -y
sudo apt install wget -y
wget https://vscode.download.prss.microsoft.com/dbazure/download/stable/f220831ea2d946c0dcb0f3eaa480eb435a2c1260/code_1.104.0-1757488003_amd64.deb
sudo apt install ./code_1.104.0-1757488003_amd64.deb -y
wget https://download-cdn.jetbrains.com/python/pycharm-2025.2.1.1.tar.gz
sudo tar xzf pycharm-*.tar.gz -C /opt/
sudo apt install inkscape -y

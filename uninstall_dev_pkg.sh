#!/bin/bash

sudo apt remove taqosurvey
sudo apt autoremove
sudo rm /usr/bin/taqo
sudo rm /usr/bin/taqo_daemon
sudo rm /etc/xdg/autostart/taqo_daemon.desktop
rm -rf ~/.taqo

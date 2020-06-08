#!/bin/bash

sudo apt remove taqosurvey
sudo apt autoremove
sudo rm -rf /usr/share/taqo
sudo rm /usr/bin/taqo
sudo rm /usr/bin/taqo_daemon
rm -rf ~/.taqo

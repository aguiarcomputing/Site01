#!/bin/bash

# Define o novo nome do MacBook
NEW_HOSTNAME="MacBookPro_0001"

# Altera o hostname
sudo scutil --set ComputerName "$NEW_HOSTNAME"
sudo scutil --set HostName "$NEW_HOSTNAME"
sudo scutil --set LocalHostName "$NEW_HOSTNAME"

# Confirma a alterao
echo "O nome do MacBook foi alterado para: $NEW_HOSTNAME"
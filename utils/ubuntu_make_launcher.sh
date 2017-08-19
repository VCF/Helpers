#!/bin/bash

## THIS IS WHY I HATE UBUNTU

# Making a desktop launcher used to be a simple right-click on the
# desktop. Apparently that was deemed too confusing by Canonical, so
# they deleted the menu option. You now have to run a command line
# script to create a launcher.

# From @Liso:
# https://askubuntu.com/a/854398

# Requires gnome-panel installed:
# sudo apt-get install gnome-panel
gnome-desktop-item-edit --create-new ~/Desktop


#!/bin/bash

# KDE's plasmashell (windowing environment) steadily gobbles up
# resources. The only apparent solution is to restart it


## Run in new shell to avoid (?) spam to the current terminal

# https://askubuntu.com/a/871707
## bash -c "killall plasmashell && kstart plasmashell"

# https://superuser.com/a/933894
bash -c "kbuildsycoca5 && kquitapp5 plasmashell && kstart5 plasmashell"


## https://bugs.kde.org/show_bug.cgi?id=356479
##    Status: 	CLOSED FIXED  (yeah, nope)

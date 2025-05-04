#!/bin/bash

## How is it possible that you manage to replace pulseaudio with something
## that sucks as much or more

## replacement for killall pulseaudio
##  -> Linux Mint 22 wilma  (May 2025)

systemctl --user restart pipewire.service

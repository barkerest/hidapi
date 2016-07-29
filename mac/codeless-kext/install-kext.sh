#!/bin/sh

echo 'Installing codeless-kext for LCDs...'

sudo cp -r PicoLCD256x64.kext /System/Library/Extensions/PicoLCD256x64.kext

sudo touch /System/Library/Extensions

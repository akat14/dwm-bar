#!/bin/sh

# A dwm_bar function to show the master volume of ALSA
# Joe Standring <git@joestandring.com>
# GNU GPLv3

# Dependencies: alsa-utils

dwm_alsa () {
	STATUS=$(amixer sget Master | tail -n1 | sed -r "s/.*\[(.*)\]/\1/")
	VOL=$(amixer get Master | tail -n1 | sed -r "s/.*\[(.*)%\].*/\1/")
	if [ "$STATUS" = "off" ]; then
		printf "婢"
	else
	        # removed this line because it may get confusing
	        if [ "$VOL" -gt 0 ] && [ "$VOL" -le 33 ]; then
	            printf " %s%%" "$VOL"
	        elif [ "$VOL" -gt 33 ] && [ "$VOL" -le 66 ]; then
	            printf " %s%%" "$VOL"
	        else
	            printf " %s%%" "$VOL"
        	fi
        fi
}

dwm_alsa

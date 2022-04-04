#!/bin/sh

# A dwm-bar module that shows the current master volume of Alsa, PulseAudio, or
# PipeWire
# Joe Standring <git@joestandring.com>
# https://github.com/joestandring/dwm-bar/blob/master/modules/dwm_pulse.sh
# GNU GPLv3

# Thanks to Changaco for progress bar styles:
# https://github.com/Changaco/unicode-progress-bars

# Dependencies: pamixer (PulseAudio/PipeWire)/alsa-utils (Alsa)

# OPTIONS
# -i Identifiers to be displayed before module data corresponding to muted,
#    low volume, medium volume, and high volume e.g. "ﱝ 奄 奔 墳"
# -f How to display volume data. 0: Nothing (just the percentage),
#    1: "▰▰▰▰▱▱▱▱▱▱", 2: "▮▮▮▮▯▯▯▯▯▯" 3: "⚫⚫⚫⚫⚪⚪⚪⚪⚪⚪"
# -p Include volume percentage after volume bar
# -a Use amixer (Alsa). pamixer (PulseAudio/PipeWire) will be used if not set
# -s Seperator displayed before module e.g. "["
# -S Seperator displayed after module e.g. "]"
# -c Hexidecimal forground and background color values for identifier formatted
#    as "identifier fg identifier bg". Requires status2d e.g. "#21222c #bd93f9"
# -C Hexidecimal forground and background color values for data formatted as
#    "identifier fg identifier bg". Requires status2d e.g. "#bd93f9 #21222c"

dwm_volume() {
    USE_ALSA=0
    SHOW_PER=0

    while getopts "i:f:pas:S:c:C:" OPT; do
        case "$OPT" in
            # Set the identifiers that displays before data
            i)
                IDEN_MUTE="$(printf "%s" "$OPTARG" | cut -d' ' -f1) "
                IDEN_LOW="$(printf "%s" "$OPTARG" | cut -d' ' -f2) "
                IDEN_MED="$(printf "%s" "$OPTARG" | cut -d' ' -f3) "
                IDEN_HIGH="$(printf "%s" "$OPTARG" | cut -d' ' -f4) "
                ;;
            # Set full and empty volume bar symbols for selected arg
            f)
                case "$OPTARG" in
                    1)
                        BAR_FULL="▰"
                        BAR_EMPTY="▱"
                        ;;
                    2)
                        BAR_FULL="▮"
                        BAR_EMPTY="▯"
                        ;;
                    3)
                        BAR_FULL="⚫"
                        BAR_EMPTY="⚪"
                        ;;
                esac
                ;;
            # Show the current volume as a percentage
            p)
                SHOW_PER=1
                ;;
            # Which backend to use
            a)
                USE_ALSA=1
                ;;
            # Set the first seperator that is displayed first in the module
            s)
                SEP1="$OPTARG"
                ;;
            # Set the second seperator that is displayed last in the module
            S)
                SEP2="$OPTARG"
                ;;
            # Apply colors to the identifier and reset
            c)
                set_iden_colors "$OPTARG"
                ;;
            # Apply colors to the main module body and reset
            C)
                set_data_colors "$OPTARG"
                ;;
            *)
                printf "dwm-bar: dwm_volume: invalid option -- %s\n" \
                "$OPTARG" >&2
                exit 1
                ;;
        esac
    done

    # Get current volume and mute status from pamixer/amixer
    if [ "$USE_ALSA" -eq 1 ]; then
        if ! command -v amixer > /dev/null; then
            printf \
            "dwm_volume: amixer not found. Are you sure it's installed?\n" >&2
            kill_bar 1
        fi

        VOL=$(amixer get Master | tail -n1 | sed -r "s/.*\[(.*)%\].*/\1/")
        MUTED=$(amixer sget Master | tail -n1 | sed -r "s/.*\[(.*)\]/\1/")
    else
        if ! command -v pamixer > /dev/null; then
            printf \
            "dwm_volume: pamixer not found. Are you sure it's installed?\n" >&2
            kill_bar 1
        fi

        VOL=$(pamixer --get-volume)
        MUTED=$(pamixer --get-mute)
    fi

    # Show volume percentage
    if [ "$SHOW_PER" -eq 1 ]; then
        PER="$VOL%"
    fi

    # Treat volume being 0 and muted as the same
    if [ "$MUTED" = "true" ] || [ "$MUTED" = "off" ]; then
        VOL=0
        PER="MUTE"
    fi

    # Display corresponding identifier to audio level
    if [ "$VOL" -eq 0 ]; then
        IDEN="$IDEN_MUTE"
    elif [ "$VOL" -gt 0 ] && [ "$VOL" -le 33 ]; then
        IDEN="$IDEN_LOW"
    elif [ "$VOL" -gt 33 ] && [ "$VOL" -le 66 ]; then
        IDEN="$IDEN_MED"
    else
        IDEN="$IDEN_HIGH"
    fi 

    # The amount of full and empty bars to make up the volume bar
    FULL_BARS=$((VOL/10))
    EMPTY_BARS=$((10-FULL_BARS))

    # Display the volume bar
    i=0
    while [ $i -lt $FULL_BARS ]; do
        DATA="${DATA}$BAR_FULL"
        true $(( i=i+1 ))
    done
    i=0
    while [ $i -lt $EMPTY_BARS ]; do
        DATA="${DATA}$BAR_EMPTY"
        true $(( i=i+1 ))
    done

    # If both a bar and percentage are used, add a space between them
    if [ "$PER" != "" ] && [ "$BAR_FULL" != "" ]; then
        PER=" $PER"
    fi

    # Print data used by dwm_bar.sh
    printf "%s%s%s%s%s%s%s%s%s%s%s" \
        "$SEP1" \
        "$IDEN_COL_FG" \
        "$IDEN_COL_BG" \
        "$IDEN" \
        "$IDEN_COL_RESET" \
        "$DATA_COL_FG" \
        "$DATA_COL_BG" \
        "$DATA" \
        "$PER" \
        "$DATA_COL_RESET" \
        "$SEP2"
}
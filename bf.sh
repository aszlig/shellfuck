#!/usr/bin/env bash
# Copyright (c) 2006-2013 aszlig <aszlig@redmoonstudios.org
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

# sorry, but because of read -n i had to introduce a bashism :-/
DEBUG=1;

isdbg(){
    case "$DEBUG" in
        ([yY]|[yY][eE][sS]) return 0;;
        (0) return 1;;
        (*)
        echo "$DEBUG" | grep -q '^-\{0,1\}[0-9]\{1,\}$';
        return $?;;
    esac;
}

bf_get()
{
    P_ARRAY="$1";
    P_APOS="$2";

    printf '%s\n' "$P_ARRAY" |
    tr ' ' '\n' |
    grep . |
    sed -n "$(($P_APOS+1))p";
}

bf_manip()
{
    P_ACTION="$1";
    P_ARRAY="$2";
    P_APOS="$3";

    case "$P_ACTION" in
        (\*) CHANGED=$4;;
        (*)
            CHANGED=$(($(bf_get "$P_ARRAY" "$P_APOS") $P_ACTION 1));
            case $CHANGED in (-*) CHANGED=255;; esac;
            case $CHANGED in (25[6-9]|2[6-9]?|[3-9]??|[1-9]???*) CHANGED=0;; esac;
    esac;

    printf '%s\n' "$P_ARRAY" |
    tr ' ' '\n' |
    grep . |
    awk -v changed="$CHANGED" -v apos="$P_APOS" '
    BEGIN{ORS=" ";}
    {if(NR-1==apos)print changed;else print $0;}';
}

bf_fix()
{
    P_ARRAY="$1";
    P_APOS="$2";

    case "$(bf_get "$P_ARRAY" "$P_APOS")" in
        ('') echo "$P_ARRAY 0";;
        (*)  echo "$P_ARRAY";;
    esac;
}

bf_d2a()
{
    awk '{ printf "%c", $0 }';
}

brainfuck()
{
    CODE="$(echo "$1" | sed 's/./& /g')";
    INSIDE_LOOP="$2";

    case "$INSIDE_LOOP" in
        ('')
            isdbg && printf '\033[2J\033[2;0f';
            ARRAY="0";
            APOS=0;;
        (*)
            ARRAY="$3";
            APOS=$4;;
    esac;

    COLLECT=0;
    COLLECTION="";

    for cmd in $CODE;
    do
        case "$COLLECT:$cmd" in (1:) COLLECTION="$COLLECTION$cmd";; esac;
        case "$cmd" in
            (\<) APOS=$(($APOS - 1));;
            (\>) APOS=$(($APOS + 1));;
            (+|-) ARRAY="$(bf_manip "$cmd" "$ARRAY" "$APOS")";;
            (,)
                C_CHAR_N=$(dd bs=1 count=1 2>/dev/null | od -A n -t d1 -v | tr -Cd 0123456789);
                case $C_CHAR_N in ('') C_CHAR_N=0;; esac;
                ARRAY="$(bf_manip "*" "$ARRAY" "$APOS" "$C_CHAR_N")";;
            (.) printf %s "$(bf_get "$ARRAY" "$APOS" | bf_d2a)";;
            (\[) COLLECT=1;;
            (\]) # special case: the LOOP, WOHOOO ;-)
                case $COLLECT in (0) continue;; esac;
                while :;
                do
                    case "$(bf_get "$ARRAY" "$APOS")" in (0) break;; esac;
                    ARRAY="$(brainfuck "$COLLECTION" l "$ARRAY" "$APOS")";
                    APOS=$?;
                done;
                COLLECTION="";
                COLLECT=0;
                ;;
            (*) continue;; # ignore other chars
        esac;

        case $APOS in (-*) APOS=0;; esac;

        isdbg &&
            printf '\033\067\033[0;0f\033[1;31mcommand '"$cmd: $ARRAY ($APOS)"'\033[0m\033\070' >&2;

        ARRAY="$(bf_fix "$ARRAY" "$APOS")";
    done;

    case "$INSIDE_LOOP" in
        ('') :;;
        (*)
            echo "$ARRAY";
            return $APOS;;
    esac;
}

# this actually is a brainfuck interpreter in shellscript (and probably
# one of the slowest bf-interpreters ever ;-)

# i didn't want to include speedups (except these gained by using bashisms
# :-/) because my intentions were that the dns server should work great, but
# is too slow to deliver anything within the timeout *g*

trap 'dd of=/dev/null 2>/dev/null' EXIT HUP INT QUIT PIPE ALRM TERM
brainfuck "$@";

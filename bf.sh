#!/usr/bin/env bash
# Copyright (c) 2006-2013 aszlig <aszlig@redmoonstudios.org
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

# sorry, but because of read -n i had to introduce a bashism :-/
DEBUG=1;

bf_get()
{
    P_ARRAY="$1";
    P_APOS="$2";

    iter=0;

    for i in $P_ARRAY;
    do
        case $iter in ($P_APOS) echo "$i";; esac;
        iter=$(($iter + 1));
    done;
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
            [ $CHANGED -lt 0 ] && CHANGED=255;
            [ $CHANGED -gt 255 ] && CHANGED=0;;
    esac;

    iter=0;

    for i in $P_ARRAY;
    do
        case $iter in ($P_APOS) printf "$CHANGED ";; (*) "$i ";; esac;
        iter=$(($iter + 1));
    done;
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
    read DECI;

    echo "$DECI" | awk '{ printf "%c", $0 }';
}

brainfuck()
{
    CODE="$(echo "$1" | sed 's/./& /g')";
    INSIDE_LOOP="$2";

    case "$INSIDE_LOOP" in
        ('')
            [ "$DEBUG" -gt 0 ] && printf '\e[2J\e[2;0f';
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
            (,) read -n 1 C_CHAR; ARRAY="$(bf_manip "*" "$ARRAY" "$APOS" "$(printf '   %d\n' "'$C_CHAR")")";;
            (.) printf "$(bf_get "$ARRAY" "$APOS" | bf_d2a)";;
            (\[) COLLECT=1;;
            (\]) # special case: the LOOP, WOHOOO ;-)
                case $COLLECT in (0) continue;; esac;
                while [ "x$(bf_get "$ARRAY" "$APOS")" != "x0" ];
                do
                    ARRAY="$(brainfuck "$COLLECTION" l "$ARRAY" "$APOS")";
                    APOS=$?;
                done;
                COLLECTION="";
                COLLECT=0;
                ;;
            *) continue;; # ignore other chars
        esac;

        [ $APOS -lt 0 ] && APOS=0;

        [ $DEBUG -gt 0 ] &&
            printf "\e7\e[0;0f\e[1;31mcommand $cmd: $ARRAY ($APOS)\e[0m\e8" >&2;

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
brainfuck "$@";

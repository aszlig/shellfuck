#!/usr/bin/env bash
# sorry, but because of read -n i had to introduce a bashism :-/
DEBUG=1;

bf_get()
{
	P_ARRAY="$1";
	P_APOS="$2";

	iter=0;

	for i in $P_ARRAY;
	do
		[ $iter -eq $P_APOS ] && echo "$i";
		iter=$(($iter + 1));
	done;
}

bf_manip()
{
	P_ACTION="$1";
	P_ARRAY="$2";
	P_APOS="$3";

	if [ "x$P_ACTION" = "x*" ];
	then
		CHANGED=$4;
	else
		CHANGED=$(($(bf_get "$P_ARRAY" "$P_APOS") $P_ACTION 1));
		[ $CHANGED -lt 0 ] && CHANGED=0;
	fi;

	iter=0;

	for i in $P_ARRAY;
	do
		[ $iter -eq $P_APOS ] && echo -n "$CHANGED " || echo -n "$i ";
		iter=$(($iter + 1));
	done;
}

bf_fix()
{
	P_ARRAY="$1";
	P_APOS="$2";

	if [ "x$(bf_get "$P_ARRAY" "$P_APOS")" != "x" ];
	then
		echo "$P_ARRAY";
	else
		echo "$P_ARRAY 0";
	fi;
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

	if [ "x$INSIDE_LOOP" = "x" ];
	then
		[ $DEBUG -gt 0 ] && echo -en "\e[2J\e[2;0f";
		ARRAY="0";
		APOS=0;
	else
		ARRAY="$3";
		APOS=$4;
	fi;

	COLLECT=0;
	COLLECTION="";

	for cmd in $CODE;
	do
		[ $COLLECT -eq 1 -a "x$cmd" != "x]" ] && COLLECTION="$COLLECTION$cmd";
		case "$cmd" in
			\<) APOS=$(($APOS - 1));;
			\>) APOS=$(($APOS + 1));;
			+|-) ARRAY="$(bf_manip "$cmd" "$ARRAY" "$APOS")";;
			,) read -n 1 C_CHAR; ARRAY="$(bf_manip "*" "$ARRAY" "$APOS" "$(echo -n "$C_CHAR" | od -An -td1)")";;
			.) echo -n "$(bf_get "$ARRAY" "$APOS" | bf_d2a)";;
			\[) COLLECT=1;;
			\]) # special case: the LOOP, WOHOOO ;-)
				[ $COLLECT -eq 0 ] && continue;
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
			echo -en "\e7\e[0;0f\e[1;31mcommand $cmd: $ARRAY ($APOS)\e[0m\e8" >&2;

		ARRAY="$(bf_fix "$ARRAY" "$APOS")";
	done;

	if [ "x$INSIDE_LOOP" != "x" ];
	then
		echo "$ARRAY";
		return $APOS;
	fi;
}

# this actually is a brainfuck interpreter in shellscript (and probably
# one of the slowest bf-interpreters ever ;-)

# i didn't want to include speedups (except these gained by using bashisms
# :-/) because my intentions were that the dns server should work great, but
# is too slow to deliver anything within the timeout *g*
#brainfuck "$@";
brainfuck "+++++++++++[>+++++++++++<-]>------.<+++[>---<-]>++.<++++[>---<-]>+.<+++++[>++++<-]>---.<++[>+<-]>.<++++[>---<-]>+.<+++[>---<-]>++.-.<+++++[>++++<-]>---.<++[>+<-]>.<++++[>----<-]>++.<+++[>--<-]>+.<+++++[>++++<-]>--.+.";

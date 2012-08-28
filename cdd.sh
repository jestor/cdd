#!/usr/bin/env bash
# This script is intended to be used as:
# alias cdd=". /<full path>/cder.sh"


level=0
dir_count=0
max_dir_count=0
current_dir=""
initial_dir=`pwd`
old_dir=$OLDPWD
seek_dir="$initial_dir/"
search_dir=0
erase=0

function partial_match {
	local tmp_dir=`pwd`
	if [ "$tmp_dir" == "/" ]; then 
		tmp_dir=""
	fi

	# Test and return a substring match, IE: /ape/moose == /ape/*
	[[ "$seek_dir" == "$tmp_dir/$1/"* ]]
}

# Builds a list of all directories in the current directory
function get_dirs {
	dirs=( )
	dir_count=0

	for f in *; do
		if [ -d "$f" ]; then
			dirs[$dir_count]="$f"
			if [ $search_dir == 1 ] && partial_match $f; then
				level=$dir_count
				search_dir=0
			fi
			((dir_count++))
		fi
	done
	
	#store the rewind marker at dir_count + 2
	max_dir_count=$(($dir_count+2))
}

# Display the input string $1
# If $erase is set, then erase strlen($1) characters
function display_str {
	if [ $erase == 0 ]; then
		echo "$1"
	else
		for ((k = 0; k < ${#1}; k++)); do
			echo -ne " "
		done
		echo
	fi
}

# Display the current directory or erase the old directory
function print_dir {
	
	if [ $1 == 1 ] ; then	
		# Rewind up max_dir_count lines
		echo -e "\033[${max_dir_count}A"
	else
		get_dirs
		current_dir=`pwd`
	fi
	
	erase=$1
	
	display_str "$current_dir"

	for ((j = 0; j < $dir_count; j++)); do
		if ((j == level)); then 
			display_str "* ${dirs[$j]}"
		else
			display_str "  ${dirs[$j]}"
		fi
	done

	if [ $1 == 1 ] ; then	
		# Rewind up max_dir_count lines
		echo -e "\033[${max_dir_count}A"
	fi
}

function move_cursor {
	local distance=$((dir_count - level))
	if [ $1 == 1 ]; then
		distance=$((distance + 1))
		if [ $distance -gt 0 ]; then echo -ne "\033[${distance}A"; fi
		echo -e " "
		echo -e "*"
	else
		if [ $distance -gt 0 ]; then echo -ne "\033[${distance}A"; fi
		echo -e "*"
		echo -e " "
	fi
	local remainder=$((distance - 2))
	if [ $remainder -gt 0 ]; then echo -ne "\033[${remainder}B"; fi
}

# Display instructions
function print_instructions {

	if [ $1 == 1 ] ; then
		echo -e "\033[11A"
	fi
	
	erase=$1
	display_str "cdd is a directory navigation tool."
	display_str "The following stdin input options are available:"
	display_str "       h - Navigate to the parent directory"
	display_str "       j - Move the directory selection down"
	display_str "       k - Move the directory selection up"
	display_str "       l - Enter the selected directory"
	display_str " ESC | q - Exit cdd without changing the current directory"
	display_str "   Enter - Exit cdd at the current directory"
	display_str ""
	display_str "Press any key to continue."
	# Set the next clear operation to clear away help

	if [ $1 == 1 ] ; then
		echo -e "\033[11A"
	fi
}

redraw=1
	
while [ 1 ]; do

	if [ $redraw == 1 ]; then
		print_dir 0
	fi
	redraw=1
	clear_dir=1

	read -r -s -n 1 C
	
	case $C in
	"h") # Left
		# we are traversing "backwards", so instruct search directory to occur
		search_dir=1
		cd ..
		level=0
		;;
	"j") # Down
		level=$((level+1))
		clear_dir=0
		redraw=0
		if [ $level -ge $dir_count ]; then
			level=$((dir_count-1))
		else
			move_cursor 1
		fi
		;;
	"k") # Up
		level=$((level-1))
		clear_dir=0
		redraw=0
		if [ $level -lt 0 ]; then
			level=0
		else
			move_cursor 0
		fi
		;;
	"l") # Right
		enter_dir="$current_dir/${dirs[$level]}"
		if [ "$current_dir" == "/" ]; then
			enter_dir="/${dirs[$level]}"
		fi
		
		# if we are traversing "forwards", ie: Entering /ape with a seek_dir of /ape/moose
		if partial_match "${dirs[$level]}"; then
			search_dir=1
			cd "$enter_dir"
		else
			cd "$enter_dir"
			# This isn't forwards, so set the new seek_dir to `pwd`/
			seek_dir="`pwd`/"
		fi
		#reset the current selection index
		level=0
		
		;;
	"q" | $'\e')
		cd "$initial_dir"
		export OLDPWD=$old_dir
		break
		;;
	"")
		export OLDPWD=$initial_dir
		break
		;;
	*) 
		print_dir 1
		print_instructions 0
		read -r -s -n 1 C
		print_instructions 1
		clear_dir=0
		;;
	esac
	
	if [ $clear_dir == 1 ]; then
		print_dir 1
	fi
	
done


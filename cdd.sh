#!/usr/bin/env bash

# This script is intended to be used thusly:
# alias cdd="/path/to/cdd.sh"

level=0
old_level=0
dir_count=0
display_count=0
current_dir=""
initial_dir=`pwd`
old_dir=$OLDPWD
seek_dir="$initial_dir/"
search_dir=0
erase=0
scroll_pos=0
if [ $LINES ] ; then
	rows=$((LINES)) # subtract one to display path
else
	rows=20
fi
cols=$((COLUMNS / 2))
dbg=""

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
			fi
			((dir_count++))
		fi
	done

	if [ $search_dir == 1 ] && [ $dir_count -gt $rows ] ; then
		scroll_pos=$((level - rows / 2))
		if [ $scroll_pos -lt 0 ]; then
			scroll_pos=0
		fi
	fi
	search_dir=0
}

# Display the input string $1
# If $erase is set, then erase the line
# If $2 is set to 1, then echo a newline
function display_str {
	local p=""
	if [ $2 ] && [ $2 == 1 ]; then
		p="-n"
	fi
	if [ $erase == 1 ]; then
		echo $p -e "\033[K"
	else
		echo $p -e "$1\033[K"
	fi
	if [ $2 ] && [ $2 == 1 ]; then
		#up one row followed by a newline (resets cursor to start)
		echo -e "\033[1A"
	fi
}

function dbg_clear {
	echo -ne "\033[s"
	echo -ne "\033[1;0H"
	echo -e "\033[K"
	echo -e "\033[K"
	echo -e "\033[K"
	echo -e "\033[K"
	echo -e "\033[K"
	echo -ne "\033[u"
}

function debug {
	echo -ne "\033[s"
	echo -ne "\033[1;0H"
	echo -e "$dbg\033[K"
	echo -ne "\033[u"
}

# Display the current directory or erase the old directory
# $1 indicates mode:
# 0 - normal paint
# 1 - erase
# 2 - cursor movement, only moves the * character
# 3 - rewind paint position to start and return immediately
# 4 - normal paint without get_dirs
function print_dir {

	if [ $1 == 2 ] && [ $level -gt 0 ]; then
		# scroll if level <= current scroll postion
		# scroll if level minus scroll pos exceeds row count
		if [ $level -le $scroll_pos ] ||
		   [ $((level - scroll_pos + 3)) -gt $rows ]; then
		    # scroll, unless we are at the bottom
		    if [ $((dir_count - level)) -gt 2 ] ; then
				scroll_pos=$((scroll_pos + (level - old_level)))
				print_dir 3
				print_dir 4
			fi
		fi
	elif [ $1 == 1 ] ; then	
		# Rewind up display_count lines
		echo -ne "\033[${display_count}A"
	elif [ $1 == 3 ] ; then 
		echo -ne "\033[${display_count}A"
		return
	elif [ $1 == 0 ] ; then
		get_dirs
		current_dir=`pwd`
	fi

	#limit displayed rows if there are more directories than rows
	local dir_display_min=scroll_pos
	local dir_display_max=dir_count
	local display_more=0 # used to render "more" ellipsis
	local display_less=0 # used to render "less" ellipsis
	if [ $((dir_count+1)) -gt $rows ] ; then
		dir_display_max=$((rows + scroll_pos))

		if [ $scroll_pos -gt 0 ]; then 
			display_less=1
			((dir_display_min++))
		fi
		if [ $dir_display_max -lt $dir_count ]; then
			display_more=1
			dir_display_max=$((dir_display_max - 1))
		fi
	fi

	if [ $1 -lt 2 ] || [ $1 == 4 ]; then
		erase=$1
		# Display the current path
		display_str "$current_dir"
		display_count=1
		
		if [ $display_less == 1 ]; then
			display_str "  ..."
			((display_count++))
		fi
		
		for ((j = $dir_display_min; j < $dir_display_max; j++)); do
			if [ $((dir_display_max - j)) -gt 1 ] ; then
				display_str "  ${dirs[$j]}"
				((display_count++))
			else
				display_str "  ${dirs[$j]}" 1
			fi
		done
		
		if [ $display_more == 1 ]; then
			display_str "  ..." 1
		fi
	fi

	
	# Seek and draw the selection - as this function is called after moving we 
	# should also clear above and below the selection.
	local tmp_level=$((level - scroll_pos))
	local distance=$((display_count - tmp_level))
	local remainder=$((distance - 2))
	if [ $1 == 2 ] || [ $1 == 0 ] || [ $1 == 4 ]; then
		if [ $distance -gt 0 ]; then echo -ne "\033[${distance}A"; fi
		if [ $tmp_level == 0 ] ; then
			echo
		else
			echo -e " "
		fi
		echo -ne "*\033[1D"
		if [ $remainder -ge 0 ]; then
			# erase the first character, then move the cursor left
			echo -ne "\033[1B \033[1D"
		fi
		if [ $remainder -gt 0 ]; then echo -ne "\033[${remainder}B"; fi
	fi

	if [ $1 == 1 ] ; then	
		# Rewind up display_count lines
		echo -ne "\033[${display_count}A"
	fi
	
	#dbg_clear
	#debug
	old_level=$level
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
		builtin cd ..
		level=0
		scroll_pos=0
		;;

	"j") # Down
		level=$((level+1))
		clear_dir=0
		redraw=0
		if [ $level -ge $dir_count ]; then
			level=$((dir_count-1))
		else
			print_dir 2
		fi
		;;

	"k") # Up
		level=$((level-1))
		dbg="$dbg\nHitting down: $level"
		clear_dir=0
		redraw=0
		if [ $level -lt 0 ]; then
			level=0
		else
			print_dir 2
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
			builtin cd "$enter_dir"
		else
			builtin cd "$enter_dir"
			# This isn't forwards, so set the new seek_dir to `pwd`/
			seek_dir="`pwd`/"
		fi
		#reset the current selection index
		level=0
		scroll_pos=0
		;;

	"q" | $'\e')
		builtin cd "$initial_dir"
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


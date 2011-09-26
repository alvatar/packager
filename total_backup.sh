#!/bin/bash

#	-------------------------------------------------------------------
#
#	Shell program to make a backup from a list of directories into
# another one
#
#	Copyright 2011,  alvatarc
#
#	This program is free software; you can redistribute it and/or
#	modify it under the terms of the GNU General Public License as
#	published by the Free Software Foundation; either version 2 of the
#	License, or (at your option) any later version. 
#
#	This program is distributed in the hope that it will be useful, but
#	WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#	General Public License for more details.
#
#	Description:
#
#
#
#	Usage:
#
#		total_backup [ -h | --help ]
#
#	Options:
#
#		-h, --help	Display this help message and exit.
#
#
#	Revision History:
#
#	09/18/2011	File created by new_script ver. 2.1.0
#
#	-------------------------------------------------------------------


#	-------------------------------------------------------------------
#	Constants
#	-------------------------------------------------------------------

	PROGNAME=$(basename $0)
	VERSION="0.0.1"



#	-------------------------------------------------------------------
#	Functions
#	-------------------------------------------------------------------


function clean_up
{

#	-----------------------------------------------------------------------
#	Function to remove temporary files and other housekeeping
#		No arguments
#	-----------------------------------------------------------------------

	rm -f ${TEMP_FILE1}
}


function error_exit
{

#	-----------------------------------------------------------------------
#	Function for exit due to fatal program error
#		Accepts 1 argument:
#			string containing descriptive error message
#	-----------------------------------------------------------------------


	echo "${PROGNAME}: ${1:-"Unknown Error"}" >&2
	clean_up
	exit 1
}


function graceful_exit
{

#	-----------------------------------------------------------------------
#	Function called for a graceful exit
#		No arguments
#	-----------------------------------------------------------------------

	clean_up
	exit
}


function signal_exit
{

#	-----------------------------------------------------------------------
#	Function to handle termination signals
#		Accepts 1 argument:
#			signal_spec
#	-----------------------------------------------------------------------

	case $1 in
		INT)	echo "$PROGNAME: Program aborted by user" >&2
			clean_up
			exit
			;;
		TERM)	echo "$PROGNAME: Program terminated" >&2
			clean_up
			exit
			;;
		*)	error_exit "$PROGNAME: Terminating on unknown signal"
			;;
	esac
}


function make_temp_files
{

#	-----------------------------------------------------------------------
#	Function to create temporary files
#		No arguments
#	-----------------------------------------------------------------------

	# Use user's local tmp directory if it exists

	if [ -d ~/tmp ]; then
		TEMP_DIR=~/tmp
	else
		TEMP_DIR=/tmp
	fi

	# Temp file for this script, using paranoid method of creation to
	# insure that file name is not predictable.  This is for security to
	# avoid "tmp race" attacks.  If more files are needed, create using
	# the same form.

	TEMP_FILE1=$(mktemp -q "${TEMP_DIR}/${PROGNAME}.$$.XXXXXX")
	if [ "$TEMP_FILE1" = "" ]; then
		error_exit "cannot create temp file!"
	fi
}


function usage
{

#	-----------------------------------------------------------------------
#	Function to display usage message (does not exit)
#		No arguments
#	-----------------------------------------------------------------------

	echo "Usage: ${PROGNAME} [-h | --help] -c [conf_file] -d [output_directory]"
}


function helptext
{

#	-----------------------------------------------------------------------
#	Function to display help message for program
#		No arguments
#	-----------------------------------------------------------------------

	local tab=$(echo -en "\t\t")

	cat <<- -EOF-

	${PROGNAME} ver. ${VERSION}
	This is a program to (describe purpose of script).

	$(usage)

	Options:

	-h, --help	Display this help message and exit.


	
	
-EOF-
}

#	-----------------------------------------------------------------------
#	Function to set the config file
#		$1: config file
#	-----------------------------------------------------------------------

function set_config_file
{
  CONFIG_FILE=$1
}

#	-----------------------------------------------------------------------
#	Function to set the output directory
#		$1: config file
#	-----------------------------------------------------------------------

function set_target_directory
{
  TARGET_DIRECTORY=$1
  OUT_FILENAME=$TARGET_DIRECTORY"total_backup_"`(date +%g_%m_%d)`".tar.bz2.enc"
  echo "Backup will be written to $TARGET_DIRECTORY"
}

#	-----------------------------------------------------------------------
#	Function to check the size of directories
#		No arguments
#	-----------------------------------------------------------------------

function check_size
{
  if [ -z "$CONFIG_FILE" ]
  then
    usage
    graceful_exit
  else
    du -csh `cat $CONFIG_FILE`
  fi
}

#	-----------------------------------------------------------------------
#	Function to do the backup
#		No arguments
#	-----------------------------------------------------------------------

function do_backup
{
  echo -en "\n\033[0;34mIntroduce password for data encryption...\033[0m\n> "
  read ENC_PASS
  echo -en "\n"

  tar cjf - `cat $CONFIG_FILE` | openssl aes-256-cbc -salt -pass pass:"$ENC_PASS" >> $OUT_FILENAME
}

#	-------------------------------------------------------------------
#	Program starts here
#	-------------------------------------------------------------------

##### Initialization And Setup #####

# Set file creation mask so that all files are created with 600 permissions.

umask 066


# Trap TERM, HUP, and INT signals and properly exit

trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

# Create temporary file(s)

make_temp_files


##### Set global variables #####

OUT_FILENAME="./total_backup_"`(date +%g_%m_%d)`".tar.bz2.enc"

##### Command Line Processing #####

if [ "$1" = "--help" ]; then
	helptext
	graceful_exit
fi

while getopts "h c: d:" opt; do
	case $opt in

		h )	helptext
			graceful_exit ;;
    c ) set_config_file $OPTARG ;;
    d ) set_target_directory $OPTARG ;;
		* )	usage
			clean_up
			exit 1
	esac
done

##### Main Logic #####

check_size

while true
do
    read -r -p 'Do you want to continue? ' choice
    case $choice in
      n|N) break ;;
      y|Y) do_backup
        break ;;
    esac
done

graceful_exit


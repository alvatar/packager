#!/bin/sh

#       _
#      ( )
#       H
#       H
#      _H_
#   .-'-.-'-.
#  /         \ 
# |           |
# |   .-------'._
# |  / /  '.' '. \ 
# |  \ \ @   @ / /
# |   '---------'
# |    _______|
# |  .'-+-+-+|
# |  '.-+-+-+|
# |     |
# '-.__   __.-'
#      """ 
# Author: Alvaro Castro-Castilla
#
# URL: http://castrocastilla.com
# Date: 20090809
# License: MIT/X11
#
# Description: Bash script generating a self-executable script containing encrypted user
# configuration files, system configuration files and an arbitrary directory of files
# here called "essentials".
#
# TODO: Handle signals!!
# TODO: Arguments


# Variables for files extraction
#

#USER_CONF_DIRS_AND_FILES=`cat user_conf`

#SYSTEM_CONF_FILES=`cat system_conf`

declare -x ESSENTIALS_DIR_SRC="/data/essentials"

declare -rx FTP_PROGRAM="lftp"
declare -rx FTP_PROGRAM_ARGS="castrocastilla"


# Initial checks
#

shopt -s -o nounset

if [[ ! `which $FTP_PROGRAM` ]]; then echo -e "\n\033[0;31mERROR: $FTP_PROGRAM not found! Proceed to install it.\033[0m\n"; exit 192; fi

declare -rx OUT_FILE_DIR=`pwd`

#declare -x AM_I_ROOT=false
#if [ `id -u` != "0" ]; then
#    echo -e "\n\033[0;31mYou must be root to embed System Configuration Files!\033[0m\n" >&2
#else
#    AM_I_ROOT=true
#fi

IFS=$'\n'

ESSENTIALS_FILES_SRC=`(find -P $ESSENTIALS_DIR_SRC -printf '%p\n' )`


# Grab information
#

if [[ "$?" -ne "0" ]]; then echo -e "\n\033[0;31mERROR: File(s) Not Found.\033[0m\n"; exit 192; fi

echo -ne "\nPlease, write the output file name: [injection.sh]\n> "
read OUT_FILE
if [[ $OUT_FILE == "" ]]; then OUT_FILE="injection.sh"; fi
if [[ -f $OUT_FILE ]]; then
    echo -ne "File exists. Delete? y/[N]: "
    read ANS
    case $ANS in
	y)
        rm -f $OUT_FILE
        ;;
	*)
        exit
        ;;
    esac
fi

declare -x DO_USER_CONF=false
#echo -ne "\nDo you want to embed User Configuration? [Y]/n: "
#read ASK_USER_CONF
#case $ASK_USER_CONF in
#    n)
#    ;;
#    *)
#    DO_USER_CONF=true
#    echo -ne "\nPlease, set user to extract configuration files. Press [Enter] for current:\n> "
#    read USER_ID_ORIGIN
#    if [[ -z "$USER_ID_ORIGIN" ]]; then USER_ID_ORIGIN=$USER; fi
#
#    echo -ne 'Configuration files for: '"$USER_ID_ORIGIN"'\n'
#    declare -x USER_HOME=""
#    declare -x USER_CONF_FILES=""
#
#    if [[ "$USER_ID_ORIGIN" == "root" ]]; then
#	USER_HOME="/root"
#    else
#	USER_HOME="/home/$USER_ID_ORIGIN"
#    fi
#
#    for i in $USER_CONF_DIRS_AND_FILES; do
#	USER_CONF_FILES+=`find -P $USER_HOME/$i -printf '%p\n'`$'\n'
#    done
#    ;;
#esac

declare -x DO_SYSTEM_CONF=false
#if $AM_I_ROOT; then
#    echo -en "\nDo you want to embed System Configuration? [Y]/n: "
#    read ASK_SYSTEM_CONF
#    case $ASK_SYSTEM_CONF in
#	n)
#	;;
#	*)
#	DO_SYSTEM_CONF=true
#	;;
#    esac
#fi

declare -x DO_ESSENTIALS=true
#echo -en "\nDo you want to embed Essentials? [Y]/n: "
#read ASK_ESSENTIALS
#case $ASK_ESSENTIALS in
#    n)
#    ;;
#    *)
#    DO_ESSENTIALS=true
#    ;;
#esac

declare -x FTP_UPLOAD=true
declare -x REMOVE_FILES=false
echo -en "\nDo you want to upload to the FTP? [Y]/[n]: "
read ASK_FTP_UPLOAD
case $ASK_FTP_UPLOAD in
    n)
        FTP_UPLOAD=false ;;
    *)
        echo -en "\nDo you want to clean up generated files after uploading: [Y]/[n]"
        read ASK_REMOVE_FILES
        case $ASK_REMOVE_FILES in
            n)
                REMOVE_FILES=false
                ;;
            *)
                REMOVE_FILES=true
                ;;
        esac ;;
esac

echo -en "\n\033[0;34mIntroduce password for data encryption...\033[0m\n> "
read ENC_PASS
echo -en "\n"


# Generation of variables and user interaction
#

echo -e "#!/bin/sh\n" >> $OUT_FILE

echo -e "declare -rx SCRIPT=\${0##*/}\n" >> $OUT_FILE

echo -e "if [[ ! \`which openssl\` ]]; then echo -e \"\\\n\\\033[0;31mError: OpenSSL not found. Please install it and run again\\\033[0m\\\n\" >&2; exit 192; fi" >> $OUT_FILE

echo "echo -e \"      _\n     ( )\n      H\n      H\n     _H_\n  .-'-.-'-.\n /         \ \n|           |\n|   .-------'._\n|  / /  '.' '. \ \n|  \ \ @   @ / /\n|   '---------'\n|    _______|\n|  .'-+-+-+|\n|  '.-+-+-+|\n|    \"\"\"\"\"\" |\n'-.__   __.-'\n     \\\"\\\"\\\" \n\nTHE DEVIL PROTECTS THIS DATA\n\"" >> $OUT_FILE

echo -e "\necho -en \"\\\nChecking file integrity... \"" >> $OUT_FILE
echo -e "md5sum -c \"$OUT_FILE.md5sum\"\nif [[ \$? -ne 0 ]]; then echo -e \"\\\n\\\033[0;31mThere was an error checking the file's hash!\\\033[0m\\\n\" >&2; exit 192; fi\n" >> $OUT_FILE

echo -e "declare -x AM_I_ROOT=false\nif [ \`id -u\` != \"0\" ]; then\n    echo -e \"\\\n\\\033[0;31mYou must be root to overwrite System Configuration Files!\\\033[0m\\\n\" >&2;\nelse AM_I_ROOT=true;\nfi\n" >> $OUT_FILE

if $DO_USER_CONF; then
    echo -e "declare -x USER_INJECTION_DIR" >> $OUT_FILE
    echo -e "echo -ne \"\\\n\\\033[0;32mDo you want to inject USER configuration files in a [N]eutral directory or [o]verwrite current user's configuration files?\\\033[0m\\\n> \"; read DO_OVER;\ncase \$DO_USER_OVER in\no)\n    DO_USER_OVER=\"true\"\n    ;;\n*)\n    DO_OVER=\"\"\n    ;;\nesac" >> $OUT_FILE
    echo -e "if [ ! \$DO_USER_OVER ]; then echo -ne \"\\\033[0;32m...set the neutral directory (default: [.])\\\033[0m\\\n> \"; read USER_NEUTRAL_DIR; if [[ -n \"\$USER_NEUTRAL_DIR\" ]]; then USER_INJECTION_DIR=\$USER_NEUTRAL_DIR; else USER_INJECTION_DIR=\".\" ; fi; else if \$AM_I_ROOT; then USER_INJECTION_DIR=/root; else USER_INJECTION_DIR=/home/\$USER; fi; fi" >> $OUT_FILE
fi

if $DO_SYSTEM_CONF; then
    echo -e "declare -x SYSTEM_INJECTION_DIR" >> $OUT_FILE
    echo -e "echo -ne \"\\\n\\\033[0;32mDo you want to inject SYSTEM configuration files in a [N]eutral directory or [o]verwrite System's configuration files?\\\033[0m\\\n> \"; read DO_SYSTEM_OVER;\ncase \$DO_SYSTEM_OVER in\no)\n    DO_SYSTEM_OVER=\"true\"\n    ;;\n*)\n    DO_OVER=\"\"\n    ;;\nesac\n" >> $OUT_FILE
    echo -e "if [ ! \$DO_SYSTEM_OVER ]; then echo -ne \"\\\033[0;32m...set the neutral directory (default: [.])\\\033[0m\\\n> \"; read SYSTEM_NEUTRAL_DIR; if [[ -n \"\$SYSTEM_NEUTRAL_DIR\" ]]; then SYSTEM_INJECTION_DIR=\$SYSTEM_NEUTRAL_DIR; else SYSTEM_INJECTION_DIR=\".\"; fi; else SYSTEM_INJECTION_DIR=/; fi\n" >> $OUT_FILE
fi

if $DO_ESSENTIALS; then
    echo -e "declare -x ESSENTIALS_INJECTION_DIR" >> $OUT_FILE
    echo -e "echo -ne \"\\\n\\\033[0;32m...set the directory for placing ESSENTIALS (default: [.])\\\033[0m\\\n> \"; read ESSENTIALS_NEUTRAL_DIR; if [[ -n \"\$ESSENTIALS_NEUTRAL_DIR\" ]]; then ESSENTIALS_INJECTION_DIR=\$ESSENTIALS_NEUTRAL_DIR; else ESSENTIALS_INJECTION_DIR=\".\"; fi" >> $OUT_FILE
fi

echo -e "echo -ne \"\\\n\\\033[0;32mIntroduce password for data desencryption...\\\033[0m\\\n> \"; read DESENC_PASS; echo -ne \"\\\n\"\n" >> $OUT_FILE



# Generate pack
#

# Trap for abnormal termination
trap 'if [[ "$?" -ne "0" ]]; then if [[ -f "$OUT_FILE_DIR/$OUT_FILE" ]]; then rm "$OUT_FILE_DIR/$OUT_FILE"; fi; if [[ -f "$OUT_FILE_DIR/$OUT_FILE.md5sum" ]]; then rm "$OUT_FILE_DIR/$OUT_FILE.md5sum"; fi; fi' EXIT

# 1) inject user configuration files (tar archive)
if $DO_USER_CONF && [[ -n $USER_CONF_DIRS_AND_FILES ]]
then
    echo -e '\n######################## USER_CONF_DIRS_AND_FILES #########################' >> $OUT_FILE

    for i in $USER_CONF_FILES; do
	echo -e "\033[0;32m...processing user configuration file -> $i"
    done

    echo -e "openssl des3 -d -a -salt -pass pass:\"\$DESENC_PASS\" <<'################ END_OF_USER_CONF_DIRS_AND_FILES ################' | tar xjf - -C \$USER_INJECTION_DIR" >> $OUT_FILE
    cd $USER_HOME
    tar -cjf - $USER_CONF_DIRS_AND_FILES | openssl des3 -a -salt -pass pass:"$ENC_PASS">> $OUT_FILE_DIR/$OUT_FILE
    cd $OUT_FILE_DIR
    echo -e "################ END_OF_USER_CONF_DIRS_AND_FILES ################\n" >> $OUT_FILE
fi


# 2) inject system configuration files (concatenated files)
if $DO_SYSTEM_CONF && [[ -n $SYSTEM_CONF_FILES ]]
then
    echo -e '\n############################ SYSTEM_CONF_FILES ############################' >> $OUT_FILE
    echo -e ""
    
    for i in $SYSTEM_CONF_FILES; do
        if [ -f "$i" ]
        then
            echo -e "\033[0;32m...processing system configuration file -> $i"
            
            echo -e "FILE_TO_WRITE=\"$i\"" >> $OUT_FILE
            echo -e "if [ ! \$DO_SYSTEM_OVER ]; then FILENAME=\`basename \"\$FILE_TO_WRITE\"\`; FILE_TO_WRITE=\"\$SYSTEM_INJECTION_DIR\"/\"\$FILENAME\"; fi" >> $OUT_FILE
            echo -e "openssl des3 -d -a -salt -pass pass:\"\$DESENC_PASS\">\$FILE_TO_WRITE <<'################ END_OF_$i ################'" >> $OUT_FILE
            cat $i | openssl des3 -a -salt -pass pass:"$ENC_PASS" >> $OUT_FILE
            echo -e "################ END_OF_$i ################" >> $OUT_FILE
        else
            echo "The system configuration file does not exist! Aborting..." 1>&2
            echo -e "$i"
            exit 1;
        fi
    done

    echo -e "################ END_OF_SYSTEM_CONF_FILES ################" >> $OUT_FILE
    echo -e "\n" >> $OUT_FILE
fi


# 3) inject essentials (compressed bz2 tar archive)
if $DO_ESSENTIALS; then
    echo -e '\n############################### ESSENTIALS ###############################' >> $OUT_FILE
    
    echo -e "mkdir -p \$ESSENTIALS_INJECTION_DIR/essentials " >> $OUT_FILE
    echo -e "openssl des3 -d -a -salt -pass pass:\"\$DESENC_PASS\" <<'################ END_OF_ESSENTIALS ################' | tar xjf - -C \$ESSENTIALS_INJECTION_DIR " >> $OUT_FILE

    echo -e "\n\033[0;32m...embedding essentials\033[0m"
    cd `dirname $ESSENTIALS_DIR_SRC`; tar cjf - `basename $ESSENTIALS_DIR_SRC` | openssl des3 -a -salt -pass pass:"$ENC_PASS" >> "$OUT_FILE_DIR/$OUT_FILE"
    echo -e "\033[0;32m...done\033[0m\n"
    cd - > /dev/null

    echo -e "################ END_OF_ESSENTIALS ################" >> $OUT_FILE
fi

echo -e "echo -e \"\\\033[0;34m...finished!\\\033[0;0m\\\n\"" >> $OUT_FILE
echo -e "exit 0" >> $OUT_FILE

echo -e "\033[0;32m...creating checksum\033[0;0m\n"
md5sum $OUT_FILE > $OUT_FILE.md5sum
chmod +x $OUT_FILE

echo -e "\033[0;32m...the files weight:\033[0;0m"
du -sh $OUT_FILE $OUT_FILE.md5sum
echo ""

# FTP upload
#

if $FTP_UPLOAD; then
    echo -e "\033[0;32m...uploading to FTP\033[0;0m\n"
    $FTP_PROGRAM "$FTP_PROGRAM_ARGS"<<EOT
cd www
cd files
put $OUT_FILE
put $OUT_FILE.md5sum
quit
EOT
fi

# File cleanup
#

if $REMOVE_FILES; then
    if [ -e $OUT_FILE ]; then rm $OUT_FILE; fi
    if [ -e $OUT_FILE.md5sum ]; then rm $OUT_FILE.md5sum; fi
fi

# Finalizing
#

echo -e "\033[0;34m...finished!\033[0;0m\n"

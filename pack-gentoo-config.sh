#!/bin/sh


IN_USER_FILES="
.Xmodmaprc
.Xdefaults
.bashrc
.bash_profile
.bin
.blackhole/pkglist
.config/uzbl
.emacs
.emacs.d
.gambcini
.gtkrc-2.0
.irssi
.lftp
.lftprc
.moc/config
.prompt
.prompt_config
.prompt_functions
.rtorrent.rc
.themes
.vim
.vimrc
.xbindkeysrc
.xinitrc
.xmonad/xmonad.hs
"
IN_SYSTEM_FILES="
/boot/grub/grub.conf
/etc/fstab
/etc/hosts
/etc/locale.gen
/etc/make.conf
/etc/rc.conf
/etc/X11/xorg.conf
/etc/bitlbee/bitlbee.conf
/etc/conf.d/consolefont
/etc/conf.d/hwclock
/etc/conf.d/keymaps
/etc/conf.d/net
/etc/conf.d/wpa_supplicant
/etc/portage/package.keywords
/etc/portage/package.use
/root/.ecryptfsrc
/usr/src/linux/.config
/var/lib/bitlbee/alvatar.xml
/usr/share/fonts/external/
"

OLD_PATH=`pwd`
cd /home/alvatar

declare -x AM_I_ROOT=false
if [ `id -u` != "0" ]; then
	echo -e "\nError: You must be root to make a backup of certain files\n" >&2
	exit 192
else
    AM_I_ROOT=true
fi

if [ -d "user_files_tmp" ]; then
    echo -e "\nError: the directory user_files_tmp already existsi\n" >&2
    exit 192
fi

mkdir user_files_tmp
cp --parents -R $IN_USER_FILES user_files_tmp

IN_FILES="
user_files_tmp
$IN_SYSTEM_FILES
"

OUT_FILENAME="gentoo_system_config_"`(date +%g_%m_%d)`".tar.bz2"

tar cjf $OUT_FILENAME $IN_FILES

if [ -d "user_files_tmp" ]; then
    rm -R user_files_tmp
fi

mv $OUT_FILENAME $OLD_PATH

#!/bin/bash -e

time=$(date +%Y-%m-%d)
mirror_dir="/var/www/html/rcn-ee.us/rootfs/bb.org/testing"
DIR="$PWD"

git pull --no-edit https://github.com/beagleboard/image-builder master

export apt_proxy=apt-proxy:3142/

if [ -d ./deploy ] ; then
	sudo rm -rf ./deploy || true
fi

if [ ! -f jenkins.build ] ; then
./RootStock-NG.sh -c machinekit-debian-wheezy
./RootStock-NG.sh -c machinekit-debian-jessie
#./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-2gb-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-4gb-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-lxqt-4gb-xm
./RootStock-NG.sh -c bb.org-debian-jessie-iot-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-console-v4.4
./RootStock-NG.sh -c seeed-debian-jessie-lxqt-4gb-v4.4
./RootStock-NG.sh -c seeed-debian-jessie-iot-v4.4
./RootStock-NG.sh -c bb.org-debian-jessie-oemflasher
./RootStock-NG.sh -c bb.org-debian-stretch-iot-v4.9
./RootStock-NG.sh -c bb.org-debian-stretch-wayland-v4.4
else
	mkdir -p ${DIR}/deploy/ || true
fi

    debian_wheezy_machinekit="debian-7.11-machinekit-armhf-${time}"
    debian_jessie_machinekit="debian-8.6-machinekit-armhf-${time}"
      debian_jessie_lxqt_2gb="debian-8.6-lxqt-2gb-armhf-${time}"
      debian_jessie_lxqt_4gb="debian-8.6-lxqt-4gb-armhf-${time}"
   debian_jessie_lxqt_xm_4gb="debian-8.6-lxqt-xm-4gb-armhf-${time}"
           debian_jessie_iot="debian-8.6-iot-armhf-${time}"
       debian_jessie_console="debian-8.6-console-armhf-${time}"
debian_jessie_seeed_lxqt_4gb="debian-8.6-seeed-lxqt-4gb-armhf-${time}"
     debian_jessie_seeed_iot="debian-8.6-seeed-iot-armhf-${time}"
    debian_jessie_oemflasher="debian-8.6-oemflasher-armhf-${time}"
          debian_stretch_iot="debian-stretch-iot-armhf-${time}"
      debian_stretch_wayland="debian-stretch-wayland-armhf-${time}"

archive="xz -z -8"

beaglebone="--dtb beaglebone --bbb-old-bootloader-in-emmc \
--rootfs_label rootfs --hostname beaglebone --enable-cape-universal"

bbbw="--dtb osd335x-blank-eeprom \
--rootfs_label rootfs --hostname beaglebone --enable-cape-universal"

arduino_tre="--dtb am335x-arduino-tre --boot_label ARDUINO-TRE \
--rootfs_label rootfs --hostname arduino-tre"

beagle_xm="--dtb omap3-beagle-xm --rootfs_label rootfs --hostname beagleboard"

omap5_uevm="--dtb omap5-uevm --rootfs_label rootfs --hostname omap5-uevm"
beagle_x15="--dtb am57xx-beagle-x15 --rootfs_label rootfs \
--hostname BeagleBoard-X15"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

copy_base_rootfs_to_mirror () {
        if [ -d ${mirror_dir}/ ] ; then
                if [ ! -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${base_rootfs}.tar.xz ] ; then
                                cp -v \${base_rootfs}.tar ${mirror_dir}/${time}/\${blend}/
                                cd ${mirror_dir}/${time}/\${blend}/
                                ${archive} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.xz > \${base_rootfs}.tar.xz.sha256sum &
                                cd -
                        fi
                fi
        fi
}

archive_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi
        if [ -f \${base_rootfs}.tar ] ; then
                copy_base_rootfs_to_mirror
        fi
}

extract_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi

        if [ -f \${base_rootfs}.tar.xz ] ; then
                tar xf \${base_rootfs}.tar.xz
        fi

        if [ -f \${base_rootfs}.tar ] ; then
                tar xf \${base_rootfs}.tar
        fi
}

copy_img_to_mirror () {
        if [ -d ${mirror_dir} ] ; then
                if [ ! -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        mkdir -p ${mirror_dir}/${time}/\${blend}/ || true
                fi
                if [ -d ${mirror_dir}/${time}/\${blend}/ ] ; then
                        if [ -f \${wfile}.bmap ] ; then
                                mv -v \${wfile}.bmap ${mirror_dir}/${time}/\${blend}/
                                sync
                        fi
                        if [ ! -f ${mirror_dir}/${time}/\${blend}/\${wfile}.img.zx ] ; then
                                mv -v \${wfile}.img ${mirror_dir}/${time}/\${blend}/
                                sync
                                if [ -f \${wfile}.img.xz.job.txt ] ; then
                                        mv -v \${wfile}.img.xz.job.txt ${mirror_dir}/${time}/\${blend}/
                                        sync
                                fi
                                cd ${mirror_dir}/${time}/\${blend}/
                                ${archive} \${wfile}.img && sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum &
                                cd -
                        fi
                fi
        fi
}

archive_img () {
        if [ -f \${wfile}.img ] ; then
                if [ ! -f \${wfile}.bmap ] ; then
                        if [ -f /usr/bin/bmaptool ] ; then
                                bmaptool create -o \${wfile}.bmap \${wfile}.img
                        fi
                fi
                copy_img_to_mirror
        fi
}

generate_img () {
        if [ -d \${base_rootfs}/ ] ; then
                cd \${base_rootfs}/
                sudo ./setup_sdcard.sh \${options}
                sudo chown 1000:1000 *.img || true
                sudo chown 1000:1000 *.job.txt || true
                mv *.img ../ || true
                mv *.job.txt ../ || true
                cd ..
        fi
}

###machinekit (wheezy):
base_rootfs="${debian_wheezy_machinekit}" ; blend="machinekit" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs} ${beaglebone} --enable-systemd" ; generate_img

###machinekit (jessie)
base_rootfs="${debian_jessie_machinekit}" ; blend="machinekit" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs} ${beaglebone}" ; generate_img

###lxqt-4gb image
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}        ${beaglebone}"                 ; generate_img
options="--img-4gb BBB-blank-\${base_rootfs}   ${beaglebone}  --emmc-flasher" ; generate_img
options="--img-4gb BBBW-blank-\${base_rootfs}  ${beaglebone}  --bbbw-flasher" ; generate_img
options="--img-4gb m10a-blank-\${base_rootfs}  ${beaglebone}  --m10a-flasher" ; generate_img
options="--img-4gb bbx15-\${base_rootfs}       ${beagle_x15}"                 ; generate_img
options="--img-4gb bbx15-blank-\${base_rootfs} ${beagle_x15}  --emmc-flasher" ; generate_img

#options="--img-4gb omap5-uevm-\${base_rootfs}  ${omap5_uevm}"                 ; generate_img
#options="--img-4gb tre-\${base_rootfs}         ${arduino_tre}"                ; generate_img

###lxqt-2gb image
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb" ; extract_base_rootfs

options="--img-2gb bone-\${base_rootfs}  ${beaglebone}" ; generate_img

#options="--img-2gb BBB-blank-\${base_rootfs} ${beaglebone} --emmc-flasher" ; generate_img

###lxqt-xm-4gb image
base_rootfs="${debian_jessie_lxqt_xm_4gb}" ; blend="lxqt-xm-4gb" ; extract_base_rootfs

options="--img-4gb bbxm-\${base_rootfs}  ${beagle_xm}" ; generate_img

###iot image
base_rootfs="${debian_jessie_iot}" ; blend="iot" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}       ${beaglebone}"                  ; generate_img
options="--img-4gb BBB-blank-\${base_rootfs}  ${beaglebone}   --emmc-flasher" ; generate_img
options="--img-4gb BBBL-blank-\${base_rootfs}  ${beaglebone}  --bbbl-flasher" ; generate_img
#options="--img-4gb BBBW-blank-\${base_rootfs}  ${beaglebone}   --bbbw-flasher" ; generate_img

###console images
base_rootfs="${debian_jessie_console}" ; blend="console" ; extract_base_rootfs

options="--img-2gb a335-eeprom-\${base_rootfs} ${beaglebone}  --a335-flasher" ; generate_img
options="--img-2gb bone-\${base_rootfs}        ${beaglebone}"                 ; generate_img
options="--img-2gb bbx15-\${base_rootfs}       ${beagle_x15}"                 ; generate_img
options="--img-2gb BBB-blank-\${base_rootfs}   ${beaglebone}  --emmc-flasher" ; generate_img

#options="--img-2gb bbx15-blank-\${base_rootfs} ${beagle_x15}  --emmc-flasher" ; generate_img

#options="--img-2gb omap5-uevm-\${base_rootfs}  ${omap5_uevm}"                  ; generate_img
#options="--img-2gb BBGW-blank-\${base_rootfs}  ${beaglebone}  --bbgw-flasher"  ; generate_img

###Seeed lxqt-4gb image
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}      ${beaglebone}"                ; generate_img
options="--img-4gb BBG-blank-\${base_rootfs} ${beaglebone}  --bbg-flasher" ; generate_img

###Seeed iot image
base_rootfs="${debian_jessie_seeed_iot}" ; blend="seeed-iot" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}       ${beaglebone}"                ; generate_img
options="--img-4gb BBGW-blank-\${base_rootfs} ${beaglebone} --bbgw-flasher" ; generate_img

###stretch iot image
base_rootfs="${debian_stretch_iot}" ; blend="stretch-iot" ; extract_base_rootfs

options="--img-4gb bone-\${base_rootfs}       ${beaglebone}"                 ; generate_img

###stretch wayland image
base_rootfs="${debian_stretch_wayland}" ; blend="stretch-wayland" ; extract_base_rootfs

options="--img-4gb bbx15-\${base_rootfs}      ${beagle_x15}"                 ; generate_img

###archive *.tar
base_rootfs="${debian_wheezy_machinekit}"     ; blend="machinekit"      ; archive_base_rootfs
base_rootfs="${debian_jessie_machinekit}"     ; blend="machinekit"      ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_4gb}"       ; blend="lxqt-4gb"        ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_2gb}"       ; blend="lxqt-2gb"        ; archive_base_rootfs
base_rootfs="${debian_jessie_lxqt_xm_4gb}"    ; blend="lxqt-xm-4gb"     ; archive_base_rootfs
base_rootfs="${debian_jessie_iot}"            ; blend="iot"             ; archive_base_rootfs
base_rootfs="${debian_jessie_console}"        ; blend="console"         ; archive_base_rootfs
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb"  ; archive_base_rootfs
base_rootfs="${debian_jessie_seeed_iot}"      ; blend="seeed-iot"       ; archive_base_rootfs
base_rootfs="${debian_jessie_oemflasher}"     ; blend="oemflasher"      ; archive_base_rootfs
base_rootfs="${debian_stretch_iot}"           ; blend="stretch-iot"     ; archive_base_rootfs
base_rootfs="${debian_stretch_wayland}"       ; blend="stretch-wayland" ; archive_base_rootfs

###archive *.img
base_rootfs="${debian_wheezy_machinekit}" ; blend="machinekit"

wfile="bone-\${base_rootfs}-4gb" ; archive_img

base_rootfs="${debian_jessie_machinekit}" ; blend="machinekit"

wfile="bone-\${base_rootfs}-4gb" ; archive_img

#
base_rootfs="${debian_jessie_lxqt_4gb}" ; blend="lxqt-4gb"

wfile="bone-\${base_rootfs}-4gb"        ; archive_img
wfile="m10a-blank-\${base_rootfs}-4gb"  ; archive_img
wfile="BBB-blank-\${base_rootfs}-4gb"   ; archive_img
wfile="BBBW-blank-\${base_rootfs}-4gb"  ; archive_img
wfile="bbx15-\${base_rootfs}-4gb"       ; archive_img
wfile="bbx15-blank-\${base_rootfs}-4gb" ; archive_img

#wfile="omap5-uevm-\${base_rootfs}-4gb"  ; archive_img
#wfile="tre-\${base_rootfs}-4gb"         ; archive_img

#
base_rootfs="${debian_jessie_lxqt_2gb}" ; blend="lxqt-2gb"

wfile="bone-\${base_rootfs}-2gb"      ; archive_img
#wfile="BBB-blank-\${base_rootfs}-2gb" ; archive_img

#
base_rootfs="${debian_jessie_lxqt_xm_4gb}" ; blend="lxqt-xm-4gb"

wfile="bbxm-\${base_rootfs}-4gb"      ; archive_img

#
base_rootfs="${debian_jessie_iot}" ; blend="iot"

wfile="bone-\${base_rootfs}-4gb"        ; archive_img
wfile="BBB-blank-\${base_rootfs}-4gb"   ; archive_img
wfile="BBBL-blank-\${base_rootfs}-4gb"  ; archive_img
#wfile="BBBW-blank-\${base_rootfs}-4gb" ; archive_img

#
base_rootfs="${debian_jessie_console}" ; blend="console"

wfile="a335-eeprom-\${base_rootfs}-2gb" ; archive_img
wfile="bone-\${base_rootfs}-2gb"        ; archive_img
wfile="BBB-blank-\${base_rootfs}-2gb"   ; archive_img
wfile="bbx15-\${base_rootfs}-2gb"       ; archive_img
wfile="bbx15-blank-\${base_rootfs}-2gb" ; archive_img

#wfile="omap5-uevm-\${base_rootfs}-2gb"  ; archive_img
#wfile="BBGW-blank-\${base_rootfs}-2gb"  ; archive_img

#
base_rootfs="${debian_jessie_seeed_lxqt_4gb}" ; blend="seeed-lxqt-4gb"

wfile="bone-\${base_rootfs}-4gb"      ; archive_img
wfile="BBG-blank-\${base_rootfs}-4gb" ; archive_img

#
base_rootfs="${debian_jessie_seeed_iot}" ; blend="seeed-iot"

wfile="bone-\${base_rootfs}-4gb"       ; archive_img
wfile="BBGW-blank-\${base_rootfs}-4gb" ; archive_img

#
base_rootfs="${debian_jessie_oemflasher}" ; blend="oemflasher"

#
base_rootfs="${debian_stretch_iot}" ; blend="stretch-iot"

wfile="bone-\${base_rootfs}-4gb"       ; archive_img

#
base_rootfs="${debian_stretch_wayland}" ; blend="stretch-wayland"

wfile="bbx15-\${base_rootfs}-4gb"       ; archive_img

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

image_prefix="bb.org"
#node:
if [ ! -d /var/www/html/farm/images/ ] ; then
	if [ ! -d /mnt/farm/images/ ] ; then
		#nfs mount...
		sudo mount -a
	fi

	if [ -d /mnt/farm/images/ ] ; then
		mkdir -p /mnt/farm/images/${image_prefix}-${time}/ || true
		echo "Copying: *.tar to server: images/${image_prefix}-${time}/"
		cp -v ${DIR}/deploy/*.tar /mnt/farm/images/${image_prefix}-${time}/ || true
		cp -v ${DIR}/deploy/gift_wrap_final_images.sh /mnt/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
		chmod +x /mnt/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
	fi
fi

#x86:
if [ -d /var/www/html/farm/images/ ] ; then
	mkdir -p /var/www/html/farm/images/${image_prefix}-${time}/ || true
	echo "Copying: *.tar to server: images/${image_prefix}-${time}/"
	cp -v ${DIR}/deploy/gift_wrap_final_images.sh /var/www/html/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
	chmod +x /var/www/html/farm/images/${image_prefix}-${time}/gift_wrap_final_images.sh || true
	sudo chown -R apt-cacher-ng:apt-cacher-ng /var/www/html/farm/images/${image_prefix}-${time}/ || true
fi

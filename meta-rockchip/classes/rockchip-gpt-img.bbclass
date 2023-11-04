# Create an image that can be written onto a SD card using dd.

inherit image_types

# Use an uncompressed ext4 by default as rootfs
IMG_ROOTFS_TYPE = "ext4"
IMG_ROOTFS = "${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${IMG_ROOTFS_TYPE}"

# This image depends on the rootfs image
IMAGE_TYPEDEP:rockchip-gpt-img = "${IMG_ROOTFS_TYPE}"

GPTIMG = "${IMAGE_BASENAME}-${MACHINE}-gpt.img"
BOOT_IMG = "${IMAGE_BASENAME}-${MACHINE}-boot.img"
IDBLOADER = "idbloader.img"
UBOOT_ITB = "u-boot.itb"

GPTIMG_APPEND:rk3566 = "console=tty1 console=ttyFIQ0,1500000n8 rw \
	root=PARTUUID=b921b045-1d rootfstype=ext4 init=/sbin/init rootwait"
GPTIMG_APPEND:rk3568 = "console=tty1 console=ttyFIQ0,1500000n8 rw \
	root=PARTUUID=b921b045-1d rootfstype=ext4 init=/sbin/init rootwait"

# from http://opensource.rock-chips.com/wiki_Partitions
LOADER1_START = "64"
LOADER1_SIZE  = "7104"
LOADER1_END   = "7167"

LOADER2_START = "16384"
LOADER2_SIZE  = "8192"
LOADER2_END   = "24575"

TRUST_START   = "24576"
TRUST_SIZE    = "8192"
TRUST_END     = "32767"

BOOT_START    = "32768"
BOOT_SIZE     = "229376"
BOOT_END      = "262143"
BOOT_SIZE_FAT = "114688"

ROOTFS_START  = "262144"


# WORKROUND: miss recipeinfo
do_image:rockchip-gpt-img[depends] += " \
	rockchip-rkbin:do_populate_lic \
	virtual/bootloader:do_populate_lic"

do_image:rockchip-gpt-img[depends] += " \
	parted-native:do_populate_sysroot \
	mtools-native:do_populate_sysroot \
	gptfdisk-native:do_populate_sysroot \
	dosfstools-native:do_populate_sysroot \
	rockchip-rkbin:do_deploy \
	virtual/kernel:do_deploy \
	virtual/bootloader:do_deploy"

PER_CHIP_IMG_GENERATION_COMMAND_rk3566 = "generate_rk3566_loader_image"
PER_CHIP_IMG_GENERATION_COMMAND_rk3568 = "generate_rk3568_loader_image"

IMAGE_CMD:rockchip-gpt-img () {
	bbwarn "DEPLOY_DIR_IMAGE ${DEPLOY_DIR_IMAGE}"
	bbwarn "WORKDIR ${WORKDIR}"

	# Change to image directory
	cd ${DEPLOY_DIR_IMAGE}

	# Remove the existing image
	rm -f "${GPTIMG}"
	rm -f "${BOOT_IMG}"

	create_rk_image

	cd ${DEPLOY_DIR_IMAGE}
	if [ -f ${WORKDIR}/${GPTIMG} ]; then
		cp ${WORKDIR}/${GPTIMG} ./
	fi
}

create_rk_image () {
	# last dd rootfs will extend gpt image to fit the size,
	# but this will overrite the backup table of GPT
	# will cause corruption error for GPT
	IMG_ROOTFS_SIZE=$(stat -L --format="%s" ${IMG_ROOTFS})
	GPTIMG_MIN_SIZE=$(expr $IMG_ROOTFS_SIZE + \( ${ROOTFS_START} + 63 \) \* 512 )
	GPT_IMAGE_SIZE=$(expr $GPTIMG_MIN_SIZE \/ 1024 \/ 1024 + 10)
	
	# Initialize sdcard image file
	dd if=/dev/zero of=${GPTIMG} bs=1M count=0 seek=$GPT_IMAGE_SIZE

	# Create partition table
	parted -s ${GPTIMG} mklabel gpt

	# Create vendor defined partitions
	parted -s ${GPTIMG} unit s mkpart loader1 ${LOADER1_START} ${LOADER1_END}
	parted -s ${GPTIMG} unit s mkpart loader2 ${LOADER2_START} ${LOADER2_END}
	parted -s ${GPTIMG} unit s mkpart trust   ${TRUST_START}   ${TRUST_END}
	parted -s ${GPTIMG} unit s mkpart boot    ${BOOT_START}    ${BOOT_END}
	parted -s ${GPTIMG} set 4 boot on
	parted -s ${GPTIMG} unit s mkpart rootfs  ${ROOTFS_START} 100%

	parted ${GPTIMG} print
	
	# Write loader1 (idbloader.img)
	dd if=${DEPLOY_DIR_IMAGE}/${IDBLOADER} of=${GPTIMG} conv=notrunc,fsync seek=${LOADER1_START}

	# Write loader2 (u-boot.itb)
	dd if=${DEPLOY_DIR_IMAGE}/${UBOOT_ITB} of=${GPTIMG} conv=notrunc,fsync seek=${LOADER2_START}

	# START change UUID for root ----------------------------------------------
	
	# the root partition is always this, because aarch64
	ROOT_PART=5
	ROOT_UUID="B921B045-1DF0-41C3-AF44-4C6F280D3FAE"

	# Change rootfs partuuid
	gdisk ${GPTIMG} <<EOF
x
c
${ROOT_PART}
${ROOT_UUID}
w
y
EOF
	# END change UUID for root ------------------------------------------------

	# START Creating and writing boot partition -------------------------------

	# Delete the boot image to avoid trouble with the build cache
	rm -f ${WORKDIR}/${BOOT_IMG}

	# Create boot partition image
	mkfs.vfat -n "boot" -S 512 -C ${WORKDIR}/${BOOT_IMG} ${BOOT_SIZE_FAT}
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin ::${KERNEL_IMAGETYPE}

	DEVICETREE_DEFAULT=""
	for DTS_FILE in ${KERNEL_DEVICETREE}; do
		[ -n "${DEVICETREE_DEFAULT}"] && DEVICETREE_DEFAULT="${DTS_FILE}"
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/${DTS_FILE} ::$(basename ${DTS_FILE})
	done

	# Create extlinux config file
	cat >${WORKDIR}/extlinux.conf <<EOF
default Yocto

label Yocto
	kernel /${KERNEL_IMAGETYPE}
	devicetree /$(basename ${DEVICETREE_DEFAULT})
	append ${GPTIMG_APPEND}
EOF

	mmd -i ${WORKDIR}/${BOOT_IMG} ::/extlinux
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${WORKDIR}/extlinux.conf ::/extlinux/
	if [ -d ${DEPLOY_DIR_IMAGE}/overlays ]; then
		mmd -i ${WORKDIR}/${BOOT_IMG} ::/overlays
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/overlays/* ::/overlays/
	fi
	if [ -e ${DEPLOY_DIR_IMAGE}/hw_intfc.conf ]; then
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/hw_intfc.conf ::/
	fi
	if [ -e ${DEPLOY_DIR_IMAGE}/uEnv.txt ]; then
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/uEnv.txt ::/
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/boot.scr ::/
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/boot.cmd ::/
	fi

	# Burn Boot Partition
	dd if=${WORKDIR}/${BOOT_IMG} of=${GPTIMG} conv=notrunc,fsync seek=${BOOT_START}

	# END Creating and writing boot partition ---------------------------------

	# Burn Rootfs Partition
	dd if=${IMG_ROOTFS} of=${GPTIMG} seek=${ROOTFS_START}
}

generate_rk3566_loader_image () {
	dd if=${DEPLOY_DIR_IMAGE}/${IDBLOADER} of=${GPTIMG} conv=notrunc,fsync seek=${LOADER1_START}
	dd if=${DEPLOY_DIR_IMAGE}/${UBOOT_ITB} of=${GPTIMG} conv=notrunc,fsync seek=${LOADER2_START}
}

generate_rk3568_loader_image () {
	
	dd if=${DEPLOY_DIR_IMAGE}/${IDBLOADER} of=${GPTIMG} conv=notrunc,fsync seek=${LOADER1_START}
	dd if=${DEPLOY_DIR_IMAGE}/${UBOOT_ITB} of=${GPTIMG} conv=notrunc,fsync seek=${LOADER2_START}
}

# common meta-rockchip wic/wks items

SPL_BINARY ?= "idbloader.img"

IMAGE_FSTYPES += "wic wic.bmap"
WKS_FILE = "rockchip.wks"
WKS_FILE_DEPENDS ?= " \
	mtools-native \
	dosfstools-native \
	e2fsprogs-native \
	virtual/bootloader \
	virtual/kernel \
	"
IMAGE_BOOT_FILES = " \
	${KERNEL_IMAGETYPE} \
	${@bb.utils.contains('KERNEL_IMAGETYPE', 'fitImage', '', '${KERNEL_DEVICETREE}', d)} \
	"

# use the first-defined <baud>;<device> pair in SERIAL_CONSOLES
# for the console parameter in the wks files
RK_CONSOLE_BAUD ?= "${@d.getVar('SERIAL_CONSOLES').split(';')[0]}"
RK_CONSOLE_DEVICE ?= "${@d.getVar('SERIAL_CONSOLES').split(';')[1].split()[0]}"

WICVARS:append = " \
	RK_CONSOLE_BAUD \
	RK_CONSOLE_DEVICE \
	SPL_BINARY \
	UBOOT_SUFFIX \
	"

# arm64 dnd arm32bts are under <vendor>/dts but is deployed under DEPLOYDIR 
do_fix_device_tree_location() {

    for kdt in ${KERNEL_DEVICETREE}
    do
        local dbt_dir=$(dirname ${kdt})
        if [ "." != "${dbt_dir}" ] ; then
            local dbt=$(basename ${kdt})
            local dst=${DEPLOY_DIR_IMAGE}/${dbt_dir}/${dbt}
            if [ ! -f ${dst} ] ; then
                mkdir -p ${DEPLOY_DIR_IMAGE}/$dbt_dir
                ln -s ${DEPLOY_DIR_IMAGE}/${dbt} ${dst}
            fi
        fi
    done
}

addtask do_fix_device_tree_location after do_write_wks_template before do_image_wic
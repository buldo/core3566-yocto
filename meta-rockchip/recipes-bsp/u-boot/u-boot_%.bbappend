#FILESEXTRAPATHS:prepend:sunxi := "${THISDIR}/files:"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://source.denx.de/u-boot/u-boot.git;protocol=https;branch=master \
           file://0001-Core3566-defconfig-and-trees.patch"

# various machines require the pyelftools library for parsing dtb files
DEPENDS:append = " python3-pyelftools-native"
DEPENDS:append:rock-pi-4 = " gnutls-native"

EXTRA_OEMAKE:append:px30 = " BL31=${DEPLOY_DIR_IMAGE}/bl31-px30.elf"
EXTRA_OEMAKE:append:rk3328 = " BL31=${DEPLOY_DIR_IMAGE}/bl31-rk3328.elf"
EXTRA_OEMAKE:append:rk3399 = " BL31=${DEPLOY_DIR_IMAGE}/bl31-rk3399.elf"
EXTRA_OEMAKE:append:rk3588s = " \
	BL31=${DEPLOY_DIR_IMAGE}/bl31-rk3588.elf \
	ROCKCHIP_TPL=${DEPLOY_DIR_IMAGE}/ddr-rk3588.bin \
	"

EXTRA_OEMAKE:append:rk3566 = " \
	BL31=${DEPLOY_DIR_IMAGE}/bl31-rk3566.elf \
	ROCKCHIP_TPL=${DEPLOY_DIR_IMAGE}/ddr-rk3566.bin \
	"

INIT_FIRMWARE_DEPENDS ??= ""
INIT_FIRMWARE_DEPENDS:px30 = " trusted-firmware-a:do_deploy"
INIT_FIRMWARE_DEPENDS:rk3328 = " trusted-firmware-a:do_deploy"
INIT_FIRMWARE_DEPENDS:rk3399 = " trusted-firmware-a:do_deploy"
INIT_FIRMWARE_DEPENDS:rk3588s = " rockchip-rkbin:do_deploy"
INIT_FIRMWARE_DEPENDS:rk3566 = " rockchip-rkbin:do_deploy"
do_compile[depends] .= "${INIT_FIRMWARE_DEPENDS}"

do_compile:append:rock2-square () {
	# copy to default search path
	if [ "${SPL_BINARY}" = "u-boot-spl-dtb.bin" ]; then
		cp ${B}/spl/${SPL_BINARY} ${B}
	fi
}

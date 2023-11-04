FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

COMPATIBLE_MACHINE:marsboard-rk3066 = "marsboard-rk3066"
COMPATIBLE_MACHINE:rock2-square = "rock2-square"
COMPATIBLE_MACHINE:radxarock = "radxarock"
COMPATIBLE_MACHINE:firefly-rk3288 = "firefly-rk3288"
COMPATIBLE_MACHINE:vyasa-rk3288 = "vyasa-rk3288"
COMPATIBLE_MACHINE:tinker-board = "tinker-board"
COMPATIBLE_MACHINE:tinker-board-s = "tinker-board-s"
COMPATIBLE_MACHINE:rock-pi-4 = "rock-pi-4"
COMPATIBLE_MACHINE:nanopi-m4 = "nanopi-m4"
COMPATIBLE_MACHINE:nanopi-m4-2gb = "nanopi-m4-2gb"
COMPATIBLE_MACHINE:rock64 = "rock64"
COMPATIBLE_MACHINE:rock-pi-e = "rock-pi-e"
COMPATIBLE_MACHINE:nanopi-r4s = "nanopi-r4s"
COMPATIBLE_MACHINE:nanopi-r2s = "nanopi-r2s"

COMPATIBLE_MACHINE:luckfox-core3566 = "luckfox-core3566"

#SRC_URI:append = " file://rockchip-kmeta;type=kmeta;name=rockchip-kmeta;destsuffix=rockchip-kmeta"
#SRC_URI:append:nanopi-r4s = " file://nanopi-r4s.scc"

SRC_URI += " \
    file://0001-Core3566-dts.patch \
    file://defconfig "

#KBUILD_DEFCONFIG:luckfox-core3566 = "rk3566-luckfox-core3566_defconfig"
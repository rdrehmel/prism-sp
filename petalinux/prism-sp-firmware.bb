SUMMARY = "Standard Prism SP firmwares"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_SYSROOT_STRIP = "1"
INSANE_SKIP:${PN} = "arch"

SRC_URI += "file://prism-sp-duo-rx-firmware.elf"
SRC_URI += "file://prism-sp-duo-tx-firmware.elf"
S = "${WORKDIR}"

do_install() {
	install -d ${D}/lib/firmware
	install -m 0755 prism-sp-duo-rx-firmware.elf ${D}/lib/firmware
	install -m 0755 prism-sp-duo-tx-firmware.elf ${D}/lib/firmware
}
FILES:${PN} += "/lib/firmware/prism-sp-duo-rx-firmware.elf"
FILES:${PN} += "/lib/firmware/prism-sp-duo-tx-firmware.elf"

SUMMARY = "Standard prism sp firmware"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_SYSROOT_STRIP = "1"
INSANE_SKIP_${PN} = "arch"

SRC_URI = "file://prism-sp-firmware.elf"
S = "${WORKDIR}"

do_install() {
	install -d ${D}/lib/firmware
	install -m 0755 prism-sp-firmware.elf ${D}/lib/firmware
}
FILES_${PN} = "/lib/firmware/prism-sp-firmware.elf"

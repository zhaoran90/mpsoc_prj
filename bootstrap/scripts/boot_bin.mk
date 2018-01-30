# TODO: change to your own ZynqMP chip number
ZYNQMP_CHIP := xczu9eg

BOOT_GEN_FLAGS := -arch zynqmp -o BOOT.bin -packagename $(ZYNQMP_CHIP) -w on

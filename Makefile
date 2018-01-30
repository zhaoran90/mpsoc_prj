# TODO: Change to your Vivado IDE version and installed location
VIVADO_VERSION ?= 2017.2
VIVADO_TOOL_BASE ?= /opt/Xilinx_$(VIVADO_VERSION)

# TODO: change to your own Device Tree Compiler (DTC) location
DTC_LOC ?= /opt/dtc

# Vivado and SDK tool executable binary location
VIVADO_TOOL_PATH := $(VIVADO_TOOL_BASE)/Vivado/$(VIVADO_VERSION)/bin
SDK_TOOL_PATH := $(VIVADO_TOOL_BASE)/SDK/$(VIVADO_VERSION)/bin

# Cross-compiler location
#=================================================
# aarch-linux-gnu- : used for compilation of uboot, Linux kernel, ATF and other drivers
# aarch-none-gnu- : used for compilation of FSBL
# mb- (microblaze-xilinx-elf-) : used for compilation of PMU Firmware
#=================================================
LINUX_GCC_PATH := $(VIVADO_TOOL_BASE)/SDK/$(VIVADO_VERSION)/gnu/aarch64/lin/aarch64-linux/bin
ELF_GCC_PATH := $(VIVADO_TOOL_BASE)/SDK/$(VIVADO_VERSION)/gnu/aarch64/lin/aarch64-none/bin
MB_GCC_PATH := $(VIVADO_TOOL_BASE)/SDK/$(VIVADO_VERSION)/gnu/microblaze/lin/bin

# Leveraged Vivado tools
VIVADO_BIN := $(VIVADO_TOOL_PATH)/vivado
HSI_BIN := $(SDK_TOOL_PATH)/hsi
BOOT_GEN_BIN := $(SDK_TOOL_PATH)/bootgen

# Optional Trusted OS
TOS ?= none
BL32 := $(TOS)

# Linux kernel (i.e., Physical machine, Dom0, DomU)
KERN_NAME ?= phys_os

# Temporal directory to hold hardware design output files 
# (i.e., bitstream, hardware description file (HDF))
HW_PLATFORM := hw_plat
BITSTREAM := $(HW_PLATFORM)/system.bitstream
HW_DESIGN_HDF := $(HW_PLATFORM)/system.hdf

# Object files to generate BOOT.bin
BL2_BIN := ./bootstrap/fsbl/bl2.elf
PMU_FW := ./bootstrap/pmufw/pmufw.elf
BL31_BIN := ./software/atf/bl31.elf
BL33_BIN := ./software/uboot/u-boot.elf

BOOT_BIN_OBJS := $(BL31_BIN) $(BL33_BIN) $(BL2_BIN) $(PMU_FW)

BOOTBIN_WITH_TOS ?= n
ifneq (${TOS}, none)
BOOTBIN_WITH_TOS := y
endif

BOOTBIN_WITH_BIT ?= n

# Temporal directory to save all image files for porting
INSTALL_LOC := $(shell pwd)/ready_for_download

.PHONY: FORCE

#==========================================
# Generation of BL31 (i.e., ARM Trusted Firmware (ATF)) 
# and optional BL32 Trusted OS (e.g., OP-TEE) 
#==========================================
atf $(BL31_BIN): $(BL32) FORCE
	@echo "Compiling ARM Trusted Firmware..."
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) TOS=$(TOS) atf

atf_clean: $(BL32)_clean
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) TOS=$(TOS) $@

atf_distclean: $(BL32)_distclean
	$(MAKE) -C ./software $@
	
none:
	@echo "No specified Trusted OS"

none_clean:
	@echo "No specified Trusted OS"

optee: FORCE
	@echo "Compiling OP-TEE Trusted OS..."
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) TOS=optee optee

optee_clean:
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) TOS=optee $@

optee_distclean:
	$(MAKE) -C ./software $@

#==========================================
# Generation of BL33 image, including U-Boot,
# Linux kernel for virtual and non-virtual 
# environment, and optional Xen hypervisor
#==========================================
uboot $(BL33_BIN): FORCE
	@echo "Compiling U-Boot..."
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) DTC_LOC=$(DTC_LOC) uboot

uboot_clean:
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) $@

uboot_distclean:
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) $@

kernel_image: FORCE
	@echo "Compiling Linux kernel..."
	@mkdir -p $(INSTALL_LOC)
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) KERN_NAME=$(KERN_NAME) INSTALL_LOC=$(INSTALL_LOC) $@

kernel_config: FORCE
	@echo "Configuring Linux kernel..."
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) KERN_NAME=$(KERN_NAME) $@

kernel_clean:
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) KERN_NAME=$(KERN_NAME) $@

kernel_distclean:
	$(MAKE) -C ./software COMPILER_PATH=$(LINUX_GCC_PATH) KERN_NAME=$(KERN_NAME) INSTALL_LOC=$(INSTALL_LOC) $@

#==========================================
# Generation of Xilinx FSBL (BL2)
#==========================================
fsbl $(BL2_BIN): FORCE
	@echo "Compiling FSBL..."
	$(MAKE) -C ./bootstrap COMPILER_PATH=$(ELF_GCC_PATH) HSI=$(HSI_BIN) fsbl

fsbl_clean:
	$(MAKE) -C ./bootstrap COMPILER_PATH=$(ELF_GCC_PATH) $@

fsbl_distclean:
	$(MAKE) -C ./bootstrap $@

#==========================================
# Generation of PMU Firmware (PMUFW)
#==========================================
pmufw $(PMU_FW): FORCE
	@echo "Compiling PMU Firmware..."
	$(MAKE) -C ./bootstrap COMPILER_PATH=$(MB_GCC_PATH) HSI=$(HSI_BIN) pmufw

pmufw_clean:
	$(MAKE) -C ./bootstrap COMPILER_PATH=$(MB_GCC_PATH) $@ 

pmufw_distclean:
	$(MAKE) -C ./bootstrap $@

#==========================================
# Generation of BOOT.bin
#==========================================
boot_bin: $(BOOT_BIN_OBJS)
	@echo "Generating BOOT.bin image..."
	@mkdir -p $(INSTALL_LOC)
	$(MAKE) -C ./bootstrap BOOT_GEN=$(BOOT_GEN_BIN) WITH_TOS=$(BOOTBIN_WITH_TOS) TOS=$(TOS) WITH_BIT=$(BOOTBIN_WITH_BIT) O=$(INSTALL_LOC) $@

boot_bin_clean:
	$(MAKE) -C ./bootstrap $@

#==========================================
# Hardware Design
#==========================================
gen_prj: FORCE
	@echo "Creating Vivado hardware design project..."
	$(MAKE) -C ./hardware VIVADO=$(VIVADO_BIN) $@

open_prj: FORCE
	@echo "Opening Vivado hardware design project..."
	$(MAKE) -C ./hardware VIVADO=$(VIVADO_BIN) $@

hw_install: FORCE
	@echo "Installing Hardware design output files..."
	@mkdir -p $(HW_PLATFORM)
	$(MAKE) -C ./hardware O=$(HW_PLATFORM) $@

copy_hdf: FORCE
	@

$(BITSTREAM): FORCE
	$(error no bitstream file, please inform your hardware design team to upload it)

hw_clean:
	$(MAKE) -C ./hardware $@


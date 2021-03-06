#############################################################
#
# at91bootstrap
#
#############################################################
AT91BOOTSTRAP_VERSION:=2.10
AT91BOOTSTRAP_PATCH_LEVEL:=
AT91BOOTSTRAP_PATCHED_VERSION:=$(AT91BOOTSTRAP_VERSION)$(AT91BOOTSTRAP_PATCH_LEVEL)
AT91BOOTSTRAP_NAME:=at91bootstrap-$(AT91BOOTSTRAP_VERSION)
ATMEL_MIRROR:=$(strip $(subst ",, $(BR2_ATMEL_MIRROR)))
#"))
AT91BOOTSTRAP_SITE:=$(ATMEL_MIRROR)
AT91BOOTSTRAP_SOURCE:=$(AT91BOOTSTRAP_NAME).tar.bz2
AT91BOOTSTRAP_DIR:=$(PROJECT_BUILD_DIR)/$(AT91BOOTSTRAP_NAME)
AT91BOOTSTRAP:=$(strip $(subst ",, $(BR2_AT91BOOTSTRAP)))
#"))
AT91BOOTSTRAP_ZCAT:=$(BZCAT)

AT91BOOTSTRAP_BOARD:=$(strip $(subst ",, $(BR2_TARGET_AT91BOOTSTRAP_BOARD)))
#"))

AT91BOOTSTRAP_MEMORY:=$(strip $(subst ",, $(BR2_TARGET_AT91BOOTSTRAP_MEMORY)))
#"))

AT91BOOTSTRAP_BINARY:=$(BOARD_NAME)-$(AT91BOOTSTRAP_MEMORY)boot-$(AT91BOOTSTRAP_PATCHED_VERSION).bin

AT91BOOTSTRAP_TARGET:=$(AT91BOOTSTRAP_DIR)/binaries/$(AT91BOOTSTRAP_BINARY)

AT91BOOTSTRAP_JUMP_ADDR:=$(strip $(subst ",, $(BR2_AT91BOOTSTRAP_JUMP_ADDR)))
#"))
AT91BOOTSTRAP_IMG_SIZE:=$(strip $(subst ",, $(BR2_AT91BOOTSTRAP_IMG_SIZE)))
#"))

AT91_CUSTOM_FLAGS:=
ifneq ($(AT91BOOTSTRAP_JUMP_ADDR),)
AT91_CUSTOM_FLAGS+=-DJUMP_ADDR=$(AT91BOOTSTRAP_JUMP_ADDR)
endif
ifneq ($(AT91BOOTSTRAP_IMG_SIZE),)
AT91_CUSTOM_FLAGS+=-DIMG_SIZE=$(AT91BOOTSTRAP_IMG_SIZE)
endif

$(DL_DIR)/$(AT91BOOTSTRAP_SOURCE):
	 $(call DOWNLOAD,$(AT91BOOTSTRAP_SITE),$(AT91BOOTSTRAP_SOURCE))

$(AT91BOOTSTRAP_DIR)/.unpacked: $(DL_DIR)/$(AT91BOOTSTRAP_SOURCE)
	mkdir -p $(PROJECT_BUILD_DIR)
	$(AT91BOOTSTRAP_ZCAT) $(DL_DIR)/$(AT91BOOTSTRAP_SOURCE) | tar -C $(PROJECT_BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(AT91BOOTSTRAP_DIR) target/device/Atmel/at91bootstrap/ at91bootstrap-$(AT91BOOTSTRAP_VERSION)\*.patch
	touch $(AT91BOOTSTRAP_DIR)/.unpacked

$(AT91BOOTSTRAP_DIR)/.configured: $(AT91BOOTSTRAP_DIR)/.unpacked .config
	$(MAKE) \
		MEMORY=$(AT91BOOTSTRAP_MEMORY) \
		CROSS_COMPILE=$(TARGET_CROSS) \
		-C $(AT91BOOTSTRAP_DIR) \
		$(AT91BOOTSTRAP_BOARD)_defconfig
	touch $(AT91BOOTSTRAP_DIR)/.configured

#		$(BOARD_NAME)_defconfig

$(AT91BOOTSTRAP_TARGET): $(AT91BOOTSTRAP_DIR)/.configured
	$(MAKE) \
		MEMORY=$(AT91BOOTSTRAP_MEMORY) \
		CROSS_COMPILE=$(TARGET_CROSS) \
		AT91_CUSTOM_FLAGS="$(AT91_CUSTOM_FLAGS)" \
		-C $(AT91BOOTSTRAP_DIR)

$(AT91BOOTSTRAP_DIR)/.installed:: $(AT91BOOTSTRAP_TARGET)
	mkdir -p $(BINARIES_DIR)
ifeq	($(AT91BOOTSTRAP_VERSION),2.3)
	cp $(AT91BOOTSTRAP_TARGET) $(BINARIES_DIR)/$(AT91BOOTSTRAP_BINARY)
	$(call COPY_FILE, $(AT91BOOTSTRAP_TARGET), $(BR2_TARGET_ATMEL_COPYTO), $(AT91BOOTSTRAP_BINARY))
else
	make MEMORY=$(AT91BOOTSTRAP_MEMORY) \
		CROSS_COMPILE=$(TARGET_CROSS) \
		-C $(AT91BOOTSTRAP_DIR) boot
	make DESTDIR=$(BINARIES_DIR) -C $(AT91BOOTSTRAP_DIR) install || ??
		echo "Could not copy bootstrap to BINARIES_DIR"
ifneq ($(BR2_TARGET_ATMEL_COPYTO),)
	make DESTDIR=$(BR2_TARGET_ATMEL_COPYTO) -C $(AT91BOOTSTRAP_DIR) install || \
		echo "Could not copy bootstrap to BR2_ATMEL_COPYTO"
endif
endif
	touch $@

#	cp $(AT91BOOTSTRAP_TARGET) $(BINARIES_DIR)/$(AT91BOOTSTRAP_BINARY)
#	cp $(AT91BOOTSTRAP_TARGET) $(BR2_TARGET_ATMEL_COPYTO)/$(AT91BOOTSTRAP_BINARY)

.PHONY: at91bootstrap at91bootstrap-source

at91bootstrap: $(AT91BOOTSTRAP_DIR)/.installed

at91bootstrap-source: $(DL_DIR)/$(AT91BOOTSTRAP_SOURCE)

at91bootstrap-unpacked: $(AT91BOOTSTRAP_DIR)/.unpacked

.PHONY: at91bootstrap-clean at91bootstrap-dirclean

at91bootstrap-clean:
	make -C $(AT91BOOTSTRAP_DIR) clean

at91bootstrap-dirclean:
	rm -rf $(AT91BOOTSTRAP_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_TARGET_AT91BOOTSTRAP),y)
TARGETS+=at91bootstrap
endif

at91bootstrap-status:
	@echo AT91BOOTSTRAP_BOARD=$(AT91BOOTSTRAP_BOARD)


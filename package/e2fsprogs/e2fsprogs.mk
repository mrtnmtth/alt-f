#############################################################
#
# e2fsprogs
#
#############################################################

E2FSPROGS_VERSION:=1.46.2
#E2FSPROGS_VERSION:=1.42 release is too big! (and uclibc needs ftw, +4KB)
#E2FSPROGS_VERSION:=1.42.13 rootfs too big by 73792 bytes, removing inadyn bigger by 24640
#E2FSPROGS_VERSION:=1.43.3 rootfs too big by 131136 bytes

E2FSPROGS_SOURCE=e2fsprogs-$(E2FSPROGS_VERSION).tar.xz
E2FSPROGS_SITE=$(BR2_KERNEL_MIRROR)/linux/kernel/people/tytso/e2fsprogs/v$(E2FSPROGS_VERSION)

E2FSPROGS_DIR=$(BUILD_DIR)/e2fsprogs-$(E2FSPROGS_VERSION)
E2FSPROGS_CAT:=$(XZCAT)
E2FSPROGS_BINARY:=misc/mke2fs
E2FSPROGS_TARGET_BINARY:=usr/sbin/mke2fs
LIBUUID_DIR=$(E2FSPROGS_DIR)/lib/uuid/
LIBUUID_TARGET_DIR:=usr/lib/
LIBUUID_TARGET_BINARY:=libuuid.so

E2FSPROGS_MISC_STRIP:= \
	badblocks chattr dumpe2fs filefrag fsck logsave \
	lsattr mke2fs mklost+found tune2fs 
#	blkid uuidgen

$(DL_DIR)/$(E2FSPROGS_SOURCE):
	 $(call DOWNLOAD,$(E2FSPROGS_SITE),$(E2FSPROGS_SOURCE))

e2fsprogs-source: $(DL_DIR)/$(E2FSPROGS_SOURCE)

$(E2FSPROGS_DIR)/.unpacked: $(DL_DIR)/$(E2FSPROGS_SOURCE)
	$(E2FSPROGS_CAT) $(DL_DIR)/$(E2FSPROGS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(E2FSPROGS_DIR) package/e2fsprogs/ e2fsprogs-$(E2FSPROGS_VERSION)\*.patch
	$(CONFIG_UPDATE) $(E2FSPROGS_DIR)/config
	touch $@

$(E2FSPROGS_DIR)/.configured: $(E2FSPROGS_DIR)/.unpacked
	(cd $(E2FSPROGS_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--with-linker=$(TARGET_CROSS)ld \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--libdir=/usr/lib \
		--libexecdir=/usr/lib \
		--sysconfdir=/etc \
		--datadir=/usr/share \
		--localstatedir=/var \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--enable-resizer --enable-fsck \
		--enable-elf-shlibs --enable-dynamic-e2fsck \
		--disable-defrag \
		--disable-swapfs --disable-tls --disable-e2initrd-helper \
		--disable-debugfs --disable-imager --disable-testio-debug \
		--without-catgets $(DISABLE_NLS) \
		$(DISABLE_LARGEFILE) \
		--enable-libuuid --enable-libblkid \
	)
	# do away with hiding the commands
	find $(E2FSPROGS_DIR) -name Makefile \
		| xargs $(SED) '/^[[:space:]]*@/s/@/$$\(Q\)/'
	touch $@

$(E2FSPROGS_DIR)/$(E2FSPROGS_BINARY): $(E2FSPROGS_DIR)/.configured
	$(MAKE1) -C $(E2FSPROGS_DIR)
	(cd $(E2FSPROGS_DIR)/misc; \
		$(STRIPCMD) $(E2FSPROGS_MISC_STRIP); \
	)
	#$(STRIPCMD) $(E2FSPROGS_DIR)/lib/lib*.so.*.*
	touch -c $@

$(E2FSPROGS_DIR)/lib/$(LIBUUID_TARGET_BINARY): $(E2FSPROGS_DIR)/.configured
	$(MAKE1) -C $(E2FSPROGS_DIR)/lib/uuid
	touch -c $@

$(STAGING_DIR)/$(E2FSPROGS_TARGET_BINARY): $(E2FSPROGS_DIR)/$(E2FSPROGS_BINARY)
	$(MAKE1) PATH=$(TARGET_PATH) DESTDIR=$(STAGING_DIR) LDCONFIG=true \
		-C $(E2FSPROGS_DIR) install install-libs

$(STAGING_DIR)/$(LIBUUID_TARGET_DIR)/$(LIBUUID_TARGET_BINARY): $(E2FSPROGS_DIR)/lib/$(LIBUUID_TARGET_BINARY)
	$(MAKE1) PATH=$(TARGET_PATH) DESTDIR=$(STAGING_DIR) LDCONFIG=true \
		-C $(LIBUUID_DIR) install

E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_BADBLOCKS) += ${TARGET_DIR}/usr/sbin/badblocks
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_BLKID) += ${TARGET_DIR}/usr/sbin/blkid
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_CHATTR) += ${TARGET_DIR}/usr/bin/chattr
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_DUMPE2FS) += ${TARGET_DIR}/usr/sbin/dumpe2fs
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_E2LABEL) += ${TARGET_DIR}/usr/sbin/e2label
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_E2FSCK) += ${TARGET_DIR}/usr/sbin/e2fsck
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_FILEFRAG) += ${TARGET_DIR}/usr/sbin/filefrag
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_FSCK) += ${TARGET_DIR}/usr/sbin/fsck
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_LOGSAVE) += ${TARGET_DIR}/usr/sbin/logsave
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_LSATTR) += ${TARGET_DIR}/usr/bin/lsattr
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_MKE2FS) += ${TARGET_DIR}/usr/sbin/mke2fs
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_MKLOSTFOUND) += ${TARGET_DIR}/usr/sbin/mklost+found
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_UUIDGEN) += ${TARGET_DIR}/usr/bin/uuidgen
E2FSPROGS_RM$(BR2_PACKAGE_E2FSPROGS_RESIZE) += ${TARGET_DIR}/usr/bin/resize2fs

$(TARGET_DIR)/$(E2FSPROGS_TARGET_BINARY): $(STAGING_DIR)/$(E2FSPROGS_TARGET_BINARY)
	$(MAKE1) PATH=$(TARGET_PATH) DESTDIR=$(TARGET_DIR) LDCONFIG=true \
		-C $(E2FSPROGS_DIR) install
	rm -rf ${TARGET_DIR}/sbin/mkfs.ext[234] \
		${TARGET_DIR}/sbin/fsck.ext[234] \
		${TARGET_DIR}/sbin/findfs \
		${TARGET_DIR}/sbin/tune2fs
ifneq ($(E2FSPROGS_RM),)
	rm -rf $(E2FSPROGS_RM)
endif
ifeq ($(BR2_PACKAGE_E2FSPROGS_MKE2FS),y)
	ln -sf mke2fs ${TARGET_DIR}/usr/sbin/mkfs.ext2
	ln -sf mke2fs ${TARGET_DIR}/usr/sbin/mkfs.ext3
	ln -sf mke2fs ${TARGET_DIR}/usr/sbin/mkfs.ext4
endif
ifeq ($(BR2_PACKAGE_E2FSPROGS_E2FSCK),y)
	ln -sf e2fsck ${TARGET_DIR}/usr/sbin/fsck.ext2
	ln -sf e2fsck ${TARGET_DIR}/usr/sbin/fsck.ext3
	ln -sf e2fsck ${TARGET_DIR}/usr/sbin/fsck.ext4
endif
ifeq ($(BR2_PACKAGE_E2FSPROGS_TUNE2FS),y)
	ln -sf e2label ${TARGET_DIR}/usr/sbin/tune2fs
endif
ifeq ($(BR2_PACKAGE_E2FSPROGS_FINDFS),y)
	ln -sf e2label ${TARGET_DIR}/usr/sbin/findfs
endif
ifneq ($(BR2_HAVE_INFOPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/info
endif
ifneq ($(BR2_HAVE_MANPAGES),y)
	rm -rf $(TARGET_DIR)/usr/share/man
endif
	rm -rf $(TARGET_DIR)/share/locale
	rm -rf $(TARGET_DIR)/usr/share/doc
	touch -c $@

$(TARGET_DIR)/$(LIBUUID_TARGET_DIR)/$(LIBUUID_TARGET_BINARY): $(STAGING_DIR)/$(LIBUUID_TARGET_DIR)/$(LIBUUID_TARGET_BINARY)
	$(MAKE1) PATH=$(TARGET_PATH) DESTDIR=$(STAGING_DIR) LDCONFIG=true \
		-C $(LIBUUID_DIR) install
	cp -a $(STAGING_DIR)/$(LIBUUID_TARGET_DIR)/$(LIBUUID_TARGET_BINARY)* \
		$(TARGET_DIR)/$(LIBUUID_TARGET_DIR)/
	touch $@

libuuid: uclibc $(TARGET_DIR)/$(LIBUUID_TARGET_DIR)/$(LIBUUID_TARGET_BINARY)

e2fsprogs: uclibc libuuid $(TARGET_DIR)/$(E2FSPROGS_TARGET_BINARY)

e2fsprogs-build: $(E2FSPROGS_DIR)/$(E2FSPROGS_BINARY)

e2fsprogs-configure: $(E2FSPROGS_DIR)/.configured

e2fsprogs-clean:
	$(MAKE1) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(E2FSPROGS_DIR) uninstall
	-$(MAKE1) -C $(E2FSPROGS_DIR) clean

e2fsprogs-dirclean:
	rm -rf $(E2FSPROGS_DIR)

libuuid-clean:
	-$(MAKE1) PATH=$(TARGET_PATH) DESTDIR=$(STAGING_DIR) LDCONFIG=true \
		-C $(LIBUUID_DIR) uninstall
	# make uninstall misses the includes
	rm -rf $(STAGING_DIR)/usr/include/uuid
	rm -f $(TARGET_DIR)/$(LIBUUID_TARGET_DIR)/$(LIBUUID_TARGET_BINARY)*
	-$(MAKE1) -C $(LIBUUID_DIR) clean

libuuid-source: e2fsprogs-source
libuuid-dirclean: e2fsprogs-dirclean

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_E2FSPROGS),y)
TARGETS+=e2fsprogs
endif

ifeq ($(BR2_PACKAGE_LIBUUID),y)
TARGETS+=libuuid
endif

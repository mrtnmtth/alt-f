#############################################################
#
# popt
#
#############################################################

POPT_VERSION:=1.16
POPT_SITE:=https://ftp.openbsd.org/pub/OpenBSD/distfiles
POPT_INSTALL_STAGING = YES
POPT_INSTALL_TARGET = YES
POPT_LIBTOOL_PATCH = NO
POPT_CONF_OPT = --libdir=/usr/lib
POPT_CONF_ENV = ac_cv_va_copy=yes

ifeq ($(BR2_PACKAGE_LIBICONV),y)
POPT_CONF_ENV += am_cv_lib_iconv=yes
POPT_CONF_OPT += --with-libiconv-prefix=$(STAGING_DIR)/usr
endif

POPT_DEPENDENCIES:=uclibc libiconv

$(eval $(call AUTOTARGETS,package,popt))

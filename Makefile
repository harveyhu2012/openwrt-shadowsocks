#
# Copyright (C) 2015 OpenWrt-dist
# Copyright (C) 2015 Jian Chang <aa65535@live.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=shadowsocksR-libev
PKG_VERSION:=2.4.8
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/breakwa11/shadowsocks-libev
#PKG_SOURCE_VERSION:=63f357a4b507364692bec02ecf82f056376dd663 //Stable?
PKG_SOURCE_VERSION:=f3a923ee38a1fed6b81336bb90b83e37412ee2bb

PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Max Lv <max.c.lv@gmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf
PKG_USE_MIPS16:=0
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/shadowsocksR-libev/Default
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Lightweight Secured Socks5 Proxy $(2)
	URL:=https://github.com/breakwa11/shadowsocks-libev
	VARIANT:=$(1)
	DEPENDS:=$(3)
endef

Package/shadowsocksR-libev = $(call Package/shadowsocksR-libev/Default,openssl,(OpenSSL),+libopenssl +libpthread)
Package/shadowsocksR-libev-spec = $(call Package/shadowsocksR-libev/Default,openssl,(OpenSSL),+libopenssl +libpthread +ipset +ip +iptables-mod-tproxy)
Package/shadowsocksR-libev-polarssl = $(call Package/shadowsocksR-libev/Default,polarssl,(PolarSSL),+libpolarssl +libpthread)
Package/shadowsocksR-libev-spec-polarssl = $(call Package/shadowsocksR-libev/Default,polarssl,(PolarSSL),+libpolarssl +libpthread +ipset +ip +iptables-mod-tproxy)

define Package/shadowsocksR-libev/description
Shadowsocks-libev is a lightweight secured socks5 proxy for embedded devices and low end boxes.
endef

Package/shadowsocksR-libev-spec/description = $(Package/shadowsocksR-libev/description)
Package/shadowsocksR-libev-polarssl/description = $(Package/shadowsocksR-libev/description)
Package/shadowsocksR-libev-spec-polarssl/description = $(Package/shadowsocksR-libev/description)

define Package/shadowsocksR-libev/conffiles
/etc/shadowsocks.json
endef

define Package/shadowsocksR-libev-spec/conffiles
/etc/config/shadowsocks
endef

Package/shadowsocksR-libev-polarssl/conffiles = $(Package/shadowsocksR-libev/conffiles)
Package/shadowsocksR-libev-spec-polarssl/conffiles = $(Package/shadowsocksR-libev-spec/conffiles)

define Package/shadowsocksR-libev-spec/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	uci -q batch <<-EOF >/dev/null
		delete firewall.shadowsocks
		set firewall.shadowsocks=include
		set firewall.shadowsocks.type=script
		set firewall.shadowsocks.path=/var/etc/shadowsocks.include
		set firewall.shadowsocks.reload=1
		commit firewall
EOF
fi
exit 0
endef

Package/shadowsocksR-libev-spec-polarssl/postinst = $(Package/shadowsocksR-libev-spec/postinst)

CONFIGURE_ARGS += --disable-documentation --disable-ssp

ifeq ($(BUILD_VARIANT),polarssl)
	CONFIGURE_ARGS += --with-crypto-library=polarssl
endif

define Package/shadowsocksR-libev/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-{local,redir,tunnel} $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_CONF) ./files/shadowsocks.conf $(1)/etc/shadowsocks.json
	$(INSTALL_BIN) ./files/shadowsocks.init $(1)/etc/init.d/shadowsocks
endef

define Package/shadowsocksR-libev-spec/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-{redir,tunnel} $(1)/usr/bin
	$(INSTALL_BIN) ./files/shadowsocks.rule $(1)/usr/bin/ss-rules
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/shadowsocks.config $(1)/etc/config/shadowsocks
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocks.spec $(1)/etc/init.d/shadowsocks
endef

Package/shadowsocksR-libev-polarssl/install = $(Package/shadowsocksR-libev/install)
Package/shadowsocksR-libev-spec-polarssl/install = $(Package/shadowsocksR-libev-spec/install)

$(eval $(call BuildPackage,shadowsocksR-libev))
$(eval $(call BuildPackage,shadowsocksR-libev-spec))
$(eval $(call BuildPackage,shadowsocksR-libev-polarssl))
$(eval $(call BuildPackage,shadowsocksR-libev-spec-polarssl))

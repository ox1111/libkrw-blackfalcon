ABI_VERSION     := 0
CURRENT_VERSION := 1.1.1
COMPAT_VERSION  := 1.0.0
#PACKAGE_DOMAIN  := net.siguza.

TARGET           = libkrw
SRC              = src
INC              = include
PKG              = pkg

IGCC            ?= xcrun -sdk iphoneos clang -arch arm64  -arch arm64e
IGCC_FLAGS      ?= -Wall -O3 -I$(INC)
DYLIB_FLAGS     ?= -shared -miphoneos-version-min=7.0 -Wl,-install_name,/usr/lib/$(TARGET).$(ABI_VERSION).dylib -Wl,-current_version,$(CURRENT_VERSION) -Wl,-compatibility_version,$(COMPAT_VERSION) -Wl,-no_warn_inits
SIGN            ?= codesign
SIGN_FLAGS      ?= -s -
TAPI            ?= xcrun -sdk iphoneos tapi
TAPI_FLAGS      ?= stubify --no-uuids --filetype=tbd-v2
TAR             ?= bsdtar
TAR_FLAGS       ?= --uid 0 --gid 0

.PHONY: all deb clean

all: $(TARGET).$(ABI_VERSION).dylib $(TARGET).tbd

deb: $(PACKAGE_DOMAIN)$(TARGET)_$(CURRENT_VERSION)_iphoneos-arm64.deb $(PACKAGE_DOMAIN)$(TARGET)-dev_$(CURRENT_VERSION)_iphoneos-arm64.deb

$(TARGET).$(ABI_VERSION).dylib: $(SRC)/*.c $(INC)/*.h
	$(IGCC) $(IGCC_FLAGS) $(DYLIB_FLAGS) -o $@ $(SRC)/*.c
	$(SIGN) $(SIGN_FLAGS) $@

$(TARGET).tbd: $(TARGET).$(ABI_VERSION).dylib
	$(TAPI) $(TAPI_FLAGS) -o $@ $<

$(PACKAGE_DOMAIN)$(TARGET)_$(CURRENT_VERSION)_iphoneos-arm64.deb: $(PKG)/bin/control.tar.gz $(PKG)/bin/data.tar.lzma $(PKG)/bin/debian-binary
	( cd "$(PKG)/bin"; ar -cr "../../$@" 'debian-binary' 'control.tar.gz' 'data.tar.lzma'; )

$(PACKAGE_DOMAIN)$(TARGET)-dev_$(CURRENT_VERSION)_iphoneos-arm64.deb: $(PKG)/dev/control.tar.gz $(PKG)/dev/data.tar.lzma $(PKG)/dev/debian-binary
	( cd "$(PKG)/dev"; ar -cr "../../$@" 'debian-binary' 'control.tar.gz' 'data.tar.lzma'; )

$(PKG)/bin $(PKG)/dev $(PKG)/bin/data/var/jb/var/root/veneez_hook/lib $(PKG)/dev/data/var/jb/var/root/veneez_hook/lib $(PKG)/dev/data/usr/include:
	mkdir -p $@

$(PKG)/bin/control.tar.gz: $(PKG)/bin/control
	$(TAR) $(TAR_FLAGS) -czf $@ --format ustar -C $(PKG)/bin --exclude '.DS_Store' --exclude '._*' ./control

$(PKG)/dev/control.tar.gz: $(PKG)/dev/control
	$(TAR) $(TAR_FLAGS) -czf $@ --format ustar -C $(PKG)/dev --exclude '.DS_Store' --exclude '._*' ./control

$(PKG)/bin/data.tar.lzma: $(PKG)/bin/data/var/jb/var/root/veneez_hook/lib/$(TARGET).$(ABI_VERSION).dylib
	$(TAR) $(TAR_FLAGS) -c --lzma -f $@ --format ustar -C $(PKG)/bin/data --exclude '.DS_Store' --exclude '._*' ./

$(PKG)/dev/data.tar.lzma: $(PKG)/dev/data/var/jb/var/root/veneez_hook/lib/$(TARGET).dylib $(PKG)/dev/data/usr/include/$(TARGET).h $(PKG)/dev/data/usr/include/$(TARGET)_plugin.h
	$(TAR) $(TAR_FLAGS) -c --lzma -f $@ --format ustar -C $(PKG)/dev/data --exclude '.DS_Store' --exclude '._*' ./

$(PKG)/bin/debian-binary: | $(PKG)/bin
	echo '2.0' > $@

$(PKG)/dev/debian-binary: | $(PKG)/dev
	echo '2.0' > $@
	
$(PKG)/bin/control: | $(PKG)/bin
	( echo 'Package: $(TARGET)'; \
	  echo 'Name: libkrw'; \
	  echo 'Author: Siguza'; \
	  echo 'Maintainer: Siguza'; \
	  echo 'Architecture: iphoneos-arm64'; \
	  echo 'Version: $(CURRENT_VERSION)'; \
	  echo 'Priority: optional'; \
	  echo 'Section: Development'; \
	  echo 'Description: Nice kernel r/w API'; \
	  echo 'Homepage: https://github.com/Siguza/libkrw/'; \
	) > $@

$(PKG)/dev/control: | $(PKG)/dev
	( echo 'Package: $(TARGET)-dev'; \
	  echo 'Depends: $(TARGET)'; \
	  echo 'Name: libkrw-dev'; \
	  echo 'Author: Siguza'; \
	  echo 'Maintainer: Siguza'; \
	  echo 'Architecture: iphoneos-arm64'; \
	  echo 'Version: $(CURRENT_VERSION)'; \
	  echo 'Priority: optional'; \
	  echo 'Section: Development'; \
	  echo 'Description: $(TARGET) headers'; \
	  echo 'Homepage: https://github.com/Siguza/libkrw/'; \
	) > $@

$(PKG)/bin/data/var/jb/var/root/veneez_hook/lib/$(TARGET).$(ABI_VERSION).dylib: $(TARGET).$(ABI_VERSION).dylib | $(PKG)/bin/data/var/jb/var/root/veneez_hook/lib
	cp $< $@

$(PKG)/dev/data/var/jb/var/root/veneez_hook/lib/$(TARGET).dylib: | $(PKG)/dev/data/var/jb/var/root/veneez_hook/lib
	( cd "$(PKG)/dev/data/var/jb/var/root/veneez_hook/lib"; ln -sf $(TARGET).$(ABI_VERSION).dylib $(TARGET).dylib; )

$(PKG)/dev/data/usr/include/%.h: $(INC)/%.h | $(PKG)/dev/data/usr/include
	cp $< $@

$(PKG)/bin $(PKG)/dev $(PKG)/bin/data/var/jb/var/root/veneez_hook/lib $(PKG)/dev/data/var/jb/var/root/veneez_hook/lib $(PKG)/dev/data/usr/include:
	mkdir -p $@

clean:
	rm -f *.dylib *.deb
	rm -rf $(PKG)
	git checkout $(TARGET).tbd

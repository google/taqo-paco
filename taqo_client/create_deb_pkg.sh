#!/bin/bash

flutter clean && flutter build linux

PKG=taqosurvey
VER=1.0-1
ARCH=amd64
DEB=${PKG}_${VER}_${ARCH}

BUILD=build/linux
#DEBUG=${BUILD}/debug
RELEASE=${BUILD}/release
OUT=${BUILD}/${DEB}
rm -rf ${OUT}

mkdir -p ${OUT}/usr/local/taqo
cp -R ${RELEASE}/* ${OUT}/usr/local/taqo/

mkdir -p ${OUT}/usr/share/applications
touch ${OUT}/usr/share/applications/taqo_survey.desktop
cat > ${OUT}/usr/share/applications/taqo_survey.desktop <<- EOM
[Desktop Entry]
Name=Taqo Survey
Comment=Taqo user study survey app
Exec=taqo_survey
Terminal=false
Type=Application
#StartupNotify=true
Icon=/usr/local/taqo/data/flutter_assets/assets/paco256.png
Categories=GNOME;GTK;Utility;TextEditor;
#Actions=new-window
Keywords=Taqo;taqo;survey
#DBusActivatable=true

#[Desktop Action new-window]
#Name=New Window
#Exec=gedit --new-window
EOM

mkdir -p ${OUT}/DEBIAN
touch ${OUT}/DEBIAN/control
cat > ${OUT}/DEBIAN/control <<- EOM
Package: taqosurvey
Version: 1.0-1
Architecture: ${ARCH}
Maintainer: Bob Evans <bobevans@google.com>
Section: devel
Priority: optional
Homepage: https://pacoapp.com/
Description: Taqo survey app
EOM

touch ${OUT}/DEBIAN/postinst
chmod 0755 ${OUT}/DEBIAN/postinst
cat > ${OUT}/DEBIAN/postinst <<- EOM
#!/bin/bash
ln -s /usr/local/taqo/taqo_survey /usr/local/bin/
# Auto launch the app
mkdir -p /etc/xdg/autostart
cp /usr/share/applications/taqo_survey.desktop /etc/xdg/autostart/
EOM

dpkg-deb --build ${OUT}
lintian ${OUT}.deb

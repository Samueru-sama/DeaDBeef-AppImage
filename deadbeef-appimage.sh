#!/bin/sh

APP=deadbeef-devel
SITE="https://sourceforge.net/projects/deadbeef/files/travis/linux/master"

# Create folders
if [ -z "$APP" ]; then exit 1; fi
mkdir -p "./$APP/tmp" && cd "./$APP/tmp" || exit 1

# DOWNLOAD THE ARCHIVE
version=$(wget -q "$SITE" -O - | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u | grep "x86_64.tar.bz2")
wget $version -O download.tar.bz2
tar fx ./*tar* || exit 1
cd ..
mkdir -p "./$APP.AppDir/usr/bin" && mv --backup=t ./tmp/*/* "./$APP.AppDir/usr/bin"
cd ./$APP.AppDir || exit 1

# DESKTOP ENTRY AND ICON
DESKTOP="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/deadbeef.desktop.in"
ICON="https://raw.githubusercontent.com/DeaDBeeF-Player/deadbeef/master/icons/scalable/deadbeef.svg"
wget $DESKTOP -O ./$APP.desktop && wget $ICON -O ./deadbeef.svg && ln -s ./deadbeef.svg ./.DirIcon
sed -i 's/DeaDBeeF/DeaDBeeF Nightly/g' ./$APP.desktop

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
exec "$CURRENTDIR"/usr/bin/deadbeef "$@"
EOF
chmod a+x ./AppRun

# MAKE APPIMAGE
cd ..
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod a+x ./appimagetool

# Do the thing!
ARCH=x86_64 VERSION=$(./appimagetool -v | grep -o '[[:digit:]]*') ./appimagetool -s ./$APP.AppDir && 
ls ./*.AppImage || { echo "appimagetool failed to make the appimage"; exit 1; }
APPNAME=$(ls *AppImage)
APPVERSION=$(wget -q "$SITE" -O - | sed 's/"/ /g' | grep "files_date" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | head -1)
mv ./*AppImage ./"$APPVERSION"-"$APPNAME"
if [ -z "$APP" ]; then exit 1; fi # Being extra safe lol
mv ./*.AppImage .. && cd .. && rm -rf "./$APP"
echo "All Done!"

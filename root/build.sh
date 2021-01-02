#!/usr/bin/env bash
set -euo pipefail

VERSION=1.2.11
SOURCE_ARCHIVE_URL=https://github.com/arvidn/libtorrent/releases/download/v1.2.11/libtorrent-rasterbar-1.2.11.tar.gz
ROOT_DIR=/root-layer
DEB_DIR="${ROOT_DIR}/libtorrent-upgrade"
DOWNLOAD_DIR="${DEB_DIR}/download"
SOURCE_DIR="${DEB_DIR}/src"

echo "=== Installing build requirements ==="
apt-get update
apt-get build-dep --no-install-recommends --no-upgrade -y libtorrent-rasterbar9
apt-get install checkinstall wget

echo "=== Setting up directories ==="
rm -rf "${DEB_DIR}" "${DOWNLOAD_DIR}" "${SOURCE_DIR}"
mkdir "${DEB_DIR}"
mkdir "${DOWNLOAD_DIR}"
mkdir "${SOURCE_DIR}"

echo "=== Downloading and extracting libtorrent ${VERSION} source ==="
wget "${SOURCE_ARCHIVE_URL}" -P "${DOWNLOAD_DIR}"
tar xzf ${DOWNLOAD_DIR}/*.tar.* --strip-components=1 -C "${SOURCE_DIR}"

echo "=== Configuring libtorrent ==="
cd "${SOURCE_DIR}"

PY3_MAJOR_MINOR_VERSION=$(py3versions -v -d)
eval $(dpkg-architecture -s)

CONFIGURE_ARGS="--with-libiconv --with-boost-libdir=/usr/lib/${DEB_HOST_MULTIARCH} "
CONFIGURE_ARGS+=" --enable-python-binding"
CONFIGURE_ARGS+=" --with-boost-python=boost_python-py${PY3_MAJOR_MINOR_VERSION//./}"

CPPFLAGS="${CPPFLAGS:-} $(python${PY3_MAJOR_MINOR_VERSION}-config --includes)"
PYTHON_LDFLAGS="$(python${PY3_MAJOR_MINOR_VERSION}-config --libs)"
PYTHON=/usr/bin/python${PY3_MAJOR_MINOR_VERSION}
PYTHON_INSTALL_PARAMS="--install-layout=deb"

CPPFLAGS=${CPPFLAGS} \
    PYTHON_LDFLAGS=${PYTHON_LDFLAGS} \
    PYTHON=${PYTHON} \
    PYTHON_INSTALL_PARAMS=${PYTHON_INSTALL_PARAMS} \
    ./configure ${CONFIGURE_ARGS}

echo "=== Compiling libtorrent ==="
make -j $(nproc)

# `deluge` depends on `python3-libtorrent`, a virtual package pointing at `libtorrent-rasterbar9`.
# Replace `python3-libtorrent` and `libtorrent-rasterbar9` with a new concrete `python3-libtorrent` package containing
# the newly compiled libtorrent.

# Apply all but the `libtorrent-rasterbar9` dependency from the original `python3-libtorrent` package to the new one
NEW_DEPENDS=$(
    (dpkg-query -s python3-libtorrent 2>/dev/null || apt-cache show python3-libtorrent) \
    | grep '^Depends:' \
    | head -1 \
    | sed -e 's/^Depends: //' \
    | sed -e 's/, /,/g' \
    | sed -E -e 's/([()<>~])/\\\1/g' \
    | sed -E -e 's/libtorrent-rasterbar9[^,]*,?//')

checkinstall \
    --pkgname=python3-libtorrent \
    --pkgversion=${VERSION} \
    --pkgrelease=1 \
    --replaces=libtorrent-rasterbar9 \
    --conflicts=libtorrent-rasterbar9 \
    --requires="${NEW_DEPENDS}" \
    --nodoc \
    --install=no \
    --backup=no \
    --strip \
    --stripso \
    --pakdir="${DEB_DIR}" \
    -y

echo "=== Cleaning up source and download dirs ==="
rm -rf "${DOWNLOAD_DIR}"
rm -rf "${SOURCE_DIR}"

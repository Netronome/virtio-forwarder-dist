#!/bin/bash

#   BSD LICENSE
#
#   Copyright(c) 2016-2020 Netronome.
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions
#   are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#     * Neither the name of Netronome nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

while getopts :s opt; do
    case ${opt} in
      s)
        STATIC="-static"
        CONFLICTS_WITH="Conflicts: virtio-forwarder"
        MESON_STATIC="-Dstatic=true"
        ;;
    esac
done

STATIC=${STATIC:-""}
CONFLICTS_WITH=${CONFLICTS_WITH:-"Conflicts:"}
MESON_STATIC=${MESON_STATIC:-"-Dstatic=false"}
DEBUILD_DIR="virtio-forwarder$STATIC"

PKG_RELEASE=1
DATE_STR=$(date --rfc-2822)
DEBIAN_DISTRO=${DEBIAN_DISTRO:-"unstable"}

TMP_BUILD="${MESON_BUILD_ROOT}"/_build/virtio-forwarder

# Create scratch work directory
mkdir -p "${TMP_BUILD}"

# Copy source files from virtio-forwarder root directory to scratch area
cd "${MESON_SOURCE_ROOT}"
find . -maxdepth 1 -type f -regextype posix-extended \
                -regex '.*(LICENSE|README.rst|README.md|meson.build|\.(c|h|in|proto|txt))' \
                -exec cp "{}" "${TMP_BUILD}" \;

find scripts/ -maxdepth 1 -type f -regextype posix-extended \
                -regex '.*(meson.build|.*\.py)' \
                -exec cp --parents "{}" "${TMP_BUILD}" \;

cp --parents startup/virtioforwarder "${TMP_BUILD}"
cp --parents startup/systemd/*.service "${TMP_BUILD}"
cp --parents startup/systemd/meson* "${TMP_BUILD}"
cp -r doc/ "${TMP_BUILD}"

find startup/ -maxdepth 1 -type f -regextype posix-extended \
                -regex '.*(meson.build|.*\.sh)' \
                -exec cp --parents "{}" "${TMP_BUILD}" \;

# Grab the correct version string from vrelay_version.h
cd "${MESON_BUILD_ROOT}"/_build
VERSION_VER_STRING=$(awk '/VIRTIO_FWD_VERSION/&&/define/&&!/SHASH/{count++;if (count<4) printf "%s.", $3; else print $3}' \
    "${MESON_BUILD_ROOT}"/vrelay_version.h)

DEBUILD_DIR="${MESON_BUILD_ROOT}"/_build/virtio-forwarder"${STATIC}"-"${VERSION_VER_STRING}"

# Create a orig.tar.bz2 of the virtio-forwarder code
mv virtio-forwarder "${DEBUILD_DIR}"
tar cfjp virtio-forwarder"${STATIC}"_"${VERSION_VER_STRING}".orig.tar.bz2 \
    virtio-forwarder"${STATIC}"-"${VERSION_VER_STRING}"

# Grab the debian build files from the packaging repo
cp -rf "${MESON_SOURCE_ROOT}"/packaging/debian "${DEBUILD_DIR}"

# Populate versions
sed -ri "s/__VRELAY_VERSION__/${VERSION_VER_STRING}/" \
    "${DEBUILD_DIR}"/debian/changelog
sed -ri "s/__PKG_RELEASE__/${PKG_RELEASE}/" \
    "${DEBUILD_DIR}"/debian/changelog;

cd "${DEBUILD_DIR}"

# Make needed rules changes
sed -ri "s/__MESON_STATIC__/${MESON_STATIC}/g" ./debian/rules

# Make needed changelog changes
sed -ri "s/__DEBIAN_DIST__/${DEBIAN_DISTRO}/g" ./debian/changelog
sed -ri "s/__DATE__/${DATE_STR}/g" ./debian/changelog
sed -ri "s/__STATIC__/${STATIC}/g" ./debian/changelog

# Make needed control changes
sed -ri "s/__STATIC__/${STATIC}/g" ./debian/control
sed -ri "s/__CONFLICTS_WITH__/${CONFLICTS_WITH}/g" ./debian/control
# For static builds we don't need DPDK packages
if [ "${STATIC}" == "-static" ]; then
  sed -i "s/ dpdk,//" ./debian/control
  sed -i "/Recommends:/d" ./debian/control
fi

# Finally run debuild
debuild --rootcmd=fakeroot -e PATH -e CFLAGS -e V -us -uc

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

while getopts 'so:' opt; do
    case ${opt} in
      s)
        STATIC="-static"
        CONFLICTS_WITH="Conflicts: virtio-forwarder"
        MESON_STATIC="-Dstatic=true"
        ;;
      o)
        OUTDIR="$OPTARG"
        ;;
    esac
done

STATIC=${STATIC:-""}
CONFLICTS_WITH=${CONFLICTS_WITH:-""}
MESON_STATIC=${MESON_STATIC:-""}

PKG_RELEASE=1
DATE_STR=$(date +'%a %b %d %Y')
TMP_BUILD="${MESON_BUILD_ROOT}"/_build/virtio-forwarder
RPM_TOPDIR="${MESON_BUILD_ROOT}"/rpmbuild
RPM_SPEC="${RPM_TOPDIR}"/SPECS/virtio-forwarder.spec

# Create scratch work directory
mkdir -p "${TMP_BUILD}"

# Create rpmbuild directory structure
mkdir -p "${RPM_TOPDIR}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Copy source files from virtio-forwarder root directory to scratch area
cd "${MESON_SOURCE_ROOT}"
find . -maxdepth 1 -type f -regextype posix-extended \
                -regex '.*(LICENSE|README.rst|README.md|meson.build|\.(c|h|in|proto|txt|py))' \
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

# Populate spec file
cp "${MESON_SOURCE_ROOT}"/packaging/virtio-forwarder.spec.in \
    "${RPM_TOPDIR}"/SPECS/virtio-forwarder.spec
sed -ri "s/__VRELAY_VERSION__/${VERSION_VER_STRING}/g" \
    "${RPM_TOPDIR}"/SPECS/virtio-forwarder.spec
sed -ri "s/__PKG_RELEASE__/${PKG_RELEASE}/g" \
    "${RPM_TOPDIR}"/SPECS/virtio-forwarder.spec
sed -ri "s/__DATE__/${DATE_STR}/g" \
    "${RPM_TOPDIR}"/SPECS/virtio-forwarder.spec
sed -ri "s/__STATIC__/${STATIC}/g" \
    "${RPM_TOPDIR}"/SPECS/virtio-forwarder.spec
sed -ri "s/__CONFLICTS_WITH__/${CONFLICTS_WITH}/g" \
    "${RPM_TOPDIR}"/SPECS/virtio-forwarder.spec
sed -ri "s/__MESON_STATIC__/${MESON_STATIC}/g" \
    "${RPM_TOPDIR}"/SPECS/virtio-forwarder.spec

# Finally, generate a .tar.bz2
VIRTIO_FORWARDER_NAME=virtio-forwarder"${STATIC}"-"${VERSION_VER_STRING}"
VIRTIO_FORWARDER_BZ2="${VIRTIO_FORWARDER_NAME}"-"${PKG_RELEASE}".tar.bz2
mv virtio-forwarder/ "${VIRTIO_FORWARDER_NAME}"
tar cfjp "${RPM_TOPDIR}"/SOURCES/$VIRTIO_FORWARDER_BZ2 "${VIRTIO_FORWARDER_NAME}"

# Call rpmbuild
rpmbuild -ba -D "_topdir "${RPM_TOPDIR}"" "${RPM_SPEC}"

# Copy the final RPM to $outdir
if [ -z "$OUTDIR" ]
then
    echo 'Error: $OUTDIR is not defined'
    exit 1
else
    find "${RPM_TOPDIR}" -name "*.rpm" -exec cp {} "$OUTDIR" \;
fi

exit 0

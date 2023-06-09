#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# TODO Don't add packages to INCLUDED_PACKAGES if they are also set to be excluded
# shellcheck disable=SC2207
INCLUDED_PACKAGES=($(jq -r "[(.all.include | (.all, select(.\"$IMAGE_NAME\" != null).\"$IMAGE_NAME\")[]), \
    (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".include | (.all, select(.\"$IMAGE_NAME\" != null).\"$IMAGE_NAME\")[])] \
                             | sort | unique[]" /tmp/packages.json))
# shellcheck disable=SC2207
EXCLUDED_PACKAGES=($(jq -r "[(.all.exclude | (.all, select(.\"$IMAGE_NAME\" != null).\"$IMAGE_NAME\")[]), \
    (select(.\"$FEDORA_MAJOR_VERSION\" != null).\"$FEDORA_MAJOR_VERSION\".exclude | (.all, select(.\"$IMAGE_NAME\" != null).\"$IMAGE_NAME\")[])] \
                             | sort | unique[]" /tmp/packages.json))

if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    # shellcheck disable=SC2207
    EXCLUDED_PACKAGES=($(rpm -qa --queryformat='%{NAME} ' "${EXCLUDED_PACKAGES[@]}"))
fi

# shellcheck disable=SC2086
wget -P /tmp/rpms \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${RELEASE}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${RELEASE}.noarch.rpm

rpm-ostree install \
    /tmp/rpms/*.rpm \
    fedora-repos-archive \
    rpmdevtools

SELF_PKG_DIR=/tmp/self-packaged
for spec_file in "$SELF_PKG_DIR"/*.spec; do
    spectool --define "_topdir $SELF_PKG_DIR" --get-files --sourcedir "$spec_file"
    rpmbuild -ba --clean --define "_topdir $SELF_PKG_DIR" "$spec_file"
done
rpm-ostree uninstall rpmdevtools
for rpm_file in "$SELF_PKG_DIR"/RPMS/*/*.rpm; do
    INCLUDED_PACKAGES+=("$rpm_file")
done

if [ ${#EXCLUDED_PACKAGES[@]} -gt 0 ]; then
    rpm-ostree override remove "${EXCLUDED_PACKAGES[@]}"
fi

if [ ${#INCLUDED_PACKAGES[@]} -gt 0 ]; then
    rpm-ostree install "${INCLUDED_PACKAGES[@]}" --idempotent
fi

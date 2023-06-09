#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

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
    fedora-repos-archive

if [[ ${#INCLUDED_PACKAGES[@]} -gt 0 && ${#EXCLUDED_PACKAGES[@]} -eq 0 ]]; then
    rpm-ostree install "${INCLUDED_PACKAGES[@]}"

elif [[ ${#INCLUDED_PACKAGES[@]} -eq 0 && ${#EXCLUDED_PACKAGES[@]} -gt 0 ]]; then
    rpm-ostree override remove "${EXCLUDED_PACKAGES[@]}"

elif [[ ${#INCLUDED_PACKAGES[@]} -gt 0 && ${#EXCLUDED_PACKAGES[@]} -gt 0 ]]; then
    # shellcheck disable=SC2046
    rpm-ostree override remove "${EXCLUDED_PACKAGES[@]}" \
        $(printf -- "--install=%s " "${INCLUDED_PACKAGES[@]}")

else
    echo "No packages to install."

fi

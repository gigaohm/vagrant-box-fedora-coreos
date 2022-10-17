#!/bin/bash

set -e

if ! command -v jq >/dev/null 2>&1; then
    echo "You need to install jq"
    exit 1
fi

printf "\nDownloading JSON files\n\n"

stable=$(curl 'https://builds.coreos.fedoraproject.org/streams/stable.json' | \
jq \
'.architectures.x86_64.artifacts.metal.release,
.architectures.x86_64.artifacts.metal.formats.iso.disk.location,
.architectures.x86_64.artifacts.metal.formats.iso.disk.sha256,
.architectures.x86_64.artifacts.metal.formats.iso.disk.signature,
.metadata."last-modified"
')


{ read stable_release; read stable_location; read stable_sha256; read stable_signature ; } <<< $stable

#

printf "\nUpdating VARS files\n\n"
printf "STABLE:\n"
printf "iso_url = $stable_location
iso_checksum = $stable_sha256
release = $stable_release
os_name = \"fedora-coreos-stable\"" \
| tee stable.pkrvars.hcl

printf "\n\nVars file created\n"
#!/bin/bash

infile="$(dirname $0)/../config.ign.yml"
outfile="$(dirname $0)/../http/transpiled_config.ign"

if command -v podman >/dev/null 2>&1; then
    podman run -i --rm quay.io/coreos/butane:release --pretty --strict < $infile > $outfile
elif command -v docker >/dev/null 2>&1; then
    docker run -i --rm quay.io/coreos/butane:release --pretty --strict < $infile > $outfile
else
    echo "You need to install Podman or Docker!"
    exit 1
fi

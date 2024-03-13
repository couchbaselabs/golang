#!/bin/bash -e

# Extracts the value of the GOVERSION or GO_VERSION annotation from the
# "build" project of the current manifest, and maps it to a full Golang
# version as specified in the golang/versions directory.

# It expects to be run with cwd set to the top of a repo sync, or to
# have a path to the top of a repo sync passed as a single argument.

# It will find the "current manifest" either using the 'repo' tool (if
# there's a .repo dir) or else the 'xmllint' tools (if there's a
# manifest.xml). If neither tool works, die. If the manifest simply
# doesn't have such an annotation, returns "".

function annot_from_manifest {

    annot=$1

    # Try to extract the annotation using "repo" if available, otherwise
    # "xmllint" on "manifest.xml". If neither tool works, die!
    if test -d .repo && command -v repo > /dev/null; then
        DEP_VERSION=$(repo forall build -c 'echo $REPO__'${annot} 2> /dev/null)
    elif test -e manifest.xml && command -v xmllint > /dev/null; then
        # This version expects "manifest.xml" in the current directory, from
        # either a build-from-manifest source tarball or the Black Duck script
        # running "repo manifest -r".
        DEP_VERSION=$(xmllint \
            --xpath 'string(//project[@name="build"]/annotation[@name="'${annot}'"]/@value)' \
            manifest.xml)
    else
        echo "Couldn't use repo or xmllint - can't continue!" >&2
        exit 3
    fi

    echo ${DEP_VERSION}
}

# If a directory was specified as an argument, cd there first
[ -n "$1" ] && cd "$1"

# This is unfortunately spelled two different ways in different
# products' manifests (CBD-5117), and fixing that would be
# potentially disruptive, so just look for either. As far as I know
# no product uses *both* spellings, but if they do, "GOVERSION" will
# win.
GOVERSION=$(annot_from_manifest GOVERSION)
if [ -z "${GOVERSION}" ]; then
    GOVERSION=$(annot_from_manifest GO_VERSION)
fi

# If the manifest doesn't specify *anything*, do nothing.
[ -z "${GOVERSION}" ] && exit

# Ok, there's some GOVERSION specified. To ensure we don't break when
# building older product versions that aren't using the centralized
# Go version management, if GOVERSION is a fully-specified minor
# version (eg. "1.18.3"), just use it as-is.
if [[ ! ${GOVERSION} =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
    # Ok, GOVERSION is a major-only version (eg. "1.18"). Look up the
    # currently supported Go minor version from the 'golang' repository.
    # At this point we know the project has "opted in" to the
    # centralized Go version management, therefore it is an error if the
    # specified major version is not supported.
    GOVERFILE=golang/versions/${GOVERSION}.txt
    if [ ! -e "${GOVERFILE}" ]; then
        echo "Specified GOVERSION ${GOVERSION} is not supported!!" >&2
        exit 5
    fi
    GOVERSION=$(cat ${GOVERFILE})
fi

echo ${GOVERSION}

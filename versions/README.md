This directory contains files with the current "approved" major versions
of Golang, named eg. 1.18.txt, 1.19.txt, etc. The contents of each file
is the specific minor version taht should be used for all product builds
that wish to use that major version, eg. "1.18.5".

NOTES FOR "supported-newer-1.20" git branch:

This is for use (hopefully exclusively) in couchbase-server 7.1.6 / 7.2.3
builds, which are quick turnaround releases with a few targeted fixes.
It just so happened that SUPPORTED_NEWER was bumped to 1.21 between the
previous releases and those, which would result in a number of components
building with Go 1.21 which were on Go 1.20 in the previous release. That's
too significant a change for a quick patch release. So this branch exists
which has the newest versions, but still says SUPPORTED_NEWER is 1.20.

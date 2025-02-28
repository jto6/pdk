#!/bin/bash

##
# SCISERVER
#
# Copyright (C) 2021 Texas Instruments Incorporated - http://www.ti.com/
#
# This software is licensed under the  standard terms and conditions in the
# Texas Instruments  Incorporated Technology and Software Publicly Available
# Software License Agreement, a copy of which is included in the software
# download.
##

year=$(date +%Y)
month=$(date +%m)
dm_ver=""

# Specify major version name if an explicit non-empty VERSION is specified
VERSION=${3}
if [ -n "$VERSION" ]; then
	major_ver_name="${VERSION}"
else
	major_ver_name="v${year}.${month}"
fi

if [ ! -z "$WIN_GITPATH" ]; then
	git_cmd="$WIN_GITPATH/git.exe"

	if [ ! -x "$git_cmd" ]; then
		echo "WARNING: Git is not at indicated location $git_cmd"
	fi
else
	git_cmd="git"
fi

# Include an SCMVERSION if applicable. Make it short. If we are on a clean
# tree that matches the current tag, the string is blank. If the closest
# tag matches what we expect based on v$VERSION.$SUBVERSION.$PATCHVERSION,
# then don't bother including it. Abbreviate dirty as +.
if "$git_cmd" rev-parse --is-inside-work-tree 2>/dev/null >/dev/null; then
	"$git_cmd" fetch --depth=500
	git_ver=$("$git_cmd" describe --abbrev=5 --dirty | sed -e 's/-dirty$/+/g')
	makefile_ver="${major_ver_name}.${1}.${2}"
	git_ver="$(echo "$git_ver" | sed -s "s/^${makefile_ver}-//g")"
	if [ -n "$git_ver" ]; then
		git_ver="-${git_ver}"
	fi

	# Included dm_ver required for DM version api call. implementing for ease of debug
	# eg: PSDK.xx.xx.xx.xx-NN+ PSDK explains DM build on which repo, xx.xx.xx.xx explains
	# the latest tag, NN represents delta between tag and commit, Abbreviate dirty as +.
	dm_ver="$("$git_cmd" describe --match "REL.PSDK.*" --abbrev=5 --dirty | sed -e 's/-g.....//g' -e 's/-dirty$/+/g' | cut -c 5-)"
else
	git_ver=""
fi

# Override git version if an explicit non-empty SCISERVER_SCMVERSION is specified
SCISERVER_SCMVERSION=${4}
if [ -n "$SCISERVER_SCMVERSION" ]; then
	git_ver="-${SCISERVER_SCMVERSION}"
fi

# Strip away the leading 0 to avoid MISRA.TOKEN.OCTAL.INT
S1=$(printf %d $(echo $1 | sed 's/^0*//g'))
S2=$(printf %d $(echo $2 | sed 's/^0*//g'))

if [ ${#dm_ver} -gt 25 ]
then
	dm_ver=""
fi

cat << EOF
/**
 * SCISERVER Version Info
 *
 * Copyright (C) 2024-$year Texas Instruments Incorporated - http://www.ti.com/
 *
 * This software is licensed under the  standard terms and conditions in the
 * Texas Instruments  Incorporated Technology and Software Publicly Available
 * Software License Agreement, a copy of which is included in the software
 * download.
 *
 * NOTICE: This file is auto-generated based on version numbers passed in
 * Makefile. Never edit this file by hand.
 */

#ifndef INCLUDE_SCISERVER_VERSION_H
#define INCLUDE_SCISERVER_VERSION_H

#define SCISERVER_MAJOR_VERSION_NAME	"$major_ver_name"
#define SCISERVER_SUBVERSION	$S1
#define SCISERVER_PATCHVERSION	$S2
#define SCISERVER_SCMVERSION	"$git_ver"
#define SCISERVER_DMVERSION     "$dm_ver"

#endif /* INCLUDE_SCISERVER_VERSION_H */

EOF


# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

DESCRIPTION="Service files for sys-apps/systemd"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/systemd http://en.gentoo-wiki.com/wiki/Systemd"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+basic +desktop sysv"

RDEPEND=""
DEPEND=""

doservices() {
	insinto "${ROOT}"lib/systemd/system
	for i in "$@" ; do
		doins "$i"
	done
}

src_install() {
	if use basic; then
		doservices "${FILESDIR}"/services-basic/*
	fi

	if use desktop; then
		doservices "${FILESDIR}"/services-desktop/*
	fi

	if use sysv; then
		doservices "${FILESDIR}"/services-sysv/*
	fi
}

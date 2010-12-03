# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

DESCRIPTION="Service files for sys-apps/systemd"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/systemd http://en.gentoo-wiki.com/wiki/Systemd"
SRC_URI="basic? ( http://0pointer.de/public/systemd-units/sshd.service
	http://0pointer.de/public/systemd-units/sshd.socket
	http://0pointer.de/public/systemd-units/sshd@.service )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+basic +desktop server sysv"

RDEPEND=""
DEPEND=""

doservices() {
	insinto /lib/systemd/system
	for i in "$@" ; do
		doins "$i" || die "doservices failed"
	done
}

src_install() {
	if use basic; then
		doservices "${FILESDIR}"/services-basic/*
		doservices "${DISTDIR}/sshd.service"
		doservices "${DISTDIR}/sshd.socket"
		doservices "${DISTDIR}/sshd@.service"
	fi

	if use server; then
		doservices "${FILESDIR}"/services-server/*
	fi

	if use desktop; then
		doservices "${FILESDIR}"/services-desktop/*
	fi

	if use sysv; then
		doservices "${FILESDIR}"/services-sysv/*
	fi
}

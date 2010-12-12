# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3
inherit systemd

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

pkg_postinst() {
	elog "NetworkManager.service has been removed, because it is included"
	elog "upstream.  Emerge >=net-misc/networkmanager-0.8.2 if you use"
	elog "NetworkManager."
	elog
	elog "The gdm.service has been removed in favour of gdm@.service.  Please"
	elog "remove the stale symlinks 'display-manager.service' and"
	elog "'graphical.target.wants/gdm.service' under '/etc/systemd/system'"
	elog "if you had them enabled, and enable the new service file with"
	elog "    systemctl enable gdm@.service"
}

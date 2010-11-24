# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit autotools eutils linux-info pam

DESCRIPTION="Replacement for sysvinit with extensive usage of parallelization"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/systemd"
SRC_URI="http://www.freedesktop.org/software/systemd/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="audit gtk pam +tcpwrap sysv selinux"

RDEPEND="
	>=sys-apps/dbus-1.3.2[systemd]
	sys-libs/libcap
	>=sys-fs/udev-162[systemd]
	app-admin/tmpwatch
	audit? ( sys-process/audit )
	gtk? (	>=x11-libs/gtk+-2.20
			>=x11-libs/libnotify-0.7.0
			dev-libs/dbus-glib )
	tcpwrap? ( sys-apps/tcp-wrappers )
	pam? ( virtual/pam )
	selinux? ( sys-libs/libselinux )
	sys-apps/systemd-units
"
DEPEND="${RDEPEND}
	gtk? ( >=x11-libs/gtk+-2.20 >=dev-lang/vala-0.11 )
	>=sys-kernel/linux-headers-2.6.32
"

CONFIG_CHECK="AUTOFS4_FS CGROUPS DEVTMPFS ~FANOTIFY"

pkg_setup() {
	linux-info_pkg_setup
	enewgroup lock # used by var-lock.mount
}

src_prepare() {
	epatch "${FILESDIR}/no-gtk-no-vala.patch"
	eautoreconf
}

src_configure() {
	use prefix || local EPREFIX="${ROOT}"

	local myconf=

	if use sysv; then
		myconf="${myconf} --with-sysvinit-path=\"${EPREFIX}\"etc/init.d"
		myconf="${myconf} --with-sysvrcd-path=\"${EPREFIX}\"etc"
	else
		myconf="${myconf} --with-sysvinit-path= --with-sysvrcd-path="
	fi

	# econf sets localstatedir to /var/lib, but systemd expects /var
	econf --with-distro=gentoo \
		--with-rootdir="${EROOT}" \
		--localstatedir="${EPREFIX}"/var \
		$(use_enable audit) \
		$(use_enable gtk) \
		$(use_enable pam) \
		$(use_enable tcpwrap) \
		$(use_enable selinux) \
		${myconf}
}

src_install() {
	use prefix || local ED="${D}"

	emake DESTDIR="${D}" install || die "emake install failed"

	dodoc "${ED}/usr/share/doc/systemd"/* && \
	rm -r "${ED}/usr/share/doc/systemd/"

	cd ${ED}/usr/share/man/man8/
	for i in halt poweroff reboot runlevel shutdown telinit; do
		mv ${i}.8 systemd.${i}.8
	done
}

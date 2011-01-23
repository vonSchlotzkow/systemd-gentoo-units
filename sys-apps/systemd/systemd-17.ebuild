# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit linux-info pam

DESCRIPTION="systemd is a system and service manager for Linux"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/systemd"
SRC_URI="http://www.freedesktop.org/software/systemd/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="audit gtk pam +tcpwrap sysv selinux"

RDEPEND="
	>=sys-apps/dbus-1.4.0[systemd]
	sys-libs/libcap
	>=sys-fs/udev-163[systemd]
	audit? ( sys-process/audit )
	gtk? (	>=x11-libs/gtk+-2.20
			x11-libs/libnotify
			dev-libs/dbus-glib )
	tcpwrap? ( sys-apps/tcp-wrappers )
	pam? ( virtual/pam )
	selinux? ( sys-libs/libselinux )
	sys-apps/systemd-units
"
# vala-0.10.2 segfaults, hopefully 0.10.3 will be in-tree soon.
VALASLOT="0.10"
DEPEND="${RDEPEND}
	gtk? ( >=dev-lang/vala-0.10.3:$VALASLOT )
	>=sys-kernel/linux-headers-2.6.32
"

CONFIG_CHECK="AUTOFS4_FS CGROUPS DEVTMPFS ~FANOTIFY"

pkg_setup() {
	linux-info_pkg_setup
	enewgroup lock # used by var-lock.mount
	enewgroup tty 5 # used by mount-setup for /dev/pts
}

src_prepare() {
	epatch "${FILESDIR}"/0001-Revert-Revert-Revert-fsck-add-new-l-switch-to-fsck-m.patch

	# Force rebuild of .c files, necessary for gnome-ask-password-agent.c
	for i in src/*.vala; do
		touch "${i}"
	done
}

src_configure() {
	local myconf=

	if use sysv; then
		myconf="${myconf} --with-sysvinit-path=/etc/init.d --with-sysvrcd-path=/etc"
	else
		myconf="${myconf} --with-sysvinit-path= --with-sysvrcd-path="
	fi

	if use gtk; then
		export VALAC="$(type -p valac-$VALASLOT)"
	fi

	# econf sets localstatedir to /var/lib, but systemd expects /var, see
	# comment #73 on bug #318365
	econf --with-distro=gentoo \
		--with-rootdir= \
		--localstatedir=/var \
		$(use_enable audit) \
		$(use_enable gtk) \
		$(use_enable pam) \
		$(use_enable tcpwrap) \
		$(use_enable selinux) \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	dodoc "${D}/usr/share/doc/systemd"/* && \
		rm -r "${D}/usr/share/doc/systemd/"

	cd "${D}"/usr/share/man/man8/
	for i in halt poweroff reboot runlevel shutdown telinit; do
		mv ${i}.8 systemd.${i}.8
	done
}

check_mtab_is_symlink() {
	if test ! -L "${ROOT}"etc/mtab; then
		ewarn "${ROOT}etc/mtab must be a symlink to ${ROOT}proc/self/mounts!"
		ewarn "To correct that, execute"
		ewarn "    $ ln -sf '${ROOT}proc/self/mounts' '${ROOT}etc/mtab'"
	fi
}

pkg_postinst() {
	check_mtab_is_symlink

	# Inform user about extra configuration
	elog "You may need to perform some additional configuration for some"
	elog "programs to work, see the systemd manpages for loading modules and"
	elog "handling tmpfiles:"
	elog "    $ man modules-load.d"
	elog "    $ man tmpfiles.d"
}

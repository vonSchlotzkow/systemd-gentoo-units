# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit linux-info pam

DESCRIPTION="systemd is a system and service manager for Linux"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/systemd"
SRC_URI="http://www.freedesktop.org/software/systemd/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="audit gtk pam selinux sysv +tcpwrap"

COMMON_DEPEND=">=sys-apps/dbus-1.4.8-r1
	sys-libs/libcap
	>=sys-fs/udev-163[systemd]
	audit? ( sys-process/audit )
	gtk? (
		dev-libs/dbus-glib
		>=dev-libs/glib-2.26
		x11-libs/gtk+:2
		>=x11-libs/libnotify-0.7 )
	pam? ( virtual/pam )
	selinux? ( sys-libs/libselinux )
	tcpwrap? ( sys-apps/tcp-wrappers )
	>=sys-apps/util-linux-2.19"

# Vala-0.10 doesn't work with libnotify 0.7.1
VALASLOT="0.12"
MINKV="2.6.38"

RDEPEND="${COMMON_DEPEND}
	sys-apps/systemd-units"
DEPEND="${COMMON_DEPEND}
	gtk? ( dev-lang/vala:${VALASLOT} )
	>=sys-kernel/linux-headers-${MINKV}"

pkg_pretend() {
	local CONFIG_CHECK="AUTOFS4_FS CGROUPS DEVTMPFS ~FANOTIFY ~IPV6"
	linux-info_pkg_setup
	kernel_is -ge ${MINKV//./ } || die "Kernel version at least ${MINKV} required"
}

pkg_setup() {
	enewgroup lock # used by var-lock.mount
	enewgroup tty 5 # used by mount-setup for /dev/pts
}

src_prepare() {
	# Force the rebuild of .vala sources
	touch src/*.vala
}

src_configure() {
	local myconf="
		--with-distro=gentoo
		--with-rootdir=
		--localstatedir=/var
		$(use_enable audit)
		$(use_enable gtk)
		$(use_enable pam)
		$(use_enable selinux)
		$(use_enable tcpwrap)
	"

	if use sysv; then
		myconf="
			${myconf}
			--with-sysvinit-path=/etc/init.d
			--with-sysvrcd-path=/etc
		"
	else
		myconf="
			${myconf}
			--with-sysvinit-path=
			--with-sysvrcd-path=
		"
	fi

	if use gtk; then
		export VALAC="$(type -p valac-${VALASLOT})"
	fi

	econf ${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	dodoc "${D}"/usr/share/doc/systemd/* &&
		rm -r "${D}"/usr/share/doc/systemd

	cd "${D}"/usr/share/man/man8/
	for i in halt poweroff reboot runlevel shutdown telinit; do
		mv ${i}.8 systemd.${i}.8 || die
	done

	keepdir /run
}

check_mtab_is_symlink() {
	if test ! -L "${ROOT}"etc/mtab; then
		ewarn "${ROOT}etc/mtab must be a symlink to ${ROOT}proc/self/mounts!"
		ewarn "To correct that, execute"
		ewarn "    $ ln -sf '${ROOT}proc/self/mounts' '${ROOT}etc/mtab'"
	fi
}

systemd_machine_id_setup() {
	einfo "Setting up /etc/machine-id..."
	if ! "${ROOT}"bin/systemd-machine-id-setup; then
		ewarn "Setting up /etc/machine-id failed, to fix it please see"
		ewarn "  http://lists.freedesktop.org/archives/dbus/2011-March/014187.html"
	elif test ! -L "${ROOT}"var/lib/dbus/machine-id; then
		# This should be fixed in the dbus ebuild, but we warn about it here.
		ewarn "${ROOT}var/lib/dbus/machine-id ideally should be a symlink to"
		ewarn "${ROOT}etc/machine-id to make it clear that they have the same"
		ewarn "content."
	fi
}

check_var_run_is_symlink() {
	if test ! -L "${ROOT}"var/run; then
		einfo "${ROOT}var/run should be a symlink to ${ROOT}run. This is not"
		einfo "trivial to change, and there is no hurry as it is currently"
		einfo "bind-mounted at boot-time. You may be able to create the"
		einfo "symlink by lazily unmounting ${ROOT}var/run first."
	fi
}

pkg_postinst() {
	check_mtab_is_symlink
	systemd_machine_id_setup
	check_var_run_is_symlink

	# Inform user about extra configuration
	elog "You may need to perform some additional configuration for some"
	elog "programs to work, see the systemd manpages for loading modules and"
	elog "handling tmpfiles:"
	elog "    $ man modules-load.d"
	elog "    $ man tmpfiles.d"

	ewarn "This is a work-in-progress ebuild. You may brick your system. Have fun!"
}

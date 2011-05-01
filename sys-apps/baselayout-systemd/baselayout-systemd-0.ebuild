# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

DESCRIPTION="Standard system configuration files"
HOMEPAGE="http://0pointer.de/blog/projects/the-new-configuration-files.html"
SRC_URI=""
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

# guess: guess the configuration from existing file, from openrc, or by
# 	executing commands, in that order
IUSE="+guess"

DEPEND=""
RDEPEND="${DEPEND}"

parse_value() {
	local vname="$1"
	local fname="$2"
	local value

	test -e "${fname}" || return

	value="$(grep -i "^${vname}" "${fname}")"
	value="${value#*=}"
	value="${value#\"}"
	value="${value%\"}"
	value="${value#\'}"
	value="${value%\'}"

	echo -n "${value}"
}

claim-file() {
	local fname="$1"
	local bname="$(basename "${fname}")"

	if test -e "${fname}"; then
		cat "${fname}" >"${bname}"
	else
		return 1
	fi
}

etc-hostname() {
	claim-file /etc/hostname && return

	local hostname
	local fname=/etc/conf.d/hostname

	use guess || ewarn "/etc/hostname must be manually created"
	use guess || return

	if test -e "${fname}"; then
		echo "$(parse_value hostname "${fname}")" >hostname
	else
		echo "$(hostname)" >hostname
	fi

	einfo "guessed hostname: \"$(cat hostname)\""
}

print-if-nonempty-k-v-new-file() {
	print_if_nonempty_k_v_file="$1"
	test -e "$1" && rm "$1"
}

print-if-nonempty-k-v() {
	local str="$@"
	local key="${str%%=*}"
	local value="${str#*=}"

	test -n "${value}" &&
		echo "${key}=${value}" >>"${print_if_nonempty_k_v_file}"

	return 0
}

etc-vconsole.conf() {
	claim-file /etc/vconsole.conf && return

	use guess || return

	#local vc_unicode="`parse_value unicode /etc/rc.conf`"
	#local utf8="YES"
	local vc_font="`parse_value consolefont /etc/conf.d/consolefont`"
	local vc_font_map="`parse_value consoletranslation /etc/conf.d/consolefont`"
	local vc_font_unimap="`parse_value unicodemap /etc/conf.d/consolefont`"
	local vc_keymap="`parse_value keymap /etc/conf.d/keymaps`"
	local vc_keymap_toggle="`parse_value keymap_toggle /etc/vconsole.conf`"

	print-if-nonempty-k-v-new-file vconsole.conf
	print-if-nonempty-k-v KEYMAP="$vc_keymap"
	print-if-nonempty-k-v KEYMAP_TOGGLE="$vc_keymap_toggle"
	print-if-nonempty-k-v FONT="$vc_font"
	print-if-nonempty-k-v FONT_MAP="$vc_font_map"
	print-if-nonempty-k-v FONT_UNIMAP="$vc_font_unimap"
}

etc-locale.conf() {
	claim-file /etc/locale.conf && return

	use guess || return

	local fname=/etc/profile.env

	print-if-nonempty-k-v-new-file locale.conf
	for vn in LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY \
		LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT \
		LC_IDENTIFICATION; do
		print-if-nonempty-k-v ${vn}="$(parse_value "export $vn" "${fname}")"
	done
}

etc-os-release() {
	# VERSION and VERSION_ID can be unset for rolling releases
	print-if-nonempty-k-v-new-file os-release
	print-if-nonempty-k-v NAME=Gentoo
	print-if-nonempty-k-v ID=gentoo
	print-if-nonempty-k-v PRETTY_NAME=\"Gentoo Linux\"
	print-if-nonempty-k-v ANSI_COLOR="1;32"
}

src_unpack() {
	mkdir -p "${S}"
}

src_configure() {
	etc-hostname && einfo "hostname"
	etc-vconsole.conf && einfo "vconsole.conf"
	etc-locale.conf && einfo "locale.conf"
	etc-os-release && einfo "os-release"
}

src_install() {
	insinto /etc
	doins *
}

# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6
PYTHON_COMPAT=( python{2_7,3_4} )
GITHUB_USER=rpm-software-management

#inherit fedora-github eutils autotools python-r1 flag-o-matic perl-module versionator
inherit fedora-github autotools python-r1 eutils flag-o-matic versionator

DESCRIPTION="Red Hat Package Management Utils"
HOMEPAGE="http://www.rpm.org"
EGIT_SRC_URI=https://github.com/rpm-software-management/rpm


[ "${PV}" = 9999 ] || SRC_URI="http://rpm.org/releases/rpm-$(get_version_component_range 1-2).x/${P}.tar.bz2"

LICENSE="GPL-2 LGPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~x86-linux"

IUSE="nls python doc caps lua acl selinux fedora"

RDEPEND="
	!app-arch/rpm5
	>=sys-libs/db-4.5
	>=sys-libs/zlib-1.2.3-r1
	>=app-arch/bzip2-1.0.1
	>=dev-libs/popt-1.7
	>=app-crypt/gnupg-1.2
	dev-libs/elfutils
	virtual/libintl
	>=dev-lang/perl-5.8.8
	dev-libs/nss
	python? ( ${PYTHON_DEPS} )
	nls? ( virtual/libintl )
	lua? ( >=dev-lang/lua-5.1.0[deprecated] )
	acl? ( virtual/acl )
	caps? ( >=sys-libs/libcap-2.0 )
	selinux? ( sec-policy/selinux-rpm )
"

DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )
	doc? ( app-doc/doxygen )
"

REQUIRED_USE="
	python? ( ${PYTHON_REQUIRED_USE} )
"

src_prepare() {
	eapply_user
	epatch \
		"${FILESDIR}"/${PN}-4.11.0-autotools.patch \
		"${FILESDIR}"/${PN}-4.8.1-db-path.patch \
		"${FILESDIR}"/${PN}-9999-build.patch

	# fix #356769
	sed -i 's:%{_var}/tmp:/var/tmp:' macros.in || die "Fixing tmppath failed"
	# fix #492642
	sed -i 's:@__PYTHON@:/usr/bin/python2:' macros.in || die "Fixing %__python failed"

	eautoreconf

	# Prevent automake maintainer mode from kicking in (#450448).
	touch -r Makefile.am preinstall.am

	python_copy_sources
}

src_configure() {
	append-cppflags -I"${EPREFIX}/usr/include/nss" -I"${EPREFIX}/usr/include/nspr"
	python_foreach_impl run_in_build_dir econf \
	    $(usex fedora --with-vendor=redhat) \
		--without-selinux \
		--with-external-db \
		--with-crypto=nss \
		$(use_enable python) \
		$(use_with doc hackingdocs) \
		$(use_enable nls) \
		$(use_with lua) \
		$(use_with caps cap) \
		$(use_with acl)
}

src_compile() {
	python_foreach_impl run_in_build_dir make DESTDIR="${ED}"
}

src_install() {
	python_foreach_impl run_in_build_dir make install DESTDIR="${ED}"

	# remove la files
	prune_libtool_files --all

	mv "${ED}"/bin/rpm "${ED}"/usr/bin
	rmdir "${ED}"/bin
	# fix symlinks to /bin/rpm (#349840)
	for binary in rpmquery rpmverify;do
		ln -sf rpm "${ED}"/usr/bin/${binary}
	done

	use nls || rm -rf "${ED}"/usr/share/man/??

	keepdir /usr/src/rpm/{SRPMS,SPECS,SOURCES,RPMS,BUILD}

	dodoc CHANGES CREDITS README*
	if use doc; then
		pushd doc/hacking/html
		dohtml -p hacking -r .
		popd
		pushd doc/librpm/html
		dohtml -p librpm -r .
		popd
	fi

	# Fix perllocal.pod file collision
	fixlocalpod
}

pkg_postinst() {
	if [[ -f "${EROOT}"/var/lib/rpm/Packages ]] ; then
		einfo "RPM database found... Rebuilding database (may take a while)..."
		"${EROOT}"/usr/bin/rpmdb --rebuilddb --root="${EROOT}"
	else
		einfo "No RPM database found... Creating database..."
		"${EROOT}"/usr/bin/rpmdb --initdb --root="${EROOT}"
	fi
}

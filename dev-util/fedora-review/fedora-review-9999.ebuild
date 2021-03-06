# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6
PYTHON_COMPAT=( python2_7 )

inherit fedora-github distutils-r1
[ "${PV}" = 9999 ] && inherit git-r3

DESCRIPTION="Helper scripts for Fedora reviews"
HOMEPAGE="https://fedorahosted.org/FedoraReview/"
EGIT_REPO_URI="https://git.fedorahosted.org/git/FedoraReview"
[ "${PV}" = 9999 ] || SRC_URI="https://fedorahosted.org/releases/${PN:0:1}/${PN:1:1}/${PN}/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE=""

COMMON_DEPEND="
	${PYTHON_DEPS}
"
DEPEND="
	${COMMON_DEPEND}
"
RDEPEND="
	${COMMON_DEPEND}
	dev-python/requests[${PYTHON_USEDEP}]
"

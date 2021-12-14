pkgver=1.0
pkgrel=1
pkgname="php5-libs${_suffix}"
_pkgver_icu=64-1
_pkgver_gd=2.1.1
_icu_src_dir="icu/source"
_gd_src_dir="libgd-${_pkgver_gd}"
_old_libs="usr/lib/${pkgname}"
_with_gd=0
pkgdesc="php5 compat libraries (for php53 and php54 building)"
arch=('x86_64' 'i686')
depends=('gcc-libs' 'sh')
makedepends=('python')
#provides=("icu=${_pkgver_icu}")
source=(
    "https://github.com/unicode-org/icu/releases/download/release-${_pkgver_icu}/icu4c-${_pkgver_icu/-/_}-src.tgz"
)
if [ "$_with_gd" -eq 1 ]; then
    source+=("gd-vpx.patch")
    source+=("https://github.com/libgd/libgd/releases/download/gd-${_pkgver_gd}/libgd-${_pkgver_gd}.tar.xz")
    makedepends+=('fontconfig' 'libxpm' 'libwebp' 'libavif' 'libheif' 'libvpx')
fi

build() {
    # Build icu
    pushd "${_icu_src_dir}"
   ./configure --prefix="/${_old_libs}/icu-${_pkgver_icu}" \
       --sysconfdir="/${_old_libs}/icu-${_pkgver_icu}/etc" \
       --mandir="/${_old_libs}/icu-${_pkgver_icu}/share/man" \
       --sbindir="/${_old_libs}/icu-${_pkgver_icu}/bin" \
       --libdir="/${_old_libs}/icu-${_pkgver_icu}/lib" \
       --disable-rpath
       make
    echo "CURDIR: $(pwd)"
    popd

    if [ "$_with_gd" -eq 1 ]; then
        # Build gd lib
        pushd "${_gd_src_dir}"
        patch -p1 -i ../gd-vpx.patch
        CFLAGS+=' -Wdeprecated-declarations '
        ./bootstrap.sh
        ./configure \
            --prefix="/${_old_libs}/gd-${_pkgver_gd}" \
            --sysconfdir="/${_old_libs}/gd-${_pkgver_gd}/etc" \
            --mandir="/${_old_libs}/gd-${_pkgver_gd}/share/man" \
            --sbindir="/${_old_libs}/gd-${_pkgver_gd}/bin" \
            --libdir="/${_old_libs}/gd-${_pkgver_gd}/lib" \
            --includedir="/${_old_libs}/gd-${_pkgver_gd}/include" \
            --disable-rpath
        make
        popd
    fi
}

check() {
    pushd "${_icu_src_dir}"
    make -k check
    popd
    if [ "$_with_gd" -eq 1 ]; then
        pushd "${_gd_src_dir}"
        export XFAIL_TESTS=gdimagestringft/gdimagestringft_bbox
        TMP=$(mktemp -d) make check
        popd
    fi
}

package() {
    if [ "$_with_gd" -eq 1 ]; then
        pushd "${_gd_src_dir}"
        make DESTDIR="${pkgdir}" install
        make clean
        popd
    fi
    pushd "${_icu_src_dir}"
    make -j1 DESTDIR="${pkgdir}" install
    make clean
    rm -rf "${pkgdir}/share/man"
    popd
}
sha256sums=('92f1b7b9d51b396679c17f35a2112423361b8da3c1b9de00aa94fd768ae296e6')

pkgname=jappeos_software_center
pkgver=1.0.2
_tag=dev-v1.0.2
pkgrel=1
pkgdesc="A GUI app for installing software for JappeOS."
arch=('x86_64')
url="https://github.com/JappeOS/$pkgname"
license=('GPL-3.0')
depends=('glibc' 'gtk3' 'desktop-file-utils')
makedepends=('git' 'clang' 'cmake' 'ninja')
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/$_tag.tar.gz")
sha256sums=('SKIP')

build() {
  cd "$srcdir/$pkgname-$_tag"
  flutter build linux --release
}

package() {
  cd "$srcdir/$pkgname-$_tag/build/linux/x64/release/bundle"

  # Install to /opt
  install -dm755 "$pkgdir/opt/$pkgname"
  cp -r * "$pkgdir/opt/$pkgname"

  # Symlink executable to /usr/bin
  install -dm755 "$pkgdir/usr/bin"
  ln -s "/opt/$pkgname/$pkgname" "$pkgdir/usr/bin/$pkgname"

  # Install desktop entry
  install -Dm644 "$srcdir/$pkgname-$_tag/jappeos-software-center.desktop" \
    "$pkgdir/usr/share/applications/jappeos-software-center.desktop"
}
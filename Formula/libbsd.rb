class Libbsd < Formula
  desc "Utility functions from BSD systems"
  homepage "https://libbsd.freedesktop.org/"
  url "https://libbsd.freedesktop.org/releases/libbsd-0.10.0.tar.xz"
  sha256 "34b8adc726883d0e85b3118fa13605e179a62b31ba51f676136ecb2d0bc1a887"

  bottle do
    cellar :any_skip_relocation
    sha256 "68ac94cf2b7530dcb4b678402d37d7fce907cd628821d5b7549b644146947951" => :x86_64_linux
    sha256 "e944dcd9145222c2ebe019bbb0c5a819b1e5589b59e0d2f11838603e9b66a0c4" => :ppc64le_linux
  end

  depends_on :linux

  def install
    system "./configure",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match "strtonum", shell_output("nm #{lib/"libbsd.so"}")
  end
end

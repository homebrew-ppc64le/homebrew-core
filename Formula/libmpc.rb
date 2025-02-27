class Libmpc < Formula
  desc "C library for the arithmetic of high precision complex numbers"
  homepage "http://www.multiprecision.org/mpc/"
  url "https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz"
  sha256 "6985c538143c1208dcb1ac42cedad6ff52e267b47e5f970183a3e75125b43c2e"

  bottle do
    cellar :any
    sha256 "b9491bbc04d1e52dfb8311dc9aa0081fd3041cb6b2f6b59a4104d712d341979d" => :catalina
    sha256 "1cb3a09238830d45d64a87f520f06122d24a020403fac1800c831d15c605282e" => :mojave
    sha256 "3b28ec506ab53ef5f3163e87fb72ae735b7f91ee2fc20fe184cf1241481b72a5" => :high_sierra
    sha256 "18d620a1612bc51b1fbd1b3b62c9c73766b90549c746740c5a27d2ab1ec5ede7" => :sierra
    sha256 "6f19f936781dae0db248abdd84a72c3e25451c44379706bc3800760f0aa43888" => :el_capitan
    sha256 "b31648a86228a042aaa8e7d58faba7859059910a427f9ef4211b06bd9152f8c2" => :x86_64_linux
    sha256 "ea97bf8f3cb05ab0e51bc8d6c810c31d05351cbb208c6f6fd586241341264531" => :ppc64le_linux
  end

  depends_on "gmp"
  depends_on "mpfr"

  def install
    args = %W[
      --prefix=#{prefix}
      --disable-dependency-tracking
      --with-gmp=#{Formula["gmp"].opt_prefix}
      --with-mpfr=#{Formula["mpfr"].opt_prefix}
    ]

    system "./configure", *args
    system "make"
    system "make", "check"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <mpc.h>
      #include <assert.h>
      #include <math.h>

      int main() {
        mpc_t x;
        mpc_init2 (x, 256);
        mpc_set_d_d (x, 1., INFINITY, MPC_RNDNN);
        mpc_tanh (x, x, MPC_RNDNN);
        assert (mpfr_nan_p (mpc_realref (x)) && mpfr_nan_p (mpc_imagref (x)));
        mpc_clear (x);
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-L#{Formula["mpfr"].opt_lib}",
                   "-L#{Formula["gmp"].opt_lib}", "-lmpc", "-lmpfr",
                   "-lgmp", "-o", "test"
    system "./test"
  end
end

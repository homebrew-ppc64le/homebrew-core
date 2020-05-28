class Automake < Formula
  desc "Tool for generating GNU Standards-compliant Makefiles"
  homepage "https://www.gnu.org/software/automake/"
  url "https://ftp.gnu.org/gnu/automake/automake-1.16.2.tar.xz"
  mirror "https://ftpmirror.gnu.org/automake/automake-1.16.2.tar.xz"
  sha256 "ccc459de3d710e066ab9e12d2f119bd164a08c9341ca24ba22c9adaa179eedd0"

  bottle do
    cellar :any_skip_relocation
    sha256 "fe26d4df57481b6a7ca0a6915c37c53648c27ffb41926b3570c45f80fdd8888e" => :catalina
    sha256 "fe26d4df57481b6a7ca0a6915c37c53648c27ffb41926b3570c45f80fdd8888e" => :mojave
    sha256 "fe26d4df57481b6a7ca0a6915c37c53648c27ffb41926b3570c45f80fdd8888e" => :high_sierra
    sha256 "58010f1a4c69947d29d90b64c5accba7246f0e7b7507bcf57076ccdc1dc41a3d" => :x86_64_linux
    sha256 "9efb486a0dc9755fbf28135f48e30bf9516d5109c16454f12e8af427d25bb37b" => :ppc64le_linux
  end

  depends_on "autoconf"

  def install
    ENV["PERL"] = "/usr/bin/perl" if OS.mac?

    system "./configure", "--prefix=#{prefix}"
    system "make", "install"

    # Our aclocal must go first. See:
    # https://github.com/Homebrew/homebrew/issues/10618
    (share/"aclocal/dirlist").write <<~EOS
      #{HOMEBREW_PREFIX}/share/aclocal
      /usr/share/aclocal
    EOS
  end

  test do
    (testpath/"test.c").write <<~EOS
      int main() { return 0; }
    EOS
    (testpath/"configure.ac").write <<~EOS
      AC_INIT(test, 1.0)
      AM_INIT_AUTOMAKE
      AC_PROG_CC
      AC_CONFIG_FILES(Makefile)
      AC_OUTPUT
    EOS
    (testpath/"Makefile.am").write <<~EOS
      bin_PROGRAMS = test
      test_SOURCES = test.c
    EOS
    system bin/"aclocal"
    system bin/"automake", "--add-missing", "--foreign"
    system "autoconf"
    system "./configure"
    system "make"
    system "./test"
  end
end

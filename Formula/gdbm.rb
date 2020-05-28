class Gdbm < Formula
  desc "GNU database manager"
  homepage "https://www.gnu.org/software/gdbm/"
  url "https://ftp.gnu.org/gnu/gdbm/gdbm-1.18.1.tar.gz"
  mirror "https://ftpmirror.gnu.org/gdbm/gdbm-1.18.1.tar.gz"
  sha256 "86e613527e5dba544e73208f42b78b7c022d4fa5a6d5498bf18c8d6f745b91dc"

  bottle do
    rebuild 1
    sha256 "b20854a82cf1285c3be2c0890e45fa532bf2f5a9d9465694439c4a4c4310e528" => :catalina
    sha256 "2168d58856917ca996d12dedaa930643529c66046103fe55018afc51f2bc1fcb" => :mojave
    sha256 "ac688d571f9c00e09670440d67d2869a34dab0fb897ba0b183ed84fceffdbc9c" => :high_sierra
    sha256 "89d6db4fbffbe2184b4531faaebf0432a4b01e1ed92678ce6bd2f95c69dc9803" => :sierra
    sha256 "80fc4bdfef26e3df4c1f7390e1169d32935faa69f00888318bf0ed8321798aad" => :x86_64_linux
    sha256 "f5d2fa3a937b36543bcdff0124bcaf4505c91c85f3fa2907710e20b4c451ae93" => :ppc64le_linux
  end

  # Use --without-readline because readline detection is broken in 1.13
  # https://github.com/Homebrew/homebrew-core/pull/10903
  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --without-readline
      --prefix=#{prefix}
    ]

    args << "--enable-libgdbm-compat" unless OS.mac?

    # GDBM uses some non-standard GNU extensions,
    # enabled with -D_GNU_SOURCE.  See:
    #   https://patchwork.ozlabs.org/patch/771300/
    #   https://stackoverflow.com/questions/5582211
    #   https://www.gnu.org/software/automake/manual/html_node/Flag-Variables-Ordering.html
    #
    # Fix error: unknown type name 'blksize_t'
    args << "CPPFLAGS=-D_GNU_SOURCE" unless OS.mac? || build.bottle?

    system "./configure", *args
    system "make", "install"
  end

  test do
    pipe_output("#{bin}/gdbmtool --norc --newdb test", "store 1 2\nquit\n")
    assert_predicate testpath/"test", :exist?
    assert_match /2/, pipe_output("#{bin}/gdbmtool --norc test", "fetch 1\nquit\n")
  end
end

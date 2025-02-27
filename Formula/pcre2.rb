class Pcre2 < Formula
  desc "Perl compatible regular expressions library with a new API"
  homepage "https://www.pcre.org/"
  url "https://ftp.pcre.org/pub/pcre/pcre2-10.35.tar.bz2"
  sha256 "9ccba8e02b0ce78046cdfb52e5c177f0f445e421059e43becca4359c669d4613"
  head "svn://vcs.exim.org/pcre2/code/trunk"

  bottle do
    cellar :any
    sha256 "6a1e59a5db23d684f92d2bf695601d1b466f3e9d5407f704ba4679d885d13cef" => :catalina
    sha256 "d7be9b0193654484e40bc30dd330711cc1e72fa9bf29f854dd50458f6a827d1b" => :mojave
    sha256 "69c4fb400d19d1910df33376974b274362ed715ab7d67ee480b5211156174784" => :high_sierra
    sha256 "e91b8af68acd7073f19487e3479d131c36f140c8d6d7db7187238210aaf1436d" => :x86_64_linux
    sha256 "1566b6e2c7f201ae0e075963444e77eaf11f7edf512c355f8ad0f86c5b201c1f" => :ppc64le_linux
  end

  uses_from_macos "bzip2"
  uses_from_macos "zlib"

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--enable-pcre2-16",
                          "--enable-pcre2-32",
                          "--enable-pcre2grep-libz",
                          "--enable-pcre2grep-libbz2",
                          "--enable-jit"
    system "make"
    system "make", "install"
  end

  test do
    system bin/"pcre2grep", "regular expression", prefix/"README"
  end
end

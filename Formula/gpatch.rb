class Gpatch < Formula
  desc "Apply a diff file to an original"
  homepage "https://savannah.gnu.org/projects/patch/"
  url "https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz"
  mirror "https://ftpmirror.gnu.org/patch/patch-2.7.6.tar.xz"
  sha256 "ac610bda97abe0d9f6b7c963255a11dcb196c25e337c61f94e4778d632f1d8fd"

  bottle do
    cellar :any_skip_relocation
    sha256 "f539f83039bc989b16aac11becfaa933c6dc8088f6fa060a8e01e84ed0a61d77" => :catalina
    sha256 "c25bf27bae741a7ec1a16d19d449d28b4b4a2f225190f55badf86b64b0266f4d" => :mojave
    sha256 "418d7ea9c3948a5d70bdca202bd56e5554eef7f105fc25449f041331db7f4f96" => :high_sierra
    sha256 "81e0fb63928b01d60b9d7a1f0bdbf262679888556bd055fd02f4f57a70cb87ad" => :sierra
    sha256 "bd67af8b9c24fa785a2da2a1d3475305593dbc183331aed657313e4066de3259" => :el_capitan
    sha256 "70df1fb356ca7ccccd277110fcf467ea9fd0dc7337c93ad8ecd39848b081f95c" => :x86_64_linux
    sha256 "2df1ffcb6ea250752d5bb768446c4cb1e9d1a8459b00f936b2ed24acb360bc70" => :ppc64le_linux
  end

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    testfile = testpath/"test"
    testfile.write "homebrew\n"
    patch = <<~EOS
      1c1
      < homebrew
      ---
      > hello
    EOS
    pipe_output("#{bin}/patch #{testfile}", patch)
    assert_equal "hello", testfile.read.chomp
  end
end

class Ffms2 < Formula
  desc "Libav/ffmpeg based source library and Avisynth plugin"
  homepage "https://github.com/FFMS/ffms2"
  url "https://github.com/FFMS/ffms2/archive/2.23.tar.gz"
  mirror "https://deb.debian.org/debian/pool/main/f/ffms2/ffms2_2.23.orig.tar.gz"
  sha256 "b09b2aa2b1c6f87f94a0a0dd8284b3c791cbe77f0f3df57af99ddebcd15273ed"
  revision 3

  bottle do
    cellar :any
    sha256 "09986c3c0185b4947c078a755d52117b309b82fb271ced093f7a29c97a1d5c4b" => :catalina
    sha256 "52e80b7671459161fcd103e4330e2641fe3701560dc08ddb924b562066ae465a" => :mojave
    sha256 "a32ddc2efaf4ce050c2d3decc2bba75d94d40d26f11460a706b57eadb1ecea4f" => :high_sierra
    sha256 "e6102b5d0b319d6681e1392b70c4061cc396efcda1552fa951eabf8cfb2843b6" => :x86_64_linux
  end

  head do
    url "https://github.com/FFMS/ffms2.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "ffmpeg"

  resource "videosample" do
    url "https://samples.mplayerhq.hu/V-codecs/lm20.avi"
    sha256 "a0ab512c66d276fd3932aacdd6073f9734c7e246c8747c48bf5d9dd34ac8b392"
  end

  def install
    # For Mountain Lion
    ENV.libcxx

    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --enable-avresample
      --prefix=#{prefix}
    ]

    if build.head?
      system "./autogen.sh", *args
    else
      system "./configure", *args
    end

    system "make", "install"
  end

  test do
    # download small sample and check that the index was created
    resource("videosample").stage do
      system bin/"ffmsindex", "lm20.avi"
      assert_predicate Pathname.pwd/"lm20.avi.ffindex", :exist?
    end
  end
end

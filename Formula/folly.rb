class Folly < Formula
  desc "Collection of reusable C++ library artifacts developed at Facebook"
  homepage "https://github.com/facebook/folly"
  url "https://github.com/facebook/folly/archive/v2020.04.27.00.tar.gz"
  sha256 "212a9f680b16f7c742cddf7f51b180c592cb8df75d4037e737f85e1335c0ebcc"
  head "https://github.com/facebook/folly.git"

  bottle do
    cellar :any
    sha256 "53e0ff3632ec92e3e2666b2cd1987dd51d8b525617facf79301bf4f5106ac069" => :catalina
    sha256 "9ca2f87d120f325f5bd7185fe28f5d2ab4f2de9a2a4217f95695a57577b96a6a" => :mojave
    sha256 "063a79442e8a8a1078d99be25e74954f6213d07db9c3196bb9928e1b2851977a" => :high_sierra
    sha256 "0c6e97a6b68487a484b69b6e55b3ac4264e77b9cb8839240dae206f430905130" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "boost"
  depends_on "double-conversion"
  depends_on "fmt"
  depends_on "gflags"
  depends_on "glog"
  depends_on "libevent"
  depends_on "lz4"
  # https://github.com/facebook/folly/issues/966
  depends_on :macos => :high_sierra if OS.mac?

  depends_on "openssl@1.1"
  depends_on "snappy"
  depends_on "xz"
  depends_on "zstd"
  unless OS.mac?
    depends_on "jemalloc"
    depends_on "python"
  end

  def install
    mkdir "_build" do
      args = std_cmake_args
      args << "-DFOLLY_USE_JEMALLOC=#{OS.mac? ? "OFF" : "ON"}"

      system "cmake", "..", *args, "-DBUILD_SHARED_LIBS=ON", ("-DCMAKE_POSITION_INDEPENDENT_CODE=ON" unless OS.mac?)
      system "make"
      system "make", "install"

      system "make", "clean"
      system "cmake", "..", *args, "-DBUILD_SHARED_LIBS=OFF"
      system "make"
      lib.install "libfolly.a", "folly/libfollybenchmark.a"
    end
  end

  test do
    (testpath/"test.cc").write <<~EOS
      #include <folly/FBVector.h>
      int main() {
        folly::fbvector<int> numbers({0, 1, 2, 3});
        numbers.reserve(10);
        for (int i = 4; i < 10; i++) {
          numbers.push_back(i * 2);
        }
        assert(numbers[6] == 12);
        return 0;
      }
    EOS
    system ENV.cxx, "-std=c++14", "test.cc", "-I#{include}", "-L#{lib}",
                    "-lfolly", "-o", "test"
    system "./test"
  end
end

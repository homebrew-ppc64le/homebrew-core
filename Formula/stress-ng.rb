class StressNg < Formula
  desc "Stress test a computer system in various selectable ways"
  homepage "https://kernel.ubuntu.com/~cking/stress-ng/"
  url "https://kernel.ubuntu.com/~cking/tarballs/stress-ng/stress-ng-0.11.10.tar.xz"
  sha256 "110519ac10cc46cd99a29909543e74f6f58a95903bc8beae9d6553ca2dd48674"

  bottle do
    cellar :any_skip_relocation
    sha256 "d05badd86529778db39038c6a653bbd5499893bb4d5dc3e4a8b45c352b390983" => :catalina
    sha256 "d1388a88881ef24d18563640417dea348e7484ff97c766fc54c97049d9574dcf" => :mojave
    sha256 "7eb634f6ac243b8f4822b16506fb3bc83d467c7d4d122e62e04555f174983ab7" => :high_sierra
    sha256 "c0ceec3689d1501fe8db84e80a42307cb844ad72fb67f4b35ba6111d123afe14" => :x86_64_linux
  end

  depends_on :macos => :sierra if OS.mac?

  uses_from_macos "zlib"

  def install
    inreplace "Makefile", "/usr", prefix
    system "make"
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/stress-ng -c 1 -t 1 2>&1")
    assert_match "successful run completed", output
  end
end

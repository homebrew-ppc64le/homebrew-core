class Nushell < Formula
  desc "Modern shell for the GitHub era"
  homepage "https://www.nushell.sh"
  url "https://github.com/nushell/nushell/archive/0.14.0.tar.gz"
  sha256 "8084bb21433aa3598475470abf78e6653440b51db2f28392212eee00238c3346"
  head "https://github.com/nushell/nushell.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "b1bda110933fb1c80b1b092fa49b09154ceefb3a47e99d97044a22cdc3451b10" => :catalina
    sha256 "9160faa62890e36a81c9cb98165ddc4e289df7778c75a2edc208a141831f5a5a" => :mojave
    sha256 "73705ace10cba1e6cfc60a784020eefe1a28baab0b08f21306c85b23567cac65" => :high_sierra
    sha256 "c9e83052237d9d02cfba1ffe8f601e253259ed08693bbfb7e79e601e0791d6c3" => :x86_64_linux
  end

  depends_on "rust" => :build
  depends_on "openssl@1.1"

  uses_from_macos "zlib"

  unless OS.mac?
    depends_on "pkg-config" => :build
    depends_on "linuxbrew/xorg/libxcb"
    depends_on "linuxbrew/xorg/libx11"
  end

  def install
    system "cargo", "install", "--features", "stable", "--locked", "--root", prefix, "--path", "."
  end

  test do
    if OS.mac?
      assert_equal pipe_output("#{bin}/nu", 'echo \'{"foo":1, "bar":2}\' | from-json | get bar | echo $it'),
      "Welcome to Nushell #{version} (type 'help' for more info)\n~ \n❯ 2~ \n❯ "
    else
      assert_match "Welcome to Nushell #{version} (type 'help' for more info)\n",
      pipe_output("#{bin}/nu", 'echo \'{"foo":1, "bar":2}\' | from-json | get bar | echo $it')
    end
  end
end

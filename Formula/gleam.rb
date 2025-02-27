class Gleam < Formula
  desc "✨ A statically typed language for the Erlang VM"
  homepage "https://gleam.run"
  url "https://github.com/lpil/gleam/archive/v0.8.1.tar.gz"
  sha256 "bf6854e9aa352516436828a22628a4b7e17a8ed7c916e508a97b93b56212cd80"

  bottle do
    cellar :any_skip_relocation
    sha256 "6f89b0eb0c0541e7c4b4b551a4651ec115aa365dc9cfa76172a25eb69313d75c" => :catalina
    sha256 "dc9b6bfb0b6d42224d096db9593f11e0608ecdb4e2d43bab8580aa47cd7cb0b0" => :mojave
    sha256 "c0164ca9bf1a34f950cdc2de052d5796a3966eed6baf249606e5e48bd9fa411d" => :high_sierra
    sha256 "8e16201316d9caf43caf8d9473b9e44421aed908e5792cf567b7d18792317fb2" => :x86_64_linux
  end

  depends_on "rust" => :build
  depends_on "erlang"
  depends_on "rebar3"

  depends_on "pkg-config" => :build unless OS.mac?

  def install
    system "cargo", "install", "--locked", "--root", prefix, "--path", "."
  end

  test do
    Dir.chdir testpath
    system "#{bin}/gleam", "new", "test_project"
    Dir.chdir "test_project"
    system "rebar3", "eunit"
  end
end

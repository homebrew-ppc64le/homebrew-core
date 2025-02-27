class Flow < Formula
  desc "Static type checker for JavaScript"
  homepage "https://flowtype.org/"
  url "https://github.com/facebook/flow/archive/v0.125.1.tar.gz"
  sha256 "e74b1b1c177ed6389ab8aad546cd353e393e53fb964460476c92e0ea9b3079a1"
  head "https://github.com/facebook/flow.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "fe87f123df6b040aaa351099cebc696d337a3f2a6d4807b98edce4c8d48ee8ca" => :catalina
    sha256 "85ff81d19ca34654d06934c08db65e495372eb1a91f6e7e8f86b677328cc6131" => :mojave
    sha256 "ee93cd4eb419e9f7293c473a4e7557cccbfc48910b40913fc97a0c1577159ff0" => :high_sierra
    sha256 "9ea0a8aedd258ed15003753126c36770addd3288c5a53a54d344f24ade4171c0" => :x86_64_linux
  end

  depends_on "ocaml" => :build
  depends_on "opam" => :build
  unless OS.mac?
    depends_on "rsync" => :build
    depends_on "elfutils"
  end

  uses_from_macos "m4" => :build
  uses_from_macos "unzip" => :build

  def install
    system "make", "all-homebrew"

    bin.install "bin/flow"

    bash_completion.install "resources/shell/bash-completion" => "flow-completion.bash"
    zsh_completion.install_symlink bash_completion/"flow-completion.bash" => "_flow"
  end

  test do
    system "#{bin}/flow", "init", testpath
    (testpath/"test.js").write <<~EOS
      /* @flow */
      var x: string = 123;
    EOS
    expected = /Found 1 error/
    assert_match expected, shell_output("#{bin}/flow check #{testpath}", 2)
  end
end

class Flow < Formula
  desc "Static type checker for JavaScript"
  homepage "https://flowtype.org/"
  url "https://github.com/facebook/flow/archive/v0.123.0.tar.gz"
  sha256 "bdd748fc855474a2fba222985f8e41587957f9018597356df51b9bc51263dd3f"
  head "https://github.com/facebook/flow.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "23b534b57175d59104abba96bf60d87a5ffcb56667ae0482e72cba686165e038" => :catalina
    sha256 "f5eb333c3f72d6e47d6901f3b95e33ea3598d3250008824811185e5ed2f50bae" => :mojave
    sha256 "883ee2baa88ff39ca33226516acdb479733ca21f81c4f808d6942c5f5a18879e" => :high_sierra
    sha256 "cdba238ee1b9509a196291aecb0a660e3a857c66f99a3dfcfd4f5633cdd6a57b" => :x86_64_linux
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

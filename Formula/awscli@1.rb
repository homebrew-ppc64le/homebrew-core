class AwscliAT1 < Formula
  include Language::Python::Virtualenv

  desc "Official Amazon AWS command-line interface"
  homepage "https://aws.amazon.com/cli/"
  # awscli should only be updated every 10 releases on multiples of 10
  url "https://github.com/aws/aws-cli/archive/1.18.60.tar.gz"
  sha256 "0af0bf57f70b197a51a013569d84332b02e5ccd182a2d297ab46b688a0b0d9e0"

  bottle do
    cellar :any_skip_relocation
    sha256 "54c0fa9e28973e907726c6b7123139329fc84c602d7e3ea9d7960df94e73a7e5" => :catalina
    sha256 "473a2fb319e00776c2df367a86d7f0385ec6f6cbdcdd6d1f3d322a746b1275fa" => :mojave
    sha256 "95da6a211f7710e3025193dc9509ab98144a74e651888e0c693d58f969338132" => :high_sierra
    sha256 "b0dc4ef01fac5859aba65c93d26cf02f3e557bd4b2f55bd45d49835f2258c44d" => :x86_64_linux
  end

  keg_only :versioned_formula

  # Some AWS APIs require TLS1.2, which system Python doesn't have before High
  # Sierra
  depends_on "python@3.8"

  uses_from_macos "groff"

  def install
    venv = virtualenv_create(libexec, "python3")
    system libexec/"bin/pip", "install", "-v", "--no-binary", ":all:",
                              "--ignore-installed", buildpath
    system libexec/"bin/pip", "uninstall", "-y", "awscli"
    venv.pip_install_and_link buildpath
    pkgshare.install "awscli/examples"

    rm Dir["#{bin}/{aws.cmd,aws_bash_completer,aws_zsh_completer.sh}"]
    bash_completion.install "bin/aws_bash_completer"
    zsh_completion.install "bin/aws_zsh_completer.sh"
    (zsh_completion/"_aws").write <<~EOS
      #compdef aws
      _aws () {
        local e
        e=$(dirname ${funcsourcetrace[1]%:*})/aws_zsh_completer.sh
        if [[ -f $e ]]; then source $e; fi
      }
    EOS
  end

  def caveats
    <<~EOS
      The "examples" directory has been installed to:
        #{HOMEBREW_PREFIX}/share/awscli/examples
    EOS
  end

  test do
    assert_match "topics", shell_output("#{bin}/aws help")
  end
end

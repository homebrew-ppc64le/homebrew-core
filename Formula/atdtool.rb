class Atdtool < Formula
  include Language::Python::Virtualenv

  desc "Command-line interface for After the Deadline language checker"
  homepage "https://github.com/lpenz/atdtool"
  url "https://files.pythonhosted.org/packages/83/d1/55150f2dd9afda92e2f0dcb697d6f555f8b1f578f1df4d685371e8b81089/atdtool-1.3.3.tar.gz"
  sha256 "a83f50e7705c65e7ba5bc339f1a0624151bba9f7cdec7fb1460bb23e9a02dab9"
  revision OS.mac? ? 3 : 4

  bottle do
    cellar :any_skip_relocation
    sha256 "f02a78aa9dbb19e8ca8670a6890f3d51949d014e6890ba5039fd9695bc1f46ce" => :catalina
    sha256 "17b2ed63f8b4f8aa53e367572b53344fa3e6fa8569e5a9fb48f3a0d5257d04cc" => :mojave
    sha256 "0f301757a596e02344c15171a834557e19e4c4145fd440cd9e960b72993e459a" => :high_sierra
    sha256 "2acb86b3a89d8a9df54e4e0544bfd740d44d87679affc00fae9abc3cc21d56a1" => :x86_64_linux
  end

  depends_on "python@3.8"

  def install
    virtualenv_install_with_resources
  end

  test do
    system "#{bin}/atdtool", "--help"
  end
end

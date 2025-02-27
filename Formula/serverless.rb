require "language/node"

class Serverless < Formula
  desc "Build applications with serverless architectures"
  homepage "https://serverless.com"
  url "https://github.com/serverless/serverless/archive/v1.71.3.tar.gz"
  sha256 "a95c0b4fa1a52792b05402f1bcfc6440ebf0a394aa5c81895a45e4130b7241b0"

  bottle do
    cellar :any_skip_relocation
    sha256 "708246ca0d0a053dbd1f2024f3f118a3c2bd5c08109d91c61ae10dbc7a78637e" => :catalina
    sha256 "04e6eae83af9fb6bf8dbf8b334529f269a763350796abcc88589d6d5b48d32f1" => :mojave
    sha256 "f0565923a259c21c34e955c2195d6b8affa9aea43d4ecfea79fc3de0faa2ab07" => :high_sierra
    sha256 "fcd2151cd0b9c08f67edaa08b24b02b35bd0044a00dc9f322b3e12e1c41822f7" => :x86_64_linux
  end

  depends_on "node"
  depends_on "python" unless OS.mac?

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    (testpath/"serverless.yml").write <<~EOS
      service: homebrew-test
      provider:
        name: aws
        runtime: python3.6
        stage: dev
        region: eu-west-1
    EOS

    system("#{bin}/serverless config credentials --provider aws --key aa --secret xx")
    output = shell_output("#{bin}/serverless package")
    assert_match "Serverless: Packaging service...", output
  end
end

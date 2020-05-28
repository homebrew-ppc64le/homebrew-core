require "language/node"

class GatsbyCli < Formula
  desc "Gatsby command-line interface"
  homepage "https://www.gatsbyjs.org/docs/gatsby-cli/"
  url "https://registry.npmjs.org/gatsby-cli/-/gatsby-cli-2.12.34.tgz"
  sha256 "26de449f0c608b59b8f001011c47a9e1516e8e0ad70dc915683ac992eeb18ee1"

  bottle do
    cellar :any_skip_relocation
    sha256 "3dc54333520c687cddbf02c1517a0b64e171bcf0a86b07108e57567cb0a7869f" => :catalina
    sha256 "ab6be8db89294566fbc6aab7039f02bc86d49454ea72c0f17976c9e0d93b5db2" => :mojave
    sha256 "ec3618903b2c497b1702bd59918c580827a301057bc071270659185a720397c9" => :high_sierra
    sha256 "9b8237fd346d269cad1bb218fb536841f733dcf40bdc66303ec32baa3ac74901" => :x86_64_linux
  end

  depends_on "node"
  depends_on "linuxbrew/xorg/xorg" unless OS.mac?

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    return if Process.uid.zero?

    system bin/"gatsby", "new", "hello-world", "https://github.com/gatsbyjs/gatsby-starter-hello-world"
    assert_predicate testpath/"hello-world/package.json", :exist?, "package.json was not cloned"
  end
end

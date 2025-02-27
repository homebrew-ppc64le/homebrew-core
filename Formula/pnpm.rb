class Pnpm < Formula
  require "language/node"

  desc "📦🚀 Fast, disk space efficient package manager"
  homepage "https://pnpm.js.org"
  url "https://registry.npmjs.org/pnpm/-/pnpm-4.14.4.tgz"
  sha256 "d9ace242533036659a9696bd64c6f3849e64143471ad6921872be1d026741b10"

  bottle do
    cellar :any_skip_relocation
    sha256 "3d6a38c5fb0d636fb8790c5eec2dc584498c8f01ec19d49e60e69b91c814b125" => :catalina
    sha256 "32fff357a7a8a6f7e7eacd682f8c99ec2beb2b3cabe491b9de569d26e3d4a4a1" => :mojave
    sha256 "71d169da0853da6a56f6cbd56ece0cf3ab6013bba1c31f5e202fa980b6b1d849" => :high_sierra
    sha256 "7a486342a9bb91a4e5928ba7271cff5e85c4f7b83729734a659a1f39d7a362bc" => :x86_64_linux
  end

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    system "#{bin}/pnpm", "init", "-y"
    assert_predicate testpath/"package.json", :exist?, "package.json must exist"
  end
end

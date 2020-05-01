class Rcm < Formula
  desc "RC file (dotfile) management"
  homepage "https://thoughtbot.github.io/rcm/rcm.7.html"
  url "https://thoughtbot.github.io/rcm/dist/rcm-1.3.3.tar.gz"
  sha256 "935524456f2291afa36ef815e68f1ab4a37a4ed6f0f144b7de7fb270733e13af"

  bottle do
    cellar :any_skip_relocation
    sha256 "3fdc7266d9faa6015ef560254f036cc355445ee12861cb17a1c0bf5cc218b368" => :catalina
    sha256 "3fdc7266d9faa6015ef560254f036cc355445ee12861cb17a1c0bf5cc218b368" => :mojave
    sha256 "3fdc7266d9faa6015ef560254f036cc355445ee12861cb17a1c0bf5cc218b368" => :high_sierra
    sha256 "2817bdd9ee36f5f321ac6b82e4d040d6e9bae08d8e7212b15555a31b432010cc" => :x86_64_linux
  end

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/".gitconfig").write <<~EOS
      [user]
      	name = Test User
      	email = test@test.com
    EOS
    assert_match /[Moving|Linking].../x, shell_output("#{bin}/mkrc -v ~/.gitconfig")
  end
end

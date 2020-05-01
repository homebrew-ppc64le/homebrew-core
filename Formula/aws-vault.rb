class AwsVault < Formula
  desc "Securely store and access AWS credentials in development environments"
  homepage "https://github.com/99designs/aws-vault"
  url "https://github.com/99designs/aws-vault/archive/v5.4.1.tar.gz"
  sha256 "a773ef8826e261c4046c41c0ff3b266d78f784cc4a8b0ede003fe2d0e648bdd0"

  bottle do
    cellar :any_skip_relocation
    sha256 "d1df76346bf805f0df5a1984f748822c7500c6458dd50de5e8c86ff8c3bed57e" => :x86_64_linux
  end

  depends_on "go" => :build
  depends_on :linux

  def install
    ENV["GOOS"] = "linux"
    ENV["GOARCH"] = "amd64"

    flags = "-X main.Version=#{version} -s -w"

    system "go", "build", "-ldflags=#{flags}"
    bin.install "aws-vault"

    zsh_completion.install "completions/zsh/_aws-vault"
    bash_completion.install "completions/bash/aws-vault"
  end

  test do
    assert_match("aws-vault: error: required argument 'profile' not provided, try --help",
      shell_output("#{bin}/aws-vault login 2>&1", 1))
  end
end

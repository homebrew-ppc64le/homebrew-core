class Crc < Formula
  desc "OpenShift 4 cluster on your local machine"
  homepage "https://code-ready.github.io/crc/"
  url "https://github.com/code-ready/crc.git",
      :tag      => "1.9.0",
      :revision => "a68b5e05157a3a1c2a2b95e3900bffa7435c3343"
  head "https://github.com/code-ready/crc.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "5d5ea105fcf3eb8eaa51b7406315e75cabae5818a8b1e6ff10c5ad60d3a19e3a" => :catalina
    sha256 "debc9c3add86f3310e791cbf8845e865aa6873ae8c34db4bd3a07363ba6e2655" => :mojave
    sha256 "6197d7e12e8bcbed963a73f921feb3ff685be93bde7ce82e3a3ee9b0ac590ce4" => :high_sierra
    sha256 "d25f7aa840b2a4492e5756ce578a420e245c09060e758dbc5d057b63624164a0" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    os = OS.mac? ? "macos" : "linux"
    system "make", "out/#{os}-amd64/crc"
    bin.install "out/#{os}-amd64/crc"
  end

  test do
    assert_match /^crc version: #{version}/, shell_output("#{bin}/crc version")

    # Should error out as running crc requires root
    status_output = shell_output("#{bin}/crc setup 2>&1", 1)
    if Process.uid.zero?
      assert_match "crc should be ran as a normal user", status_output
    else
      assert_match "Unable to set ownership", status_output
    end
  end
end

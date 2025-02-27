class Tokei < Formula
  desc "Program that allows you to count code, quickly"
  homepage "https://github.com/XAMPPRocky/tokei"
  url "https://github.com/XAMPPRocky/tokei/archive/v11.2.0.tar.gz"
  sha256 "13f6753655c6b4b0b6d5d2208154647609fd3a16ce2a13f414cf0f6c01752e55"

  bottle do
    cellar :any_skip_relocation
    sha256 "ea39f045396a61ae07444a7dc95912567a8313598ae75f098a7a983e5c799f90" => :catalina
    sha256 "38559400167c41ee51d5a995a21d1cf37b6592e7f92a672edc6f299a7d83957a" => :mojave
    sha256 "6cb69ce91d38373bdcae3427f61b12e251f70bb4eb2e45be9f2b5b8cffdcb279" => :high_sierra
    sha256 "dc36e879365c409b260eef5a23060c7710a7a79dd16931ac0aebb7765cf5dff2" => :x86_64_linux
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", "--locked", "--root", prefix, "--path", ".",
                               "--features", "all"
  end

  test do
    (testpath/"lib.rs").write <<~EOS
      #[cfg(test)]
      mod tests {
          #[test]
          fn test() {
              println!("It works!");
          }
      }
    EOS
    system bin/"tokei", "lib.rs"
  end
end

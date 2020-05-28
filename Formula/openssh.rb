class Openssh < Formula
  desc "OpenBSD freely-licensed SSH connectivity tools"
  homepage "https://www.openssh.com/"
  url "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.2p1.tar.gz"
  mirror "https://mirror.vdms.io/pub/OpenBSD/OpenSSH/portable/openssh-8.2p1.tar.gz"
  version "8.2p1"
  sha256 "43925151e6cf6cee1450190c0e9af4dc36b41c12737619edff8bcebdff64e671"
  revision 1

  bottle do
    sha256 "e1fed635b6186348398bab423cad7526553098aeca633c7f8e4cb5cef6ce8339" => :catalina
    sha256 "4993404b540da5831d8ba8abfe6b3b17db683f428bd616b1ce7a1f7876aec68b" => :mojave
    sha256 "014fecadf9d869036d63e8b52d9c9c11fe30697e2a38dee793420d41991d558b" => :high_sierra
    sha256 "b88f722fb7202517466119cd1ac071495c0dd3b1f4d4291d42b0ceccb1e51c2b" => :x86_64_linux
  end

  # Please don't resubmit the keychain patch option. It will never be accepted.
  # https://archive.is/hSB6d#10%25

  depends_on "pkg-config" => :build
  depends_on "ldns"
  depends_on "libfido2"
  depends_on "openssl@1.1"

  unless OS.mac?
    depends_on "libedit"
    depends_on "krb5"
    depends_on "zlib"
    depends_on "lsof" => :test
  end

  resource "com.openssh.sshd.sb" do
    url "https://opensource.apple.com/source/OpenSSH/OpenSSH-209.50.1/com.openssh.sshd.sb"
    sha256 "a273f86360ea5da3910cfa4c118be931d10904267605cdd4b2055ced3a829774"
  end

  # Both these patches are applied by Apple.
  if OS.mac?
    patch do
      url "https://raw.githubusercontent.com/Homebrew/patches/1860b0a745f1fe726900974845d1b0dd3c3398d6/openssh/patch-sandbox-darwin.c-apple-sandbox-named-external.diff"
      sha256 "d886b98f99fd27e3157b02b5b57f3fb49f43fd33806195970d4567f12be66e71"
    end

    patch do
      url "https://raw.githubusercontent.com/Homebrew/patches/d8b2d8c2612fd251ac6de17bf0cc5174c3aab94c/openssh/patch-sshd.c-apple-sandbox-named-external.diff"
      sha256 "3505c58bf1e584c8af92d916fe5f3f1899a6b15cc64a00ddece1dc0874b2f78f"
    end
  end

  def install
    ENV.append "CPPFLAGS", "-D__APPLE_SANDBOX_NAMED_EXTERNAL__" if OS.mac?

    # Ensure sandbox profile prefix is correct.
    # We introduce this issue with patching, it's not an upstream bug.
    inreplace "sandbox-darwin.c", "@PREFIX@/share/openssh", etc/"ssh" if OS.mac?

    args = %W[
      --prefix=#{prefix}
      --sysconfdir=#{etc}/ssh
      --with-ldns
      --with-libedit
      --with-kerberos5
      --with-ssl-dir=#{Formula["openssl@1.1"].opt_prefix}
      --with-security-key-builtin
    ]

    args << "--with-pam" if OS.mac?
    args << "--with-privsep-path=#{var}/lib/sshd" unless OS.mac?

    system "./configure", *args
    system "make"
    ENV.deparallelize
    system "make", "install"

    # This was removed by upstream with very little announcement and has
    # potential to break scripts, so recreate it for now.
    # Debian have done the same thing.
    bin.install_symlink bin/"ssh" => "slogin"

    buildpath.install resource("com.openssh.sshd.sb")
    (etc/"ssh").install "com.openssh.sshd.sb" => "org.openssh.sshd.sb"
  end

  test do
    if ENV["CI"]
      # Fixes "Starting sshd: Privilege separation user sshd does not exist FAILED" in docker
      system "groupadd", "-g", "133", "sshd"
      system "useradd", "-u", "133", "-g", "133", "-c", "sshd", "-d", "/", "sshd"
    end

    assert_match "OpenSSH_", shell_output("#{bin}/ssh -V 2>&1")

    port = free_port
    begin
      pid = fork { exec sbin/"sshd", "-D", "-p", port.to_s }
      sleep 2
      assert_match "sshd", shell_output("lsof -i :#{port}")
    ensure
      Process.kill(9, pid)
      Process.wait(pid)
    end
  end
end

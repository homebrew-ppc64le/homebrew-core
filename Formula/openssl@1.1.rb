class OpensslAT11 < Formula
  desc "Cryptography and SSL/TLS Toolkit"
  homepage "https://openssl.org/"
  url "https://www.openssl.org/source/openssl-1.1.1f.tar.gz"
  mirror "https://dl.bintray.com/homebrew/mirror/openssl@1.1--1.1.1f.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.openssl.org/source/openssl-1.1.1f.tar.gz"
  sha256 "186c6bfe6ecfba7a5b48c47f8a1673d0f3b0e5ba2e25602dd23b629975da3f35"
  version_scheme 1

  bottle do
    sha256 "724cd97c269952cdc28e24798e350fcf520a32c5985aeb26053ce006a09d8179" => :catalina
    sha256 "25ab844d2f14fc85c7f52958b4b89bdd2965bbd9c557445829eff6473f238744" => :mojave
    sha256 "27f26e2442222ac0565193fe0b86d8719559d776bcdd070d6113c16bb13accf6" => :high_sierra
    sha256 "08346b05efb1da0432ec1e9b197c920ff110aa7eb3fd49bd603603c6f10d6273" => :x86_64_linux
  end

  keg_only :shadowed_by_macos, "macOS provides LibreSSL"

  unless OS.mac?
    resource "cacert" do
      # homepage "http://curl.haxx.se/docs/caextract.html"
      url "https://curl.haxx.se/ca/cacert-2020-01-01.pem"
      mirror "https://gist.githubusercontent.com/dawidd6/16d94180a019f31fd31bc679365387bc/raw/ef02c78b9d6427585d756528964d18a2b9e318f7/cacert-2020-01-01.pem"
      sha256 "adf770dfd574a0d6026bfaa270cb6879b063957177a991d453ff1d302c02081f"
    end
  end

  # SSLv2 died with 1.1.0, so no-ssl2 no longer required.
  # SSLv3 & zlib are off by default with 1.1.0 but this may not
  # be obvious to everyone, so explicitly state it for now to
  # help debug inevitable breakage.
  def configure_args
    %W[
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      no-ssl3
      no-ssl3-method
      no-zlib
      #{[ENV.cppflags, ENV.cflags, ENV.ldflags].join(" ").strip unless OS.mac?}
      #{"enable-md2" unless OS.mac?}
    ]
  end

  def install
    # This could interfere with how we expect OpenSSL to build.
    ENV.delete("OPENSSL_LOCAL_CONFIG_DIR")

    # This ensures where Homebrew's Perl is needed the Cellar path isn't
    # hardcoded into OpenSSL's scripts, causing them to break every Perl update.
    # Whilst our env points to opt_bin, by default OpenSSL resolves the symlink.
    ENV["PERL"] = Formula["perl"].opt_bin/"perl" if which("perl") == Formula["perl"].opt_bin/"perl"

    if OS.mac?
      arch_args = %w[darwin64-x86_64-cc enable-ec_nistp_64_gcc_128]
    else
      arch_args = []
      if Hardware::CPU.intel?
        arch_args << (Hardware::CPU.is_64_bit? ? "linux-x86_64" : "linux-elf")
      elsif Hardware::CPU.arm?
        arch_args << (Hardware::CPU.is_64_bit? ? "linux-aarch64" : "linux-armv4")
      elsif Hardware::CPU.ppc64le?
        arch_args << "linux-ppc64le"
      end
    end

    ENV.deparallelize
    system "perl", "./Configure", *(configure_args + arch_args)
    system "make"
    system "make", "test" if OS.mac?
    system "make", "install", "MANDIR=#{man}", "MANSUFFIX=ssl"
    # See https://github.com/Linuxbrew/homebrew-core/pull/8891
    system "make", "test" unless OS.mac?
  end

  def openssldir
    etc/"openssl@1.1"
  end

  def post_install
    unless OS.mac?
      # Download and install cacert.pem from curl.haxx.se
      cacert = resource("cacert")
      cacert.fetch
      rm_f openssldir/"cert.pem"
      filename = Pathname.new(cacert.url).basename
      openssldir.install cacert.files(filename => "cert.pem")
      return
    end

    keychains = %w[
      /System/Library/Keychains/SystemRootCertificates.keychain
    ]

    certs_list = `security find-certificate -a -p #{keychains.join(" ")}`
    certs = certs_list.scan(
      /-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m,
    )

    valid_certs = certs.select do |cert|
      IO.popen("#{bin}/openssl x509 -inform pem -checkend 0 -noout >/dev/null", "w") do |openssl_io|
        openssl_io.write(cert)
        openssl_io.close_write
      end

      $CHILD_STATUS.success?
    end

    openssldir.mkpath
    (openssldir/"cert.pem").atomic_write(valid_certs.join("\n") << "\n")
  end

  def caveats
    <<~EOS
      A CA file has been bootstrapped using certificates from the system
      keychain. To add additional certificates, place .pem files in
        #{openssldir}/certs

      and run
        #{opt_bin}/c_rehash
    EOS
  end

  test do
    # Make sure the necessary .cnf file exists, otherwise OpenSSL gets moody.
    assert_predicate HOMEBREW_PREFIX/"etc/openssl@1.1/openssl.cnf", :exist?,
            "OpenSSL requires the .cnf file for some functionality"

    # Check OpenSSL itself functions as expected.
    (testpath/"testfile.txt").write("This is a test file")
    expected_checksum = "e2d0fe1585a63ec6009c8016ff8dda8b17719a637405a4e23c0ff81339148249"
    system bin/"openssl", "dgst", "-sha256", "-out", "checksum.txt", "testfile.txt"
    open("checksum.txt") do |f|
      checksum = f.read(100).split("=").last.strip
      assert_equal checksum, expected_checksum
    end
  end
end

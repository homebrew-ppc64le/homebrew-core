class Systemd < Formula
  desc "System and service manager"
  homepage "https://wiki.freedesktop.org/www/Software/systemd/"
  url "https://github.com/systemd/systemd/archive/v244.tar.gz"
  sha256 "2207ceece44108a04bdd5459aa74413d765a829848109da6f5f836c25aa393aa"
  revision 3
  head "https://github.com/systemd/systemd.git"

  bottle do
    sha256 "ae26fdbe001f77a7b3c5f764bd7ad1571073ab5b0ba6743596e2438d92348f57" => :x86_64_linux
  end

  depends_on "coreutils" => :build
  depends_on "docbook-xsl" => :build
  depends_on "gettext" => :build
  depends_on "gperf" => :build
  depends_on "intltool" => :build
  depends_on "libgpg-error" => :build
  depends_on "libtool" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "libcap"
  depends_on :linux
  depends_on "lz4"
  depends_on "openssl@1.1"
  depends_on "util-linux" # for libmount
  depends_on "xz"

  uses_from_macos "libxslt" => :build
  uses_from_macos "m4" => :build
  uses_from_macos "expat"

  def install
    Language::Python.rewrite_python_shebang(Formula["python@3.8"].opt_bin/"python3")

    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"

    # Needed by intltool (xml::parser)
    ENV.prepend_path "PERL5LIB", "#{Formula["intltool"].libexec}/lib/perl5"

    # Fix compilation error: file ./man/custom-html.xsl line 24 element import
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    args = %W[
      --prefix=#{prefix}
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      -Drootprefix=#{prefix}
      -Dsysvinit-path=#{prefix}/etc/init.d
      -Dsysvrcnd-path=#{prefix}/etc/rc.d
      -Dpamconfdir=#{prefix}/etc/pam.d
      -Dcreate-log-dirs=false
      -Dhwdb=false
      -Dlz4=true
    ]

    mkdir "build" do
      system "meson", *args, ".."
      system "ninja", "-v"
      system "ninja", "install", "-v"
    end
  end

  test do
    system "#{bin}/systemd-path"
  end
end

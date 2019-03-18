class Glibmm < Formula
  desc "C++ interface to glib"
  homepage "https://www.gtkmm.org/"
  url "https://download.gnome.org/sources/glibmm/2.58/glibmm-2.58.1.tar.xz"
  sha256 "6e5fe03bdf1e220eeffd543e017fd2fb15bcec9235f0ffd50674aff9362a85f0"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles"
    cellar :any
    sha256 "53f25847c421d3d56383031d69808c9d78488a2097968a8e7f446b367cd0bea5" => :mojave
    sha256 "5682d288f3f9f471919f2a3efb6483200b3eef3a21ae30668f0016104a82d5b3" => :high_sierra
    sha256 "6874494fefa0d272fe9a19c0148653c0cf50598f77b45be5680ed201fc885d0e" => :sierra
    sha256 "69fa397963a460328e8be6515163fb38f515cc0aefbb4d8a95adac5a9fd43e74" => :x86_64_linux
  end

  depends_on "pkg-config" => :build
  depends_on "glib"
  depends_on "libsigc++"

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j6" if ENV["CIRCLECI"]

    ENV.cxx11

    # see https://bugzilla.gnome.org/show_bug.cgi?id=781947
    # Note that desktopappinfo.h is not installed on Linux
    # if these changes are made.
    if OS.mac?
      inreplace "gio/giomm/Makefile.in" do |s|
        s.gsub! "OS_COCOA_TRUE", "OS_COCOA_TEMP"
        s.gsub! "OS_COCOA_FALSE", "OS_COCOA_TRUE"
        s.gsub! "OS_COCOA_TEMP", "OS_COCOA_FALSE"
      end
    end

    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <glibmm.h>

      int main(int argc, char *argv[])
      {
         Glib::ustring my_string("testing");
         return 0;
      }
    EOS
    gettext = Formula["gettext"]
    glib = Formula["glib"]
    libsigcxx = Formula["libsigc++"]
    flags = %W[
      -I#{gettext.opt_include}
      -I#{glib.opt_include}/glib-2.0
      -I#{glib.opt_lib}/glib-2.0/include
      -I#{include}/glibmm-2.4
      -I#{libsigcxx.opt_include}/sigc++-2.0
      -I#{libsigcxx.opt_lib}/sigc++-2.0/include
      -I#{lib}/glibmm-2.4/include
      -L#{gettext.opt_lib}
      -L#{glib.opt_lib}
      -L#{libsigcxx.opt_lib}
      -L#{lib}
      -lglib-2.0
      -lglibmm-2.4
      -lgobject-2.0
      -lsigc-2.0
    ]
    flags << "-lintl" if OS.mac?
    system ENV.cxx, "-std=c++11", "test.cpp", "-o", "test", *flags
    system "./test"
  end
end

require "os/linux/glibc"

class GccAT5 < Formula
  def osmajor
    `uname -r`.chomp
  end

  desc "The GNU Compiler Collection"
  homepage "https://gcc.gnu.org/"
  url "https://ftp.gnu.org/gnu/gcc/gcc-5.5.0/gcc-5.5.0.tar.xz"
  mirror "https://ftpmirror.gnu.org/gcc/gcc-5.5.0/gcc-5.5.0.tar.xz"
  sha256 "530cea139d82fe542b358961130c69cfde8b3d14556370b65823d2f91f0ced87"
  revision 4

  # gcc is designed to be portable.
  bottle do
    cellar :any
    sha256 "7fc31bed73398ba401db3107151a3b0ae301ddc60e017a45bd3d69ac1b400235" => :high_sierra
    sha256 "c2083636a45129a71c8ba9aba51f7536e976aa8a031eb899ec396c310dc6ec43" => :x86_64_linux
  end

  # The bottles are built on systems with the CLT installed, and do not work
  # out of the box on Xcode-only systems due to an incorrect sysroot.
  pour_bottle? do
    reason "The bottle needs the Xcode CLT to be installed."
    satisfy { !OS.mac? || MacOS::CLT.installed? }
  end

  depends_on :maximum_macos => [:high_sierra, :build]

  depends_on "gmp"
  depends_on "libmpc"
  depends_on "mpfr"

  unless OS.mac?
    depends_on "isl@0.18"
    depends_on "zlib"
    depends_on "binutils"
  end

  # GCC bootstraps itself, so it is OK to have an incompatible C++ stdlib
  cxxstdlib_check :skip

  resource "isl" do
    url "https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.14.tar.bz2"
    mirror "https://mirrorservice.org/sites/distfiles.macports.org/isl/isl-0.14.tar.bz2"
    sha256 "7e3c02ff52f8540f6a85534f54158968417fd676001651c8289c705bd0228f36"
  end

  # Fix build with Xcode 9
  # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=82091
  if OS.mac? && DevelopmentTools.clang_build_version >= 900
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/078797f1b9/gcc%405/xcode9.patch"
      sha256 "e1546823630c516679371856338abcbab381efaf9bd99511ceedcce3cf7c0199"
    end
  end

  # Fix Apple headers, otherwise they trigger a build failure in libsanitizer
  # GCC bug report: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=83531
  # Apple radar 36176941
  if OS.mac? && MacOS.version == :high_sierra
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/413cfac6/gcc%405/10.13_headers.patch"
      sha256 "94aaec20c8c7bfd3c41ef8fb7725bd524b1c0392d11a411742303a3465d18d09"
    end
  end

  # Patch for Xcode bug, taken from https://gcc.gnu.org/bugzilla/show_bug.cgi?id=89864#c43
  # This should be removed in the next release of GCC if fixed by apple; this is an xcode bug,
  # but this patch is a work around committed to GCC trunk
  if OS.mac? && MacOS::Xcode.version >= "10.2"
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/91d57ebe88e17255965fa88b53541335ef16f64a/gcc%405/gcc5-xcode10.2.patch"
      sha256 "6834bec30c54ab1cae645679e908713102f376ea0fc2ee993b3c19995832fe56"
    end
  end

  def install
    # GCC will suffer build errors if forced to use a particular linker.
    ENV.delete "LD"

    # Build ISL 0.14 from source during bootstrap
    resource("isl").stage buildpath/"isl" if OS.mac?

    # C, C++, ObjC and Fortran compilers are always built
    languages = %w[c c++ fortran objc obj-c++]

    version_suffix = version.to_s.slice(/\d/)

    # Even when suffixes are appended, the info pages conflict when
    # install-info is run so pretend we have an outdated makeinfo
    # to prevent their build.
    ENV["gcc_cv_prog_makeinfo_modern"] = "no"

    osmajor = `uname -r`.chomp
    args = [
      "--prefix=#{prefix}",
      "--libdir=#{lib}/gcc/#{version_suffix}",
      "--enable-languages=#{languages.join(",")}",
      # Make most executables versioned to avoid conflicts.
      "--program-suffix=-#{version_suffix}",
      "--with-gmp=#{Formula["gmp"].opt_prefix}",
      "--with-mpfr=#{Formula["mpfr"].opt_prefix}",
      "--with-mpc=#{Formula["libmpc"].opt_prefix}",
      "--enable-stage1-checking",
      "--enable-checking=release",
      "--enable-lto",
      "--enable-plugin",
      # A no-op unless --HEAD is built because in head warnings will
      # raise errors. But still a good idea to include.
      "--disable-werror",
      "--disable-nls",
      "--with-pkgversion=Homebrew GCC #{pkg_version} #{build.used_options*" "}".strip,
    ]

    unless OS.mac?
      args += [
        "--with-isl=#{Formula["isl@0.18"].opt_prefix}",
        "--with-bugurl=https://github.com/Homebrew/linuxbrew-core/issues",
        # Fix cc1: error while loading shared libraries: libisl.so.15
        "--with-boot-ldflags=-static-libstdc++ -static-libgcc #{ENV["LDFLAGS"]}",
      ]

      # Change the default directory name for 64-bit libraries to `lib`
      # http://www.linuxfromscratch.org/lfs/view/development/chapter06/gcc.html
      inreplace "gcc/config/i386/t-linux64", "m64=../lib64", "m64="

      # Set the search path for glibc libraries and objects, using the system's glibc
      # Fix the error: ld: cannot find crti.o: No such file or directory
      ENV.prepend_path "LIBRARY_PATH", Pathname.new(Utils.popen_read(ENV.cc, "-print-file-name=crti.o")).parent
    end

    # Fix Linux error: gnu/stubs-32.h: No such file or directory.
    if OS.mac?
      args << "--with-bugurl=https://github.com/Homebrew/homebrew-core/issues"
      args << "--enable-multilib"
      args << "--build=x86_64-apple-darwin#{osmajor}"

      # System headers may not be in /usr/include
      sdk = MacOS.sdk_path_if_needed
      if sdk
        args << "--with-native-system-header-dir=/usr/include"
        args << "--with-sysroot=#{sdk}"
      end

      # Avoid reference to sed shim
      args << "SED=/usr/bin/sed"
    else
      args << "--disable-multilib"
    end

    # Ensure correct install names when linking against libgcc_s;
    # see discussion in https://github.com/Homebrew/homebrew/pull/34303
    if OS.mac?
      inreplace "libgcc/config/t-slibgcc-darwin", "@shlib_slibdir@", "#{HOMEBREW_PREFIX}/lib/gcc/#{version_suffix}"
    end

    mkdir "build" do
      system "../configure", *args
      system "make", "bootstrap"

      # At this point `make check` could be invoked to run the testsuite. The
      # deja-gnu and autogen formulae must be installed in order to do this.
      system "make", OS.mac? ? "install" : "install-strip"
    end

    # Handle conflicts between GCC formulae.
    # Rename man7.
    Dir.glob(man7/"*.7") { |file| add_suffix file, version_suffix }
    # Even when we disable building info pages some are still installed.
    info.rmtree
  end

  def add_suffix(file, suffix)
    dir = File.dirname(file)
    ext = File.extname(file)
    base = File.basename(file, ext)
    File.rename file, "#{dir}/#{base}-#{suffix}#{ext}"
  end

  def post_install
    unless OS.mac?
      gcc = bin/"gcc-5"
      libgcc = Pathname.new(Utils.popen_read(gcc, "-print-libgcc-file-name")).parent
      raise "command failed: #{gcc} -print-libgcc-file-name" if $CHILD_STATUS.exitstatus.nonzero?

      glibc = Formula["glibc"]
      glibc_installed = glibc.any_version_installed?

      # Symlink crt1.o and friends where gcc can find it.
      crtdir = if glibc_installed
        glibc.opt_lib
      else
        Pathname.new(Utils.popen_read("/usr/bin/cc", "-print-file-name=crti.o")).parent
      end
      ln_sf Dir[crtdir/"*crt?.o"], libgcc

      # Create the GCC specs file
      # See https://gcc.gnu.org/onlinedocs/gcc/Spec-Files.html

      # Locate the specs file
      specs = libgcc/"specs"
      ohai "Creating the GCC specs file: #{specs}"
      specs_orig = Pathname.new("#{specs}.orig")
      rm_f [specs_orig, specs]

      system_header_dirs = ["#{HOMEBREW_PREFIX}/include"]

      # Locate the native system header dirs if user uses system glibc
      unless glibc_installed
        target = Utils.popen_read(gcc, "-print-multiarch").chomp
        raise "command failed: #{gcc} -print-multiarch" if $CHILD_STATUS.exitstatus.nonzero?

        system_header_dirs += ["/usr/include/#{target}", "/usr/include"]
      end

      # Save a backup of the default specs file
      specs_string = Utils.popen_read(gcc, "-dumpspecs")
      raise "command failed: #{gcc} -dumpspecs" if $CHILD_STATUS.exitstatus.nonzero?

      specs_orig.write specs_string

      # Set the library search path
      # For include path:
      #   * `-isysroot #{HOMEBREW_PREFIX}/nonexistent` prevents gcc searching built-in
      #     system header files.
      #   * `-idirafter <dir>` instructs gcc to search system header
      #     files after gcc internal header files.
      # For libraries:
      #   * `-nostdlib -L#{libgcc}` instructs gcc to use brewed glibc
      #     if applied.
      #   * `-L#{libdir}` instructs gcc to find the corresponding gcc
      #     libraries. It is essential if there are multiple brewed gcc
      #     with different versions installed.
      #     Noted that it should only be passed for the `gcc@*` formulae.
      #   * `-L#{HOMEBREW_PREFIX}/lib` instructs gcc to find the rest
      #     brew libraries.
      libdir = HOMEBREW_PREFIX/"lib/gcc/5"
      specs.write specs_string + <<~EOS
        *cpp_unique_options:
        + -isysroot #{HOMEBREW_PREFIX}/nonexistent #{system_header_dirs.map { |p| "-idirafter #{p}" }.join(" ")}

        *link_libgcc:
        #{glibc_installed ? "-nostdlib -L#{libgcc}" : "+"} -L#{libdir} -L#{HOMEBREW_PREFIX}/lib

        *link:
        + --dynamic-linker #{HOMEBREW_PREFIX}/lib/ld.so -rpath #{libdir} -rpath #{HOMEBREW_PREFIX}/lib

      EOS
    end
  end

  test do
    (testpath/"hello-c.c").write <<~EOS
      #include <stdio.h>
      int main()
      {
        puts("Hello, world!");
        return 0;
      }
    EOS
    system bin/"gcc-5", "-o", "hello-c", "hello-c.c"
    assert_equal "Hello, world!\n", `./hello-c`
  end
end

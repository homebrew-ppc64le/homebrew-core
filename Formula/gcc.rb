require "os/linux/glibc"

class Gcc < Formula
  desc "GNU compiler collection"
  homepage "https://gcc.gnu.org/"
  revision OS.mac? ? 1 : 7
  head "https://gcc.gnu.org/git/gcc.git" if OS.mac?

  if OS.mac?
    url "https://ftp.gnu.org/gnu/gcc/gcc-9.3.0/gcc-9.3.0.tar.xz"
    mirror "https://ftpmirror.gnu.org/gcc/gcc-9.3.0/gcc-9.3.0.tar.xz"
    sha256 "71e197867611f6054aa1119b13a0c0abac12834765fe2d81f35ac57f84f742d1"
    head "https://gcc.gnu.org/git/gcc.git"
  else
    url "https://ftp.gnu.org/gnu/gcc/gcc-5.5.0/gcc-5.5.0.tar.xz"
    mirror "https://ftpmirror.gnu.org/gcc/gcc-5.5.0/gcc-5.5.0.tar.xz"
    sha256 "530cea139d82fe542b358961130c69cfde8b3d14556370b65823d2f91f0ced87"
  end

  # gcc is designed to be portable.
  # reminder: always add 'cellar :any'
  bottle do
    cellar :any
    sha256 "57e53d66ad43fe05b5a2f93d6a7cfd472713ac03e9d9c9d0d0187cdc7a273153" => :catalina
    sha256 "de8319322428721741a0dc41dfdf2eece80e0215a7a4a861e0e206a9bfbca583" => :mojave
    sha256 "e50b9cfee063619515a8f164485b3f730077f21b49b7bb30cc5a600ddf577a83" => :high_sierra
    sha256 "8cae5e1f1e2074f46bfeda826313afb7b823879d190f27dbcd6b00fbfd8daedd" => :x86_64_linux
    sha256 "5243ed9602f434941d7fd2f41723ab96fe516367d0c6767b178501760596fc8c" => :ppc64le_linux
  end

  # The bottles are built on systems with the CLT installed, and do not work
  # out of the box on Xcode-only systems due to an incorrect sysroot.
  pour_bottle? do
    reason "The bottle needs the Xcode CLT to be installed and to be installed into #{Homebrew::DEFAULT_PREFIX}."
    satisfy { !OS.mac? || (MacOS::CLT.installed? && HOMEBREW_PREFIX.to_s == Homebrew::DEFAULT_PREFIX) }
  end

  depends_on "gmp"
  depends_on "isl" if OS.mac?
  depends_on "libmpc"
  depends_on "mpfr"
  unless OS.mac?
    depends_on "binutils"
    depends_on "isl@0.18"
  end

  uses_from_macos "zlib"

  # GCC bootstraps itself, so it is OK to have an incompatible C++ stdlib
  cxxstdlib_check :skip

  def version_suffix
    if build.head?
      "HEAD"
    else
      version.to_s.slice(/\d/)
    end
  end

  def install
    # GCC will suffer build errors if forced to use a particular linker.
    ENV.delete "LD"

    # Everything but Ada, which requires a pre-existing GCC Ada compiler
    # (gnat) to bootstrap. GCC 4.6.0 adds go as a language option, but it is
    # currently only compilable on Linux.
    languages = %w[c c++ objc obj-c++ fortran]

    pkgversion = "Homebrew GCC #{pkg_version} #{build.used_options*" "}".strip

    args = [
      "--prefix=#{prefix}",
      "--disable-nls",
      "--enable-checking=release",
      "--enable-languages=#{languages.join(",")}",
      "--program-suffix=-#{version_suffix}",
      "--with-gmp=#{Formula["gmp"].opt_prefix}",
      "--with-mpfr=#{Formula["mpfr"].opt_prefix}",
      "--with-mpc=#{Formula["libmpc"].opt_prefix}",
      "--with-pkgversion=#{pkgversion}",
    ]

    if OS.mac?
      osmajor = `uname -r`.split(".").first
      args += [
        "--build=x86_64-apple-darwin#{osmajor}",
        "--libdir=#{lib}/gcc/#{version_suffix}",
        "--with-isl=#{Formula["isl"].opt_prefix}",
        "--with-system-zlib",
        "--with-bugurl=https://github.com/Homebrew/homebrew/issues",
      ]
    else
      args += [
        "--with-isl=#{Formula["isl@0.18"].opt_prefix}",
        "--with-bugurl=https://github.com/Homebrew/linuxbrew-core/issues",
      ]

      # Change the default directory name for 64-bit libraries to `lib`
      # http://www.linuxfromscratch.org/lfs/view/development/chapter06/gcc.html
      inreplace "gcc/config/i386/t-linux64", "m64=../lib64", "m64="

      # Fix for system gccs that do not support -static-libstdc++
      # gengenrtl: error while loading shared libraries: libstdc++.so.6
      mkdir_p lib
      ln_s Utils.popen_read(ENV.cc, "-print-file-name=libstdc++.so.6").strip, lib
      ln_s Utils.popen_read(ENV.cc, "-print-file-name=libgcc_s.so.1").strip, lib

      # Set the search path for glibc libraries and objects, using the system's glibc
      # Fix the error: ld: cannot find crti.o: No such file or directory
      ENV.prepend_path "LIBRARY_PATH", Pathname.new(Utils.popen_read(ENV.cc, "-print-file-name=crti.o")).parent
    end

    # Fix cc1: error while loading shared libraries: libisl.so.15
    args << "--with-boot-ldflags=-static-libstdc++ -static-libgcc #{ENV["LDFLAGS"]}" unless OS.mac?

    # Xcode 10 dropped 32-bit support
    args << "--disable-multilib" if OS.linux? || DevelopmentTools.clang_build_version >= 1000

    if OS.mac?
      # System headers may not be in /usr/include
      sdk = MacOS.sdk_path_if_needed
      if sdk
        args << "--with-native-system-header-dir=/usr/include"
        args << "--with-sysroot=#{sdk}"
      end

      # Avoid reference to sed shim
      args << "SED=/usr/bin/sed"
    end

    # Ensure correct install names when linking against libgcc_s;
    # see discussion in https://github.com/Homebrew/legacy-homebrew/pull/34303
    if OS.mac?
      inreplace "libgcc/config/t-slibgcc-darwin", "@shlib_slibdir@", "#{HOMEBREW_PREFIX}/lib/gcc/#{version_suffix}"
    end

    mkdir "build" do
      system "../configure", *args

      # Use -headerpad_max_install_names in the build,
      # otherwise updated load commands won't fit in the Mach-O header.
      # This is needed because `gcc` avoids the superenv shim.
      system "make", "BOOT_LDFLAGS=-Wl,-headerpad_max_install_names"
      system "make", OS.mac? ? "install" : "install-strip"

      bin.install_symlink bin/"gfortran-#{version_suffix}" => "gfortran"

      unless OS.mac?
        # Create cpp, gcc and g++ symlinks
        bin.install_symlink "cpp-#{version_suffix}" => "cpp"
        bin.install_symlink "gcc-#{version_suffix}" => "gcc"
        bin.install_symlink "g++-#{version_suffix}" => "g++"
      end
    end

    # Handle conflicts between GCC formulae and avoid interfering
    # with system compilers.
    # Since GCC 4.8 libffi stuff are no longer shipped.
    # Rename man7.
    Dir.glob(man7/"*.7") { |file| add_suffix file, version_suffix }
    # Even when suffixes are appended, the info pages conflict when
    # install-info is run. TODO fix this.
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
      # Create cc and c++ symlinks, unless they already exist
      homebrew_bin = Pathname.new "#{HOMEBREW_PREFIX}/bin"
      homebrew_bin.install_symlink "gcc" => "cc" unless (homebrew_bin/"cc").exist?
      homebrew_bin.install_symlink "g++" => "c++" unless (homebrew_bin/"c++").exist?

      gcc = "#{bin}/gcc-#{version_suffix}"
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
      #   * `-L#{HOMEBREW_PREFIX}/lib` instructs gcc to find the rest
      #     brew libraries.
      specs.write specs_string + <<~EOS
        *cpp_unique_options:
        + -isysroot #{HOMEBREW_PREFIX}/nonexistent #{system_header_dirs.map { |p| "-idirafter #{p}" }.join(" ")}

        *link_libgcc:
        #{glibc_installed ? "-nostdlib -L#{libgcc}" : "+"} -L#{HOMEBREW_PREFIX}/lib

        *link:
        + --dynamic-linker #{HOMEBREW_PREFIX}/lib/ld.so -rpath #{HOMEBREW_PREFIX}/lib

      EOS

      # Symlink ligcc_s.so.1 where glibc can find it.
      # Fix the error: libgcc_s.so.1 must be installed for pthread_cancel to work
      ln_sf opt_lib/"libgcc_s.so.1", glibc.opt_lib if glibc_installed
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
    system "#{bin}/gcc-#{version_suffix}", "-o", "hello-c", "hello-c.c"
    assert_equal "Hello, world!\n", `./hello-c`

    (testpath/"hello-cc.cc").write <<~EOS
      #include <iostream>
      int main()
      {
        std::cout << "Hello, world!" << std::endl;
        return 0;
      }
    EOS
    system "#{bin}/g++-#{version_suffix}", "-o", "hello-cc", "hello-cc.cc"
    assert_equal "Hello, world!\n", `./hello-cc`

    (testpath/"test.f90").write <<~EOS
      integer,parameter::m=10000
      real::a(m), b(m)
      real::fact=0.5

      do concurrent (i=1:m)
        a(i) = a(i) + fact*b(i)
      end do
      write(*,"(A)") "Done"
      end
    EOS
    system "#{bin}/gfortran", "-o", "test", "test.f90"
    assert_equal "Done\n", `./test`
  end
end

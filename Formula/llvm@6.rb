class LlvmAT6 < Formula
  desc "Next-gen compiler infrastructure"
  homepage "https://llvm.org/"
  url "https://releases.llvm.org/6.0.1/llvm-6.0.1.src.tar.xz"
  sha256 "b6d6c324f9c71494c0ccaf3dac1f16236d970002b42bb24a6c9e1634f7d0f4e2"
  revision OS.mac? ? 3 : 4

  bottle do
    cellar :any
    sha256 "3b8315438ee3bf9eaed52b8f293e5aabbbfde7bcab4eded5de9a62b214d0b8b9" => :catalina
    sha256 "5f628b4b14fe10a7b3654902a126956561983ba7aa96dc1d519bfdde5b0552c0" => :mojave
    sha256 "bc740b2c28da83adc7bbfecb1c76a1777a963236de52af18f4413d6b090119ec" => :high_sierra
    sha256 "95f3236a8fd89bd91f02a5cb53589ed39aa9c91d5f5e904acc435630c8cfee06" => :x86_64_linux
  end

  # Clang cannot find system headers if Xcode CLT is not installed
  pour_bottle? do
    reason "The bottle needs the Xcode CLT to be installed."
    satisfy { !OS.mac? || MacOS::CLT.installed? }
  end

  keg_only :versioned_formula

  # https://llvm.org/docs/GettingStarted.html#requirement
  depends_on "cmake" => :build
  depends_on "libffi"

  unless OS.mac?
    depends_on "gcc" # needed for libstdc++
    depends_on "binutils" # needed for gold and strip
    depends_on "libedit" # llvm requires <histedit.h>
    depends_on "libelf" # openmp requires <gelf.h>
    depends_on "ncurses"
    depends_on "libxml2"
    depends_on "zlib"
    depends_on "python@3.8"
  end

  resource "clang" do
    url "https://releases.llvm.org/6.0.1/cfe-6.0.1.src.tar.xz"
    sha256 "7c243f1485bddfdfedada3cd402ff4792ea82362ff91fbdac2dae67c6026b667"

    unless OS.mac?
      patch do
        url "https://github.com/xu-cheng/clang/commit/83c39729df671c06b003e2638a2d5600a8a2278c.patch?full_index=1"
        sha256 "c8a038fb648278d9951d03a437723d5a55abc64346668566b707d555ae5997a6"
      end
    end
  end

  resource "clang-extra-tools" do
    url "https://releases.llvm.org/6.0.1/clang-tools-extra-6.0.1.src.tar.xz"
    sha256 "0d2e3727786437574835b75135f9e36f861932a958d8547ced7e13ebdda115f1"
  end

  resource "compiler-rt" do
    url "https://releases.llvm.org/6.0.1/compiler-rt-6.0.1.src.tar.xz"
    sha256 "f4cd1e15e7d5cb708f9931d4844524e4904867240c306b06a4287b22ac1c99b9"
  end

  if OS.mac?
    resource "libcxx" do
      url "https://releases.llvm.org/6.0.1/libcxx-6.0.1.src.tar.xz"
      sha256 "7654fbc810a03860e6f01a54c2297a0b9efb04c0b9aa0409251d9bdb3726fc67"
    end
  end

  resource "libunwind" do
    url "https://releases.llvm.org/6.0.1/libunwind-6.0.1.src.tar.xz"
    sha256 "a8186c76a16298a0b7b051004d0162032b9b111b857fbd939d71b0930fd91b96"
  end

  resource "lld" do
    url "https://releases.llvm.org/6.0.1/lld-6.0.1.src.tar.xz"
    sha256 "e706745806921cea5c45700e13ebe16d834b5e3c0b7ad83bf6da1f28b0634e11"
  end

  resource "lldb" do
    url "https://releases.llvm.org/6.0.1/lldb-6.0.1.src.tar.xz"
    sha256 "6b8573841f2f7b60ffab9715c55dceff4f2a44e5a6d590ac189d20e8e7472714"
  end

  resource "openmp" do
    url "https://releases.llvm.org/6.0.1/openmp-6.0.1.src.tar.xz"
    sha256 "66afca2b308351b180136cf899a3b22865af1a775efaf74dc8a10c96d4721c5a"
  end

  resource "polly" do
    url "https://releases.llvm.org/6.0.1/polly-6.0.1.src.tar.xz"
    sha256 "e7765fdf6c8c102b9996dbb46e8b3abc41396032ae2315550610cf5a1ecf4ecc"
  end

  # Clang cannot find system headers if Xcode CLT is not installed
  if OS.mac?
    pour_bottle? do
      reason "The bottle needs the Xcode CLT to be installed."
      satisfy { MacOS::CLT.installed? }
    end
  end

  def install
    # Apple's libstdc++ is too old to build LLVM
    ENV.libcxx if ENV.compiler == :clang

    (buildpath/"tools/clang").install resource("clang")
    (buildpath/"tools/clang/tools/extra").install resource("clang-extra-tools")
    (buildpath/"projects/openmp").install resource("openmp")
    (buildpath/"projects/libcxx").install resource("libcxx") if OS.mac?
    (buildpath/"projects/libunwind").install resource("libunwind")
    (buildpath/"tools/lld").install resource("lld")
    (buildpath/"tools/polly").install resource("polly")
    (buildpath/"projects/compiler-rt").install resource("compiler-rt")

    # compiler-rt has some iOS simulator features that require i386 symbols
    # I'm assuming the rest of clang needs support too for 32-bit compilation
    # to work correctly, but if not, perhaps universal binaries could be
    # limited to compiler-rt. llvm makes this somewhat easier because compiler-rt
    # can almost be treated as an entirely different build from llvm.
    ENV.permit_arch_flags

    args = %W[
      -DLIBOMP_ARCH=x86_64
      -DLINK_POLLY_INTO_TOOLS=ON
      -DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON
      -DLLVM_BUILD_LLVM_DYLIB=ON
      -DLLVM_ENABLE_EH=ON
      -DLLVM_ENABLE_FFI=ON
      -DLLVM_ENABLE_RTTI=ON
      -DLLVM_INCLUDE_DOCS=OFF
      -DLLVM_INSTALL_UTILS=ON
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DLLVM_TARGETS_TO_BUILD=all
      -DWITH_POLLY=ON
      -DFFI_INCLUDE_DIR=#{Formula["libffi"].opt_lib}/libffi-#{Formula["libffi"].version}/include
      -DFFI_LIBRARY_DIR=#{Formula["libffi"].opt_lib}
    ]

    if OS.mac?
      args << "-DLLVM_CREATE_XCODE_TOOLCHAIN=ON"
      args << "-DLLVM_ENABLE_LIBCXX=ON"
    else
      args << "-DLLVM_CREATE_XCODE_TOOLCHAIN=OFF"
      args << "-DLLVM_ENABLE_LIBCXX=OFF"
      args << "-DCLANG_DEFAULT_CXX_STDLIB=libstdc++"
    end

    if OS.mac? && MacOS.version >= :mojave
      sdk_path = MacOS::CLT.installed? ? "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk" : MacOS.sdk_path
      args << "-DDEFAULT_SYSROOT=#{sdk_path}"
    end

    mkdir "build" do
      system "cmake", "-G", "Unix Makefiles", "..", *(std_cmake_args + args)
      system "make"
      system "make", "install"
      system "make", "install-xcode-toolchain" if OS.mac?
    end

    (share/"cmake").install "cmake/modules"
    (share/"clang/tools").install Dir["tools/clang/tools/scan-{build,view}"]

    # scan-build is in Perl, so the @ in our path needs to be escaped
    inreplace "#{share}/clang/tools/scan-build/bin/scan-build",
              "$RealBin/bin/clang", "#{bin}/clang".gsub("@", "\\@")

    bin.install_symlink share/"clang/tools/scan-build/bin/scan-build", share/"clang/tools/scan-view/bin/scan-view"
    man1.install_symlink share/"clang/tools/scan-build/man/scan-build.1"

    # install llvm python bindings
    xz = OS.mac? ? "2.7": "3.8"
    (lib/"python#{xz}/site-packages").install buildpath/"bindings/python/llvm"
    (lib/"python#{xz}/site-packages").install buildpath/"tools/clang/bindings/python/clang"

    unless OS.mac?
      # Strip executables/libraries/object files to reduce their size
      system("strip", "--strip-unneeded", "--preserve-dates", *(Dir[bin/"**/*", lib/"**/*"]).select do |f|
        f = Pathname.new(f)
        f.file? && (f.elf? || f.extname == ".a")
      end)
    end
  end

  def caveats
    <<~EOS
      To use the bundled libc++ please add the following LDFLAGS:
        LDFLAGS="-L#{opt_lib} -Wl,-rpath,#{opt_lib}"
    EOS
  end

  test do
    assert_equal prefix.to_s, shell_output("#{bin}/llvm-config --prefix").chomp

    (testpath/"omptest.c").write <<~EOS
      #include <stdlib.h>
      #include <stdio.h>
      #include <omp.h>

      int main() {
          #pragma omp parallel num_threads(4)
          {
            printf("Hello from thread %d, nthreads %d\\n", omp_get_thread_num(), omp_get_num_threads());
          }
          return EXIT_SUCCESS;
      }
    EOS

    clean_version = version.to_s[/(\d+\.?)+/]

    system "#{bin}/clang", "-L#{lib}", "-fopenmp", "-nobuiltininc",
                           "-I#{lib}/clang/#{clean_version}/include",
                           *("-Wl,-rpath=#{lib}" unless OS.mac?),
                           "omptest.c", "-o", "omptest", *ENV["LDFLAGS"].split
    testresult = shell_output("./omptest")

    sorted_testresult = testresult.split("\n").sort.join("\n")
    expected_result = <<~EOS
      Hello from thread 0, nthreads 4
      Hello from thread 1, nthreads 4
      Hello from thread 2, nthreads 4
      Hello from thread 3, nthreads 4
    EOS
    assert_equal expected_result.strip, sorted_testresult.strip

    (testpath/"test.c").write <<~EOS
      #include <stdio.h>

      int main()
      {
        printf("Hello World!\\n");
        return 0;
      }
    EOS

    (testpath/"test.cpp").write <<~EOS
      #include <iostream>

      int main()
      {
        std::cout << "Hello World!" << std::endl;
        return 0;
      }
    EOS

    unless OS.mac?
      system "#{bin}/clang++", "-v", "test.cpp", "-o", "test"
      assert_equal "Hello World!", shell_output("./test").chomp
    end

    if OS.mac?
      # Testing default toolchain and SDK location.
      system "#{bin}/clang++", "-v",
             "-std=c++11", "test.cpp", "-o", "test++"
      assert_includes MachO::Tools.dylibs("test++"), "/usr/lib/libc++.1.dylib"
      assert_equal "Hello World!", shell_output("./test++").chomp
      system "#{bin}/clang", "-v", "test.c", "-o", "test"
      assert_equal "Hello World!", shell_output("./test").chomp

      # Testing Command Line Tools
      if MacOS::CLT.installed?
        toolchain_path = "/Library/Developer/CommandLineTools"
        sdk_path = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
        system "#{bin}/clang++", "-v",
               "-isysroot", sdk_path,
               "-isystem", "#{toolchain_path}/usr/include/c++/v1",
               "-isystem", "#{toolchain_path}/usr/include",
               "-isystem", "#{sdk_path}/usr/include",
               "-std=c++11", "test.cpp", "-o", "testCLT++"
        assert_includes MachO::Tools.dylibs("testCLT++"), "/usr/lib/libc++.1.dylib"
        assert_equal "Hello World!", shell_output("./testCLT++").chomp
        system "#{bin}/clang", "-v", "test.c", "-o", "testCLT"
        assert_equal "Hello World!", shell_output("./testCLT").chomp
      end

      # Testing Xcode
      if MacOS::Xcode.installed?
        system "#{bin}/clang++", "-v",
               "-isysroot", MacOS.sdk_path,
               "-isystem", "#{MacOS::Xcode.toolchain_path}/usr/include/c++/v1",
               "-isystem", "#{MacOS::Xcode.toolchain_path}/usr/include",
               "-isystem", "#{MacOS.sdk_path}/usr/include",
               "-std=c++11", "test.cpp", "-o", "testXC++"
        assert_includes MachO::Tools.dylibs("testXC++"), "/usr/lib/libc++.1.dylib"
        assert_equal "Hello World!", shell_output("./testXC++").chomp
        system "#{bin}/clang", "-v",
               "-isysroot", MacOS.sdk_path,
               "test.c", "-o", "testXC"
        assert_equal "Hello World!", shell_output("./testXC").chomp
      end

      # link against installed libc++
      # related to https://github.com/Homebrew/legacy-homebrew/issues/47149
      system "#{bin}/clang++", "-v",
             "-isystem", "#{opt_include}/c++/v1",
             "-std=c++11", "-stdlib=libc++", "test.cpp", "-o", "testlibc++",
             "-L#{opt_lib}", "-Wl,-rpath,#{opt_lib}"
      assert_includes MachO::Tools.dylibs("testlibc++"), "#{opt_lib}/libc++.1.dylib"
      assert_equal "Hello World!", shell_output("./testlibc++").chomp

      (testpath/"scanbuildtest.cpp").write <<~EOS
        #include <iostream>
        int main() {
          int *i = new int;
          *i = 1;
          delete i;
          std::cout << *i << std::endl;
          return 0;
        }
      EOS
      assert_includes shell_output("#{bin}/scan-build clang++ scanbuildtest.cpp 2>&1"),
        "warning: Use of memory after it is freed"

      (testpath/"clangformattest.c").write <<~EOS
        int    main() {
            printf("Hello world!"); }
      EOS
      assert_equal "int main() { printf(\"Hello world!\"); }\n",
        shell_output("#{bin}/clang-format -style=google clangformattest.c")
    end
  end
end

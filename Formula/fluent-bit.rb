class FluentBit < Formula
  desc "Data Collector for IoT"
  homepage "https://github.com/fluent/fluent-bit"
  url "https://github.com/fluent/fluent-bit/archive/v1.4.4.tar.gz"
  sha256 "f9abc86ca56fbfc7b5c3fff1511f21e6eaa4c75cae7690e2fcca381872abf6f7"
  head "https://github.com/fluent/fluent-bit.git"

  bottle do
    cellar :any
    sha256 "64031d4f5bfa57fe3e8a9e4c4cc657693ee59bb1938cd43c3b10b140240ebead" => :catalina
    sha256 "25c5ceaa2d7f2587128905c9c7e569912837dc26efc423ddfaf4fd7a2303c01e" => :mojave
    sha256 "4c87aca55847c43c373e30666a6a0e77e325c92708ef818540e47c83b3a961c4" => :high_sierra
    sha256 "b2e01e83e7a6374b0860e951a6add7bcebab84885d1e8d71d49d58e01d300642" => :x86_64_linux
  end

  depends_on "bison" => :build
  depends_on "cmake" => :build
  depends_on "flex" => :build

  conflicts_with "mbedtls", :because => "fluent-bit includes mbedtls libraries."
  conflicts_with "msgpack", :because => "fluent-bit includes msgpack libraries."

  # Don't install service files
  patch :DATA unless OS.mac?

  def install
    # Work around Xcode 11 clang bug
    ENV.append_to_cflags "-fno-stack-check" if DevelopmentTools.clang_build_version >= 1010

    # Per https://luajit.org/install.html: If MACOSX_DEPLOYMENT_TARGET
    # is not set then it's forced to 10.4, which breaks compile on Mojave.
    # fluent-bit builds against a vendored Luajit.
    ENV["MACOSX_DEPLOYMENT_TARGET"] = MacOS.version

    system "cmake", ".", "-DWITH_IN_MEM=OFF", *std_cmake_args
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/fluent-bit -V").chomp
    assert_equal "Fluent Bit v#{version}", output
  end
end
__END__
diff --git a/src/CMakeLists.txt b/src/CMakeLists.txt
index 54b3b291..72fd1088 100644
--- a/src/CMakeLists.txt
+++ b/src/CMakeLists.txt
@@ -316,27 +316,6 @@ if(FLB_BINARY)
     ENABLE_EXPORTS ON)
   install(TARGETS fluent-bit-bin RUNTIME DESTINATION ${FLB_INSTALL_BINDIR})

-  # Detect init system, install upstart, systemd or init.d script
-  if(IS_DIRECTORY /lib/systemd/system)
-    set(FLB_SYSTEMD_SCRIPT "${PROJECT_SOURCE_DIR}/init/${FLB_OUT_NAME}.service")
-    configure_file(
-      "${PROJECT_SOURCE_DIR}/init/systemd.in"
-      ${FLB_SYSTEMD_SCRIPT}
-      )
-    install(FILES ${FLB_SYSTEMD_SCRIPT} DESTINATION /lib/systemd/system)
-    install(DIRECTORY DESTINATION ${FLB_INSTALL_CONFDIR})
-  elseif(IS_DIRECTORY /usr/share/upstart)
-    set(FLB_UPSTART_SCRIPT "${PROJECT_SOURCE_DIR}/init/${FLB_OUT_NAME}.conf")
-    configure_file(
-      "${PROJECT_SOURCE_DIR}/init/upstart.in"
-      ${FLB_UPSTART_SCRIPT}
-      )
-    install(FILES ${FLB_UPSTART_SCRIPT} DESTINATION /etc/init)
-    install(DIRECTORY DESTINATION ${FLB_INSTALL_CONFDIR})
-  else()
-    # FIXME: should we support Sysv init script ?
-  endif()
-
   install(FILES
     "${PROJECT_SOURCE_DIR}/conf/fluent-bit.conf"
     DESTINATION ${FLB_INSTALL_CONFDIR}

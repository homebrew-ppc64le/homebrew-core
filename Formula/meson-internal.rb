class MesonInternal < Formula
  include Language::Python::Virtualenv

  desc "Fast and user friendly build system"
  homepage "https://mesonbuild.com/"
  url "https://github.com/mesonbuild/meson/releases/download/0.46.1/meson-0.46.1.tar.gz"
  sha256 "19497a03e7e5b303d8d11f98789a79aba59b5ad4a81bd00f4d099be0212cee78"
  revision 2 unless OS.mac?

  bottle do
    cellar :any_skip_relocation
    sha256 "64be4001ba0c88b770c4539489d5be2cd15b0b221a22721bd69a7af414cd20de" => :catalina
    sha256 "4f65a25c147b6e21ce47cfd2d2f744ee3c0a55e9e1b07c9119dfeb52b13946fe" => :mojave
    sha256 "cadf29ef1454acee4573d184a01e86e9c05d636b445c21255314dcca80cd9585" => :high_sierra
    sha256 "ac82416f8f8f99bfd0c19ba2196028d541b945f6bf401a018f59a0d81775988a" => :sierra
    sha256 "a2434e205cbab983230a6019fa9520adb2a5c2c31eb8d430ac80b74ddec790b6" => :el_capitan
    sha256 "f69ac0d8d10f05ae12634132273cf04daa795fcf4ae0f9cbdb3485aa37fb3fd5" => :x86_64_linux
  end

  keg_only <<~EOS
    this formula contains a heavily patched version of the meson build system and
    is exclusively used internally by other formulae.
    Users are advised to run `brew install meson` to install
    the official meson build
  EOS

  depends_on "ninja"
  depends_on "python"

  if OS.mac?
    # see https://github.com/mesonbuild/meson/pull/2577
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/a20d7df94112f93ea81f72ff3eacaa2d7e681053/meson-internal/meson-osx.patch?full_index=1"
      sha256 "d8545f5ffbb4dcc58131f35a9a97188ecb522c6951574c616d0ad07495d68895"
    end
  else
    patch :DATA
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    (testpath/"helloworld.c").write <<~EOS
      main() {
        puts("hi");
        return 0;
      }
    EOS
    (testpath/"meson.build").write <<~EOS
      project('hello', 'c')
      executable('hello', 'helloworld.c')
    EOS

    mkdir testpath/"build" do
      system "#{bin}/meson", ".."
      assert_predicate testpath/"build/build.ninja", :exist?
    end
  end
end
__END__
--- a/mesonbuild/scripts/meson_install.py
+++ b/mesonbuild/scripts/meson_install.py
@@ -366,14 +366,6 @@ def install_targets(d):
                     print("Symlink creation does not work on this platform. "
                           "Skipping all symlinking.")
                     printed_symlink_error = True
-        if os.path.isfile(outname):
-            try:
-                depfixer.fix_rpath(outname, install_rpath, False)
-            except SystemExit as e:
-                if isinstance(e.code, int) and e.code == 0:
-                    pass
-                else:
-                    raise

 def run(args):
     global install_log_file

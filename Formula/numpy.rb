class Numpy < Formula
  desc "Package for scientific computing with Python"
  homepage "https://www.numpy.org/"
  url "https://files.pythonhosted.org/packages/0c/e8/c49cb52ed2ad734efb49eb1f7766888b0e65df1848f71fa7f7fd52183392/numpy-1.18.3.zip"
  sha256 "e46e2384209c91996d5ec16744234d1c906ab79a701ce1a26155c9ec890b8dc8"
  head "https://github.com/numpy/numpy.git"

  bottle do
    sha256 "14f3fe23e77f0ea3ff28f5b339bbcccfe8c8b8c60456eb03bc9bd7d51ca031f5" => :catalina
    sha256 "4aabd9a93b951b151ff2d8be7a07e31b6370685032f694b5a4a800803d1e6c1d" => :mojave
    sha256 "f866629bdf3582ae8441df9b1522102f5adb26a1860ae2af0ece499ab8edfc04" => :high_sierra
    sha256 "47cf0645d703a8bfd66f28e2c9118aa473e1604c66bd4539488c7bf50400e6a9" => :x86_64_linux
  end

  depends_on "cython" => :build
  depends_on "gcc" => :build # for gfortran
  depends_on "openblas"
  depends_on "python@3.8"

  def install
    openblas = Formula["openblas"].opt_prefix
    ENV["ATLAS"] = "None" # avoid linking against Accelerate.framework
    ENV["BLAS"] = ENV["LAPACK"] = "#{openblas}/lib/libopenblas.dylib"

    config = <<~EOS
      [openblas]
      libraries = openblas
      library_dirs = #{openblas}/lib
      include_dirs = #{openblas}/include
    EOS

    Pathname("site.cfg").write config

    version = Language::Python.major_minor_version Formula["python@3.8"].opt_bin/"python3"
    ENV.prepend_create_path "PYTHONPATH", Formula["cython"].opt_libexec/"lib/python#{version}/site-packages"

    system Formula["python@3.8"].opt_bin/"python3", "setup.py",
      "build", "--fcompiler=gnu95", "--parallel=#{ENV.make_jobs}",
      "install", "--prefix=#{prefix}",
      "--single-version-externally-managed", "--record=installed.txt"
  end

  test do
    system Formula["python@3.8"].opt_bin/"python3", "-c", <<~EOS
      import numpy as np
      t = np.ones((3,3), int)
      assert t.sum() == 9
      assert np.dot(t, t).sum() == 27
    EOS
  end
end

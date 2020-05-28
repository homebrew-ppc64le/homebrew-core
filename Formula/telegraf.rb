class Telegraf < Formula
  desc "Server-level metric gathering agent for InfluxDB"
  homepage "https://influxdata.com"
  url "https://github.com/influxdata/telegraf/archive/v1.14.3.tar.gz"
  sha256 "88c028d22c46cc65d51689e13b3ed25e0e583eda4fbf967aa8dc6e44ab508ba0"
  head "https://github.com/influxdata/telegraf.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "b76fdfb13c1fc4466bf21c4df8d0cf307b09499ecd766b48d4084c30f7e6a3f2" => :catalina
    sha256 "83c18e93dd186262b53e610ae50252db778e9e10630eda3457f3c5a589c625ac" => :mojave
    sha256 "3c3b9977be73f353dc05aae9cda91164a774ec14f0542e17ce1cc1f8f073541e" => :high_sierra
    sha256 "7abdb032a1d191e9c85fc2e00a16fb9d79cd9370f1e5d781e22a95d4e6b5aef3" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    dir = buildpath/"src/github.com/influxdata/telegraf"
    dir.install buildpath.children
    cd dir do
      system "go", "mod", "download"
      system "go", "install", "-ldflags", "-X main.version=#{version}", "./..."
      prefix.install_metafiles
    end
    bin.install "bin/telegraf"
    etc.install dir/"etc/telegraf.conf" => "telegraf.conf"
  end

  def post_install
    # Create directory for additional user configurations
    (etc/"telegraf.d").mkpath
  end

  plist_options :manual => "telegraf -config #{HOMEBREW_PREFIX}/etc/telegraf.conf"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>KeepAlive</key>
          <dict>
            <key>SuccessfulExit</key>
            <false/>
          </dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_bin}/telegraf</string>
            <string>-config</string>
            <string>#{etc}/telegraf.conf</string>
            <string>-config-directory</string>
            <string>#{etc}/telegraf.d</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>WorkingDirectory</key>
          <string>#{var}</string>
          <key>StandardErrorPath</key>
          <string>#{var}/log/telegraf.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/telegraf.log</string>
        </dict>
      </plist>
    EOS
  end

  test do
    (testpath/"config.toml").write shell_output("#{bin}/telegraf -sample-config")
    system "#{bin}/telegraf", "-config", testpath/"config.toml", "-test",
           "-input-filter", "cpu:mem"
  end
end

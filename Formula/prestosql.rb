class Prestosql < Formula
  desc "Distributed SQL query engine for big data"
  homepage "https://prestosql.io"
  url "https://search.maven.org/remotecontent?filepath=io/prestosql/presto-server/333/presto-server-333.tar.gz"
  sha256 "59ef226067643bfa293e3104c3b1748bbbbb09d1099f39a016483d2ef62e5df1"

  bottle :unneeded

  depends_on "openjdk"

  conflicts_with "prestodb", :because => "both install `presto` and `presto-server` binaries"

  resource "presto-cli" do
    url "https://search.maven.org/remotecontent?filepath=io/prestosql/presto-cli/333/presto-cli-333-executable.jar"
    sha256 "f9f4e2cbc6ed54408b2e838d8955518f546328deabd6df60698d0e9b7bb54976"
  end

  def install
    libexec.install Dir["*"]

    (libexec/"etc/node.properties").write <<~EOS
      node.environment=dev
      node.id=dev
      node.data-dir=#{var}/presto/data
    EOS

    (libexec/"etc/jvm.config").write <<~EOS
      -XX:+UseG1GC
      -XX:G1HeapRegionSize=32M
      -XX:+ExplicitGCInvokesConcurrent
      -XX:+ExitOnOutOfMemoryError
      -Djdk.attach.allowAttachSelf=true
    EOS

    (libexec/"etc/config.properties").write <<~EOS
      coordinator=true
      node-scheduler.include-coordinator=true
      http-server.http.port=8080
      query.max-memory=1GB
      query.max-memory-per-node=1GB
      discovery-server.enabled=true
      discovery.uri=http://localhost:8080
    EOS

    (libexec/"etc/log.properties").write <<~EOS
      io.prestosql=INFO
    EOS

    (libexec/"etc/catalog/jmx.properties").write <<~EOS
      connector.name=jmx
    EOS

    (bin/"presto-server").write <<~EOS
      #!/bin/bash
      export JAVA_HOME="#{Formula["openjdk"].opt_prefix}"
      exec "#{libexec}/bin/launcher" "$@"
    EOS

    resource("presto-cli").stage do
      libexec.install "presto-cli-#{version}-executable.jar"
      (bin/"presto").write <<~EOS
        #!/bin/bash
        exec "#{Formula["openjdk"].opt_bin}/java" -jar "#{libexec}/presto-cli-#{version}-executable.jar" "$@"
      EOS
    end
  end

  def post_install
    (var/"presto/data").mkpath
  end

  def caveats
    <<~EOS
      Add connectors to #{opt_libexec}/etc/catalog/. See:
      https://prestosql.io/docs/current/connector.html
    EOS
  end

  plist_options :manual => "presto-server run"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>RunAtLoad</key>
          <true/>
          <key>AbandonProcessGroup</key>
          <true/>
          <key>WorkingDirectory</key>
          <string>#{opt_libexec}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_bin}/presto-server</string>
            <string>run</string>
          </array>
        </dict>
      </plist>
    EOS
  end

  test do
    system bin/"presto-server", "run", "--help"
    assert_match "Presto CLI #{version}", shell_output("#{bin}/presto --version").chomp
  end
end

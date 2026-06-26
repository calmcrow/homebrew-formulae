class Winghexexplorer2 < Formula
  desc "A powerful hex editor with scripting support"
  homepage "https://github.com/Wing-summer/WingHexExplorer2"
  license "AGPL-3.0"
  version "2.3.7.2"
  url "https://github.com/Wing-summer/WingHexExplorer2.git",
      using: :git,
      revision: "b0ee4db659578296d63211f49a4cb3f6134549a0"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "node" => :build
  depends_on "pkg-config" => :build
  depends_on "libdwarf"
  depends_on "openssl@3"
  depends_on "qt@6"
  depends_on "zstd"

  patch do
    url "file://#{File.expand_path("winghexexplorer2-macos-compat.patch", __dir__)}"
    sha256 "8e5e82ca93df548f9f77afd339af26d5e62a6bec979aa7b7059ad2c021bd23b2"
  end

  def install
    system "git", "submodule", "update", "--init", "--recursive"

    # Allow PKG_TARGET override from cmake command line
    inreplace "CMakeLists.txt",
              "    elseif(APPLE)\r\n        set(PKG_TARGET \"node18-macos-x64\")",
              "    elseif(APPLE)\r\n        if(NOT PKG_TARGET)\r\n            set(PKG_TARGET \"node18-macos-x64\")\r\n        endif()"

    inreplace "3rdparty/QHexView/qhexview.cpp" do |s|
      s.sub! 'f.setFamily(QStringLiteral("Monospace")); // Force Monospaced font', ""
      s.sub! 'f.setFamily("Monospace"); // Force Monospaced font', ""
    end

    system "cmake", "-S", ".", "-B", "build",
           "-G", "Ninja",
           "-DCMAKE_BUILD_TYPE=Release",
           "-DCMAKE_INSTALL_PREFIX=#{prefix}",
           "-DPKG_TARGET=node18-macos-#{Hardware::CPU.arm? ? "arm64" : "x64"}",
           "-DCPPTRACE_USE_EXTERNAL_ZSTD=ON",
           "-DCPPTRACE_USE_EXTERNAL_LIBDWARF=ON",
           "-DCPPTRACE_FIND_LIBDWARF_WITH_PKGCONFIG=ON",
           *std_cmake_args

    system "cmake", "--build", "build",
           "--target", "langgen_en_US",
           "--target", "langgen_zh_CN",
           "--target", "langgen_zh_TW"

    oh1 "Compiling WingHexExplorer2..."
    oh1 "This will take 20-30 minutes."
    oh1 "Time for a coffee ☕️, a nap 😴, or watch paint dry 🎨."
    oh1 "I'll wait. Take your time."

    system "cmake", "--build", "build", "--target", "WingHexExplorer2"

    # Install the .app bundle
    prefix.install "build/WingHexExplorer2.app"
    appdir = prefix/"WingHexExplorer2.app/Contents/MacOS"
    cp_r "build/lang",   appdir
    cp_r "build/lsp",    appdir
    mkdir_p appdir/"scripts"
    mkdir_p appdir/"plugins"

    # Copy libWingPlugin.dylib into bundle BEFORE macdeployqt
    dylib = Pathname.glob("build/**/libWingPlugin.dylib").first
    if dylib
      frameworks = prefix/"WingHexExplorer2.app/Contents/Frameworks"
      frameworks.mkpath
      cp dylib, frameworks
      system "macdeployqt", "#{prefix}/WingHexExplorer2.app",
             "-executable=#{frameworks}/libWingPlugin.dylib"
    else
      system "macdeployqt", "#{prefix}/WingHexExplorer2.app"
    end
  end

  def caveats
    <<~EOS
      WingHexExplorer2 is installed at:
        #{prefix}/WingHexExplorer2.app
      Run: open #{prefix}/WingHexExplorer2.app

      To fully remove all traces after uninstall:
        rm -rf ~/Library/Caches/Homebrew/winghexexplorer2--git
        rm -f  ~/Library/Preferences/com.wingcloudstudio.WingHexExplorer2.plist
        rm -rf ~/Library/Application Support/WingCloudStudio
        rm -rf ~/Library/Logs/DiagnosticReports/WingHexExplorer2_*
        rm -rf ~/Library/Application Support/CrashReporter/WingHexExplorer2_*
    EOS
  end
end

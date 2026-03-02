# screenmind.rb — Homebrew formula for ScreenMind
# Install: brew tap pkmdev-sec/screenmind && brew install screenmind

class Screenmind < Formula
  desc "AI-powered screen memory for macOS — captures, understands, and indexes your screen"
  homepage "https://github.com/pkmdev-sec/screenmind"
  url "https://github.com/pkmdev-sec/screenmind/releases/download/v2.1.0/ScreenMind.dmg"
  sha256 "PLACEHOLDER_SHA256"
  version "2.1.0"
  license "MIT"

  depends_on :macos
  depends_on macos: :sonoma

  def install
    # Copy app bundle to prefix
    prefix.install "ScreenMind.app"

    # Install CLI tool
    if File.exist?("screenmind-cli")
      bin.install "screenmind-cli"
    end
  end

  def post_install
    # Create symlink in /Applications for discoverability
    system "ln", "-sf", "#{prefix}/ScreenMind.app", "/Applications/ScreenMind.app"
  end

  def caveats
    <<~EOS
      ScreenMind requires Screen Recording permission.
      Grant in: System Settings > Privacy & Security > Screen Recording

      Launch from Applications or Spotlight: "ScreenMind"

      CLI tool installed at: #{bin}/screenmind-cli
      Run: screenmind-cli --help

      For audio features (voice memos, transcription):
        Grant Microphone permission in System Settings
    EOS
  end
end

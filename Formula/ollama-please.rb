require_relative "../lib/version"

class OllamaPlease < Formula
  desc "Ruby wrapper for Ollama with built-in prompts"
  homepage "https://github.com/simonas-dev/please"
  url "https://github.com/simonas-dev/please.git", tag: PleaseConsts::VERSION
  version PleaseConsts::VERSION
  license "MIT"

  depends_on "ruby"
  depends_on "ollama"

  def install
    # Install the library files including the YAML file
    lib.install Dir["lib/*"]
    
    # Install the binary
    bin.install "bin/pls"
    
    # Update the binary to use the installed lib path
    inreplace bin/"pls", 
              "require_relative '../lib/ollama_wrapper'",
              "require_relative '#{lib}/ollama_wrapper'"
  end

  def caveats
    <<~EOS      
      Make sure Ollama is installed and running to use this tool.
      Visit https://ollama.ai for Ollama installation instructions.
    EOS
  end

  test do
    assert_match "Please - Ollama prompt runner", shell_output("#{bin}/pls help")
    assert_match "list", shell_output("#{bin}/pls help")
  end
end
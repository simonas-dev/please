class Please < Formula
  desc "Ruby wrapper for Ollama with built-in prompts"
  homepage "https://github.com/simonas-dev/please"
  url "https://github.com/simonas-dev/please.git", branch: "main"
  version "0.1.0"
  license "MIT"

  depends_on "ruby"
  depends_on "ollama"

  def install
    # Install the gem files
    lib.install Dir["lib/*"]
    
    # Install the binary
    bin.install "bin/please"
    
    # Install configuration
    etc.install "default_prompts.yml" => "please/default_prompts.yml"
    
    # Make sure the binary is executable
    chmod 0755, bin/"please"
    
    # Update the binary to use the installed lib path
    inreplace bin/"please", 
              "require_relative '../lib/ollama_wrapper'",
              "require_relative '#{lib}/ollama_wrapper'"
  end

  def caveats
    <<~EOS
      The default prompts configuration is installed at:
        #{etc}/please/default_prompts.yml
      
      Make sure Ollama is installed and running to use this tool.
      Visit https://ollama.ai for Ollama installation instructions.
    EOS
  end

  test do
    assert_match "Please - Ollama prompt runner", shell_output("#{bin}/please help")
    assert_match "list", shell_output("#{bin}/please help")
  end
end
require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name          = "please"
  spec.version       = PleaseConsts::VERSION
  spec.authors       = ["Simonas Sankauskas"]
  spec.email         = ["hello@simonas.dev"]

  spec.summary       = "A Ruby wrapper for Ollama with prompt library management"
  spec.description   = "Allows creating a library of prompts that can be aliased under shorter names for use with Ollama"
  # spec.homepage      = "https://github.com/username/ollama_wrapper"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "bin/*", "README.md", "LICENSE"]
  spec.bindir        = "bin"
  spec.executables   = ["pls"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"
end
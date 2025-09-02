# Please

A Ruby wrapper for Ollama with prompt library management. Create reusable prompts with short aliases for efficient AI interactions.

## Features

- **Prompt Library**: Store prompts in YAML files with short aliases
- **Command Substitution**: Support for `$(command)` syntax in prompts
- **Direct Ollama Integration**: Streams output directly from ollama
- **User-Friendly CLI**: Simple commands for managing and running prompts

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd please
```

2. Install dependencies:
```bash
bundle install
```

3. Make executable:
```bash
chmod +x bin/please
```

## Usage

### Running Prompts

```bash
# Run the built-in scope of impact analysis
./bin/please write_scope_of_impact

# List all available prompts
./bin/please list
```

### Managing Prompts

```bash
# Add a new prompt alias
./bin/please add my_prompt llama2 "Explain this code in simple terms" "Code explanation helper"

# Remove a prompt
./bin/please remove my_prompt

# Show help
./bin/please help
```

### Built-in Prompts

- **`write_scope_of_impact`**: Generates QA scope of impact analysis from git diff using `gpt-oss:20b`

## Configuration

- **Default prompts**: Defined in `default_prompts.yml`
- **User prompts**: Stored in `~/.ollama_wrapper/prompts.yml`
- **Command substitution**: Use `$(git diff HEAD~1)` or any shell command in prompts

## Example Prompt

```yaml
my_analysis:
  model: "llama2"
  prompt: |
    Analyze the following git changes and provide insights:
    
    $(git diff HEAD~1)
    
    Focus on potential bugs and improvements.
  description: "Code change analysis"
```

## Requirements

- Ruby >= 2.7.0
- [Ollama](https://ollama.ai) installed and available in PATH

## Development

```bash
# Install development dependencies
bundle install

# Build gem
gem build please.gemspec

# Install locally
gem install please-0.1.0.gem
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
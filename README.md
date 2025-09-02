# Please

A Ruby wrapper for Ollama with built-in prompts. Run predefined AI prompts with short aliases for efficient interactions.

## Features

- **Built-in Prompts**: Predefined prompts for common tasks
- **Command Substitution**: Support for `$(command)` syntax in prompts
- **Direct Ollama Integration**: Streams output directly from ollama
- **Context Size Validation**: Warns when prompts exceed model limits
- **Progress Indicators**: Shows thinking time and total execution time
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
./bin/please lastCommitScope

# List all available prompts
./bin/please list
```

### Help

```bash
# Show help
./bin/please help
```

### Built-in Prompts

- **`lastCommitScope`**: Generates QA scope of impact analysis from git diff using `gpt-oss:20b`

## Configuration

- **Built-in prompts**: Defined in `default_prompts.yml`
- **Command substitution**: Use `$(git diff HEAD~1)` or any shell command in prompts

## Adding New Prompts

To add new prompts, edit the `default_prompts.yml` file:

```yaml
newPrompt:
  model: "llama2"
  prompt: |
    Analyze the following git changes and provide insights:
    
    $(git diff HEAD~1)
    
    Focus on potential bugs and improvements.
  description: "Code change analysis"
```

## Output Example

```bash
$ ./bin/please lastCommitScope

Calling ollama with model: gpt-oss:20b (context: 8192 tokens, prompt: ~1250 tokens)

Thinking... (3.7s)
 Thought for 3.7s
────────────────────────────────────────────────────────────

[Analysis results here...]

────────────────────────────────────────────────────────────
  Total time: 12.4s
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
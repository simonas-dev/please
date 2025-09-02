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

### Via Homebrew (Recommended)

```bash
# Add the tap
brew tap simonas-dev/please https://github.com/simonas-dev/please.git

# Install the package
brew install ollama-please
```

## Usage

```
# Generates QA scope of impact analysis by reading `git show` output.
pls lastCommitScope

# List all available prompts
pls list

# Show help
pls help
```

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
$ pls lastCommitScope

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

## License

MIT License - see [LICENSE](LICENSE) file for details.
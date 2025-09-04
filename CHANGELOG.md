# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [1.2.0] - 2025-09-04

### Added
- **Claude Model Support**: Integrated support for Anthropic's Claude models via the `claude` CLI. RAM monitoring and automatic model stopping are disabled for Claude as it's not managed by Ollama.
- **Verbose Mode**: Introduced a `-v` flag to display the full, expanded input prompt before it's sent to the model. This is useful for debugging and verifying the final prompt content.
- **Markdown Syntax Highlighting**: Added syntax highlighting for Markdown in the model's output for improved readability.
- **Prompt Size Display**: The tool now shows the estimated token count and total character count of the input prompt before execution.
- **New Prompt Templates**: Added a `releaseNotes` template for generating release notes and a `helloWorld` example prompt.

### Changed
- The `lastCommitScope` prompt now defaults to using the `claude` model and features a more generic disclaimer.
- Improved the `releaseNotes` prompt to enhance formatting and clarity.

---
## [1.1.0] - 2025-09-02

### Changed
- Refactored the internal directory structure for better organization by moving the version file into the `lib` directory.

### Removed
- Removed internal documentation related to setting up a Homebrew tap from the project repository.

---
## [1.0.0] - 2025-09-02

### Added
- Initial stable release of the "please" CLI tool
- Ruby wrapper for Ollama with prompt library management
- Configurable prompt aliases with YAML configuration
- Command substitution support in prompts using $(command) syntax
- Model context limit checking with warnings for oversized prompts
- Real-time spinner with elapsed time during model thinking
- RAM usage monitoring showing ollama process memory consumption
- Automatic model stopping after completion to free memory
- Terminal color formatting for status messages and warnings
- Support for "Thinking..." block detection with gray formatting
- Performance optimizations for large prompts

### Features
- **Prompt Management**: Store and manage reusable prompts with aliases
- **Model Support**: Works with all ollama-supported models
- **Context Awareness**: Automatic prompt size validation against model limits
- **Resource Monitoring**: Real-time RAM usage display during execution
- **User Experience**: Clean terminal interface with progress indicators
- **Extensible**: Easy to add new prompts via YAML configuration

### Technical Details
- Built as a Ruby gem with executable binary
- Uses Open3 for streaming ollama output
- Implements background threads for spinner and RAM monitoring
- Cross-platform compatibility (tested on macOS)
- Memory efficient with automatic cleanup

## [Unreleased]
- Future enhancements and bug fixes will be documented here
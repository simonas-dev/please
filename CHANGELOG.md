# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
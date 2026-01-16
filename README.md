# HyperWhisper 🎙️✨

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2015%2B-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**AI-powered voice transcription for macOS** — Speak your thoughts, get clean text. Local-first, privacy-focused.

![HyperWhisper Demo](docs/demo.gif)

## ✨ Features

- 🎯 **Push-to-Talk**: Hold `⌥ Option` to record, release to transcribe
- 🧠 **AI Processing**: Clean up transcriptions with LLM post-processing
- 🔒 **Privacy First**: All transcription happens locally with Parakeet
- ⚡ **Blazing Fast**: Neural Engine acceleration on Apple Silicon
- 📋 **Auto-Paste**: Text automatically inserted into your active app
- 🎨 **Custom Modes**: Create personas for different use cases (coding, emails, notes...)

## 🚀 Quick Start

### Option 1: Download DMG (Recommended)
1. Download the latest `HyperWhisper-Installer.dmg` from [Releases](../../releases)
2. Drag to Applications
3. Launch and follow the onboarding wizard

### Option 2: Build from Source
```bash
git clone https://github.com/YOUR_USERNAME/HyperWhisper.git
cd HyperWhisper
./build.sh
open HyperWhisper.app
```

## 📋 Requirements

- macOS 15.0 (Sequoia) or later
- Apple Silicon (M1/M2/M3/M4) recommended
- ~500MB disk space for AI models
- Microphone access

## ⚙️ Configuration

### API Keys (Optional)
For cloud AI processing, you can configure API keys in Settings:

| Provider | Purpose | Get Key |
|----------|---------|---------|
| Gemini | File transcription | [Google AI Studio](https://aistudio.google.com/) |
| OpenRouter | Post-processing LLM | [OpenRouter](https://openrouter.ai/) |

> **Note**: Local transcription with Parakeet works without any API keys!

### Permissions
HyperWhisper needs:
- 🎤 **Microphone**: For voice recording
- ♿ **Accessibility**: For text insertion into apps

## 🔧 Development

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/HyperWhisper.git
cd HyperWhisper

# Run in debug mode
swift run

# Build release .app
./build.sh

# Create DMG for distribution
./create-dmg.sh
```

## 📁 Project Structure

```
Sources/HyperWhisper/
├── Core/           # Audio engine, AI engines
├── Models/         # SwiftData models
├── Services/       # LLM providers, system services
├── UI/             # SwiftUI views
└── HyperWhisperApp.swift
```

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [FluidAudio](https://github.com/FluidInference/FluidAudio) for Parakeet TDT integration
- [OpenRouter](https://openrouter.ai/) for unified LLM access
- Apple for Neural Engine and Swift

---

Made with ❤️ for the macOS community

# Typer

An open-source voice dictation tool for macOS that respects your privacy.

## Why Typer?

Voice dictation will (if not has) become an indispensable tool for many, offering significant productivity gains and accessibility benefits. However, existing solutions come with a serious privacy concern: they require extensive accessibility permissions that allow them to monitor *all* your activities, essentially giving them the ability to spy on everything you do on your Mac, 24/7.

### The Privacy Problem

There are two layers of privacy problem for a tool like Typer.

1. The voice and text you dictate maybe collected. But you can alwasy choose to not use dictation if the subject is too sensitive. Running this speech-to-text model locally could make it bulletproof. However, that is a trade-off with the latency and memory footprint.

2. A much bigger problem. For such tool to do a better job, it needs the context through the accessibility API. And this API is much more powerful than most people would think.

When you grant accessibility permissions to a dictation app, you're giving it:
- Access to read all window content
- Ability to monitor all keyboard and mouse inputs
- Permission to control your computer
- Continuous background monitoring capabilities

While current commercial solutions may be trustworthy, circumstances can change:
- Companies can be acquired
- Privacy policies can be updated
- Software can be compromised
- Business models can shift

### Typer's Solution

Typer is built with privacy as its cornerstone:
- 🔍 **Open Source**: Every line of code is visible and auditable
- 🔒 **Transparency**: You can see exactly how accessibility permissions are used
- 💪 **Control**: You maintain control over your data and privacy

## Features

- Voice-to-text transcription using [Groq API](https://groq.com)
- Universal text insertion across macOS applications
- Function (fn) key toggle for easy recording
- Smart handling of different application contexts (WIP)

## Requirements

- macOS 11.0 or later
- Groq API key
- Microphone permissions
- Accessibility permissions

## Installation

[Installation instructions to be added]

## Usage

1. Launch Typer
2. Grant necessary permissions
3. Hold the Function (fn) key to record
4. Release to transcribe and insert text

## License

[License information to be added]

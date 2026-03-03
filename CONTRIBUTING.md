# Contributing to HealthBrowser for macOS

First off, thank you for considering contributing to HealthBrowser! It's people like you that make this project possible.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps to reproduce the problem**
* **Provide specific examples** - Include screenshots if possible
* **Describe the behavior you observed** and what behavior you expected to see
* **Include details about your environment**:
  - macOS version
  - iOS version (for companion app)
  - Xcode version
  - Device models (Mac, iPhone, Apple Watch)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a detailed description** of the suggested enhancement
* **Explain why this enhancement would be useful** to most users
* **List any similar features** in other apps if applicable

### Pull Requests

1. **Fork the repo** and create your branch from `main`
2. **Follow the code style** - Swift conventions, meaningful names, comments for complex logic
3. **Test your changes** - Ensure app builds and runs on both iOS and macOS
4. **Update documentation** if you've changed APIs or added features
5. **Write a clear commit message** describing your changes

## Development Setup

1. Clone the repository:
```bash
git clone https://github.com/Flipajs/HealthBrowserMac.git
cd HealthBrowserMac
```

2. Open in Xcode:
```bash
open HealthBrowser.xcworkspace
```

3. Configure your Apple Developer account and signing

4. Configure CloudKit container and App Group (see README.md)

5. Build and run iOS target on iPhone (physical device required for HealthKit)

6. Build and run macOS target

## Code Style Guidelines

* Use SwiftLint for consistent code formatting
* Follow Apple's Swift API Design Guidelines
* Use meaningful variable and function names
* Add comments for complex logic
* Keep functions small and focused
* Use Swift's modern concurrency (async/await)

## Project Structure

```
HealthBrowserMac/
├── iOS/                    # iOS companion app
│   └── HealthBrowseriOS/
│       └── HealthKitManager.swift
├── macOS/                  # macOS browser app
│   └── HealthBrowserMac/
│       └── Views/
├── Shared/                 # Shared code
│   └── Models/            # CoreData models
└── docs/                   # Documentation
```

## Commit Message Guidelines

Use conventional commits format:

* `feat:` - New feature
* `fix:` - Bug fix
* `docs:` - Documentation changes
* `style:` - Code style changes (formatting)
* `refactor:` - Code refactoring
* `test:` - Adding or updating tests
* `chore:` - Maintenance tasks

Example: `feat: Add rowing workout specialization to detail view`

## Testing

* Test on physical devices (iOS and macOS)
* Verify CloudKit sync works correctly
* Test with various date ranges and data volumes
* Check performance with large datasets
* Verify export functionality (CSV/JSON)

## Questions?

Feel free to open an issue with the `question` label or reach out to filip.naiser@gmail.com

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

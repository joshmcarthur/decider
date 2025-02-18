# Decider

A lightweight iOS/iPadOS/macOS app that helps you make decisions by randomly selecting from a list of options.

## Features

- 🎲 Quick decision making from any text list
- 📋 Clipboard support for easy input
- 📷 Live text scanning
- ✅ Checkbox list support (`[ ]` and `[x]` format)
- 🎯 Share extension for use from any app
- 🎊 Fun animations and confetti effects
- 📱 Native support for iPhone, iPad, and Mac
- 🔒 Privacy-focused with no data collection

## Screenshots

See the `App Store Listing` directory for screenshots and app store resources.

## Project Structure

```
Decider/
├── Shared/                    # Shared code between main app and extensions
│   ├── AnimatedSelectionView  # Main decision UI with animations
│   └── ...
├── Decider/                   # Main app target
│   ├── ContentView           # Main app interface
│   └── DeciderApp           # App entry point
├── Decider Share Extension/   # Share extension for system-wide integration
```

## Requirements

- iOS 17.0+
- iPadOS 17.0+
- macOS 14.0+
- Xcode 15.0+

## Building

1. Clone the repository
2. Open `Decider.xcodeproj` in Xcode
3. Select your target device
4. Build and run (⌘R)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Privacy

This app is designed with privacy in mind:
- No data collection or analytics
- All processing happens on device
- History stored locally only
- No network connections

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.

## Acknowledgments

- Built with SwiftUI
- Uses VisionKit for text scanning
- Inspired by the need to make quick decisions without overthinking


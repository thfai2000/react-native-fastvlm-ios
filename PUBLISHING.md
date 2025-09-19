# Publishing Guide for react-native-fastvlm-ios

## Prerequisites

1. Make sure you have an npm account: https://www.npmjs.com/signup
2. Login to npm: `npm login`
3. Ensure your package name is available on npm

## Publishing Steps

### 1. Prepare the Library

**Prerequisites for iOS Framework Building:**
- macOS with Xcode Command Line Tools installed (`xcode-select --install`)
- iOS 13.0+ deployment target support
- Swift 5.0+ toolchain

**Build Process:**
```sh
cd FastVLMCamera
npm run clean        # Clean previous build artifacts
npm run prepare      # Build both JS/TS and iOS frameworks
```

**What `npm run prepare` does:**
1. **JavaScript/TypeScript Compilation**: Builds the React Native bridge code
2. **iOS Framework Building**: 
   - Compiles iOS frameworks using xcodebuild
   - Creates XCFramework for device + simulator support
   - Packages frameworks for npm distribution
   - Gracefully skips on non-macOS platforms

**Note**: The iOS build step will automatically skip if not running on macOS with Xcode, allowing the package to be prepared on any platform for JavaScript-only changes.

### 2. Test the Build

```sh
npm run typecheck
npm run lint
```

### 3. Update Version (if needed)

```sh
npm version patch  # or minor/major
```

### 4. Publish to npm

```sh
npm publish --access public
```

## Post-Publishing

### Install in a React Native Project

```sh
npm install react-native-fastvlm-ios
cd ios && pod install
```

### Usage Example

```tsx
import { CameraPreview, analyzeCameraData } from 'react-native-fastvlm-ios';

// Use in your component
<CameraPreview style={{ flex: 1 }} statusText="ready" />
```

## Package Structure

```
react-native-fastvlm-ios/
├── src/
│   └── index.tsx              # Main JS API
├── ios/
│   ├── FastVLMCamera.swift    # Swift bridge implementation
│   ├── FastVLM/              # FastVLM Swift files
│   └── Video/                # Camera controller files
├── example/                   # Example React Native app
├── package.json              # npm package configuration
├── react-native-fastvlm-ios.podspec  # iOS CocoaPods spec
└── README.md                 # Documentation
```

## Troubleshooting

### Common Issues

1. **Pod install fails**: Ensure iOS deployment target is 13.0+
2. **Module not found**: Make sure to run `pod install` after installation
3. **Camera permission**: Add camera usage description to Info.plist

### Support

- Check the example app in the `example/` folder
- Review the README.md for detailed usage instructions
- Open an issue on GitHub for bugs or feature requests
# Publishing Guide for react-native-fastvlm-ios

## Prerequisites

1. Make sure you have an npm account: https://www.npmjs.com/signup
2. Login to npm: `npm login`
3. Ensure your package name is available on npm

## Publishing Steps

### 1. Prepare the Library

```sh
cd FastVLMCamera
npm run clean
npm run prepare
```

### 2. Build iOS Native Components (macOS only)

```sh
npm run build-ios
```

> **Note**: This step is optional as iOS components are automatically built during `npm pack` on macOS with Xcode. On other systems, source files are packaged for compilation during installation.

### 2. Test the Build

```sh
npm run typecheck
npm run lint
npm run build-ios  # Test iOS build (macOS only)
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

## iOS Build Integration

This package includes automatic iOS library building during the packaging process to provide pre-built frameworks for npm users:

### How It Works

- **macOS with Xcode**: iOS libraries (FastVLM.framework, Video.framework) are automatically built and included when running `npm pack`
- **Other environments**: Source files are packaged for native compilation during installation
- **Smart podspec**: Automatically detects pre-built frameworks and uses them when available, falls back to source compilation otherwise

### Build Components

The iOS build process creates:
- `FastVLM.framework` - Core FastVLM functionality with MLX integration
- `Video.framework` - Camera and video processing components  
- `FastVLM App` - Contains the `FastVLMModel` class used by React Native bridge

### Benefits for npm users

**With pre-built frameworks:**
- ✅ No need to compile Swift code
- ✅ Faster `pod install` process
- ✅ Reduced build dependencies
- ✅ Consistent binary across installations

**With source compilation (fallback):**
- ✅ Full platform compatibility
- ✅ Latest Xcode/Swift support
- ✅ Customizable build configurations
- ✅ Debug symbols available

### Environment Variables

- `SKIP_IOS_BUILD=1` - Skip iOS building (useful for CI/CD on non-macOS)
- `KEEP_DSYMS=1` - Keep debug symbols in frameworks (for debugging)

### Manual Building

```sh
npm run build-ios          # Build iOS components
npm run build-ios --skip   # Skip building (test mode)
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
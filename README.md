# react-native-fastvlm-ios

React Native library for FastVLM camera integration on iOS - AI-powered visual language model for real-time camera analysis.

## Features

- 📱 Real-time camera preview with customizable status overlay
- 🤖 AI-powered visual analysis using FastVLM
- ⚡ Native iOS performance with CoreML integration
- 🎨 Customizable UI components for React Native

## Installation

```sh
npm install react-native-fastvlm-ios
```

### iOS Setup

1. Run pod install in your iOS project:
```sh
cd ios && pod install
```

2. Ensure your iOS deployment target is 13.0 or higher in your `Podfile`:
```ruby
platform :ios, '13.0'
```

3. Add camera permissions to your `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera for AI analysis</string>
```

## Usage

### Camera Preview Component

```tsx
import React, { useState } from 'react';
import { View, Button } from 'react-native';
import { CameraPreview, analyzeCameraData } from 'react-native-fastvlm-ios';

export default function App() {
  const [statusText, setStatusText] = useState('ready');

  const handleAnalyze = async () => {
    setStatusText('generating...');
    try {
      const result = await analyzeCameraData('camera_data', 'Describe what you see');
      console.log('Analysis result:', result);
      setStatusText('completed');
    } catch (error) {
      setStatusText('error');
    }
  };

  return (
    <View style={{ flex: 1 }}>
      <CameraPreview 
        style={{ flex: 1 }} 
        statusText={statusText} 
      />
      <Button title="Analyze" onPress={handleAnalyze} />
    </View>
  );
}
```

### API Reference

#### `CameraPreview`

A React Native component that displays the camera preview with customizable status text.

**Props:**
- `statusText?: string` - Text to display as status overlay (default: "generating")
- `style?: ViewStyle` - Style object for the camera view

#### `analyzeCameraData(cameraData: string, prompt: string): Promise<string>`

Analyzes camera data using FastVLM and returns AI-generated response.

**Parameters:**
- `cameraData: string` - Camera data to analyze
- `prompt: string` - Prompt for the AI analysis

**Returns:**
- `Promise<string>` - AI-generated analysis result

## Requirements

- iOS 13.0+
- React Native 0.60+
- Xcode 12+

## Model Files

This library includes pre-trained FastVLM model files. The model will be automatically included in your app bundle.

## Publishing to npm

To publish this package:

1. Build the library:
```sh
npm run prepare
```

2. Build iOS native components (macOS with Xcode only):
```sh
npm run build-ios
```

3. Package with built iOS libraries:
```sh
npm pack
```
> **Note**: The `npm pack` command will automatically build iOS libraries on macOS systems with Xcode installed via the `prepack` script. On other systems, it will skip iOS building and package source files only.

4. Publish to npm:
```sh
npm publish --access public
```

## Contributing

- [Development workflow](CONTRIBUTING.md#development-workflow)
- [Sending a pull request](CONTRIBUTING.md#sending-a-pull-request)
- [Code of conduct](CODE_OF_CONDUCT.md)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
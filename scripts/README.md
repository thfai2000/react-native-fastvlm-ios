# Scripts Documentation

This directory contains build and setup scripts for the react-native-fastvlm-ios module.

## Available Scripts

### build-ios.js

**Purpose**: Builds iOS frameworks for the React Native module during the npm prepare step.

**Usage**:
```bash
node scripts/build-ios.js [options]
```

**Options**:
- `--help`, `-h` - Show help message
- `--check` - Only check if build environment is available

**What it does**:
1. Checks if running on macOS with Xcode command line tools
2. If available, builds iOS frameworks using `xcodebuild`
3. Creates an XCFramework that supports both device and simulator
4. Copies the built frameworks to `ios/Frameworks/` for npm packaging
5. If not on macOS or Xcode not available, gracefully skips building

**Build Process**:
- Builds for iOS Device (arm64)
- Builds for iOS Simulator (x86_64 and arm64)
- Creates unified XCFramework
- Copies to package location for npm distribution

**Environment Requirements**:
- macOS with Xcode Command Line Tools installed
- Swift 5.0+ support
- iOS 13.0+ deployment target

**Integration with npm Scripts**:

The iOS build is integrated into the npm prepare workflow:

```json
{
  "scripts": {
    "clean": "del-cli lib && del-cli ios/build && del-cli ios/Frameworks",
    "build:js": "bob build",
    "build:ios": "node scripts/build-ios.js", 
    "prepare": "npm run build:js && npm run build:ios"
  }
}
```

**Platform Compatibility**:

- **macOS with Xcode**: Full iOS framework building
- **Other platforms**: JavaScript building only, iOS frameworks skipped gracefully
- **npm packaging**: Works on all platforms, includes frameworks when built

## Model Download Scripts

This directory contains scripts for downloading FastVLM models automatically during installation.

## Automatic Installation

When you install this package via npm, the models will be downloaded automatically:

```bash
npm install react-native-fastvlm-ios
```

By default, the 0.5B model is downloaded. The model files will be placed in `ios/FastVLM/model/`.

## Manual Model Download

You can also manually download different model sizes:

### Using Node.js (Cross-platform)

```bash
# Download default 0.5B model
npm run download-model

# Download specific model size
npm run download-model -- --model 1.5b
npm run download-model -- --model 7b

# Download to custom directory
npm run download-model -- --model 0.5b --dest /path/to/custom/directory
```

### Using Shell Scripts

#### macOS/Linux (Bash)
```bash
# Use the original bash script
./ios/get_pretrained_mlx_model.sh --model 0.5b --dest ios/FastVLM/model
```

#### Windows (PowerShell)
```powershell
# Use PowerShell script
.\scripts\get_pretrained_mlx_model.ps1 -Model 0.5b -Dest ios\FastVLM\model
```

## Available Models

| Model Size | Parameter Count | Quantization | File Size (approx) |
|------------|-----------------|--------------|-------------------|
| 0.5b       | 0.5 billion     | FP16         | ~1GB              |
| 1.5b       | 1.5 billion     | INT8         | ~1.5GB            |
| 7b         | 7 billion       | INT4         | ~4GB              |

## Configuration for Different Model Sizes

If you want to use a different model size by default, you can modify the `postinstall` script in `package.json`:

```json
{
  "scripts": {
    "postinstall": "node scripts/download-model.js --model 1.5b"
  }
}
```

## Troubleshooting

### Windows Users
- Ensure PowerShell execution policy allows script execution: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- The Node.js script should work out of the box on all platforms

### macOS/Linux Users
- Ensure `unzip` utility is installed: `which unzip`
- On Ubuntu/Debian: `sudo apt-get install unzip`
- On CentOS/RHEL: `sudo yum install unzip`

### Common Issues
1. **Network connectivity**: Ensure you have internet access and can reach `ml-site.cdn-apple.com`
2. **Disk space**: Make sure you have sufficient disk space for the model files
3. **Permissions**: Ensure write permissions to the destination directory

## Skipping Automatic Download

To skip automatic model download during installation, set the `SKIP_FASTVLM_DOWNLOAD` environment variable:

```bash
SKIP_FASTVLM_DOWNLOAD=1 npm install react-native-fastvlm-ios
```

## Technical Details

- Models are downloaded from Apple's CDN: `https://ml-site.cdn-apple.com/datasets/fastvlm/`
- Downloaded files are zip archives that are automatically extracted
- Temporary files are cleaned up after extraction
- If the destination directory exists and contains files, they will be cleared before extraction
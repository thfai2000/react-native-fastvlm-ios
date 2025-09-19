# Scripts

This directory contains build and model download scripts for the FastVLM iOS library.

## iOS Build Scripts

### build-ios.js

Builds iOS native components (FastVLM.framework, Video.framework, and FastVLM App) for distribution.

```bash
# Build iOS libraries (macOS with Xcode only)
npm run build-ios

# Show help
npm run build-ios -- --help

# Skip building (for testing)
npm run build-ios -- --skip
# or
SKIP_IOS_BUILD=1 npm run build-ios
```

**Features:**
- Automatically detects macOS/Xcode availability
- Builds frameworks in Release configuration
- Copies built frameworks to package directory
- Gracefully handles non-macOS environments
- Integrates with `npm pack` via prepack script

**Build Products:**
- `FastVLM.framework` - Core FastVLM functionality
- `Video.framework` - Camera/video processing
- `FastVLM App.app` - Example application

### test-ios-build.js

Tests the iOS build integration to ensure everything works correctly.

```bash
node scripts/test-ios-build.js
```

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
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const https = require('https');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

// Configuration
const MODELS = {
  '0.5b': 'llava-fastvithd_0.5b_stage3_llm.fp16',
  '1.5b': 'llava-fastvithd_1.5b_stage3_llm.int8',
  '7b': 'llava-fastvithd_7b_stage3_llm.int4'
};

const BASE_URL = 'https://ml-site.cdn-apple.com/datasets/fastvlm';
const DEFAULT_MODEL = '0.5b';

function showHelp() {
  console.log('Usage: node download-model.js [options]');
  console.log('');
  console.log('Options:');
  console.log('  --model <size>    Model size to download (0.5b, 1.5b, 7b) [default: 0.5b]');
  console.log('  --dest <dir>      Destination directory [default: ./ios/FastVLM/model]');
  console.log('  --help            Show this help message');
  console.log('');
  console.log('Available model sizes:');
  console.log('  0.5b  - 0.5B parameter model (FP16)');
  console.log('  1.5b  - 1.5B parameter model (INT8)');
  console.log('  7b    - 7B parameter model (INT4)');
}

function parseArgs() {
  const args = process.argv.slice(2);
  const config = {
    model: DEFAULT_MODEL,
    dest: path.join(__dirname, '..', 'ios', 'FastVLM', 'model')
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--model':
        if (i + 1 < args.length) {
          config.model = args[++i];
        } else {
          console.error('Error: --model requires a value');
          process.exit(1);
        }
        break;
      case '--dest':
        if (i + 1 < args.length) {
          config.dest = args[++i];
        } else {
          console.error('Error: --dest requires a value');
          process.exit(1);
        }
        break;
      case '--help':
        showHelp();
        process.exit(0);
        break;
      default:
        console.error(`Unknown parameter: ${args[i]}`);
        showHelp();
        process.exit(1);
    }
  }

  if (!MODELS[config.model]) {
    console.error(`Error: Invalid model size '${config.model}'`);
    showHelp();
    process.exit(1);
  }

  return config;
}

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    
    https.get(url, (response) => {
      if (response.statusCode !== 200) {
        reject(new Error(`HTTP ${response.statusCode}: ${response.statusMessage}`));
        return;
      }

      const totalSize = parseInt(response.headers['content-length'] || '0', 10);
      let downloadedSize = 0;

      response.on('data', (chunk) => {
        downloadedSize += chunk.length;
        if (totalSize > 0) {
          const percentage = ((downloadedSize / totalSize) * 100).toFixed(1);
          process.stdout.write(`\rDownloading... ${percentage}%`);
        }
      });

      response.pipe(file);
      
      file.on('finish', () => {
        file.close();
        console.log('\nDownload completed!');
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(dest, () => {}); // Clean up partial file
      reject(err);
    });
  });
}

async function extractZip(zipPath, extractTo) {
  const isWindows = process.platform === 'win32';
  
  try {
    if (isWindows) {
      // Use PowerShell's Expand-Archive on Windows
      const command = `powershell -Command "Expand-Archive -Path '${zipPath}' -DestinationPath '${extractTo}' -Force"`;
      await execAsync(command);
    } else {
      // Use unzip on Unix/macOS
      await execAsync(`unzip -q "${zipPath}" -d "${extractTo}"`);
    }
    console.log('Extraction completed!');
  } catch (error) {
    throw new Error(`Failed to extract zip: ${error.message}`);
  }
}

async function checkDependencies() {
  const isWindows = process.platform === 'win32';
  
  if (!isWindows) {
    try {
      await execAsync('which unzip');
    } catch (error) {
      throw new Error('unzip command not found. Please install unzip utility.');
    }
  }
  // PowerShell is available by default on Windows 10/11
}

async function downloadModel(config) {
  const modelName = MODELS[config.model];
  const tempDir = fs.mkdtempSync(path.join(require('os').tmpdir(), 'fastvlm-'));
  
  try {
    // Check dependencies
    await checkDependencies();
    
    // Create destination directory if it doesn't exist
    fs.mkdirSync(config.dest, { recursive: true });
    
    // Check if destination is not empty and prompt user
    const files = fs.readdirSync(config.dest);
    if (files.length > 0) {
      console.log(`Destination directory '${config.dest}' exists and is not empty.`);
      
      // In automated environment (like npm postinstall), just clear it
      if (process.env.npm_lifecycle_event === 'postinstall') {
        console.log('Clearing existing contents for automated installation...');
        for (const file of files) {
          fs.rmSync(path.join(config.dest, file), { recursive: true, force: true });
        }
      } else {
        // Interactive mode - this would need additional handling for user input
        console.log('Clearing existing contents and continuing...');
        for (const file of files) {
          fs.rmSync(path.join(config.dest, file), { recursive: true, force: true });
        }
      }
    }

    console.log(`\nDownloading '${modelName}' model...`);
    
    // Download paths
    const zipUrl = `${BASE_URL}/${modelName}.zip`;
    const zipPath = path.join(tempDir, `${modelName}.zip`);
    const extractPath = path.join(tempDir, modelName);

    // Download the model
    await downloadFile(zipUrl, zipPath);

    // Extract the model
    console.log('\nExtracting model...');
    fs.mkdirSync(extractPath, { recursive: true });
    await extractZip(zipPath, extractPath);

    // Copy model files to destination
    console.log('\nCopying model files to destination directory...');
    const modelDir = path.join(extractPath, modelName);
    
    if (fs.existsSync(modelDir)) {
      const modelFiles = fs.readdirSync(modelDir);
      for (const file of modelFiles) {
        const srcPath = path.join(modelDir, file);
        const destPath = path.join(config.dest, file);
        
        if (fs.lstatSync(srcPath).isDirectory()) {
          fs.cpSync(srcPath, destPath, { recursive: true });
        } else {
          fs.copyFileSync(srcPath, destPath);
        }
      }
    }

    // Verify destination directory
    const destFiles = fs.readdirSync(config.dest);
    if (destFiles.length === 0) {
      throw new Error(`Model extraction failed. Destination directory '${config.dest}' is empty.`);
    }

    console.log(`\nModel downloaded and extracted to '${config.dest}'`);
    
  } catch (error) {
    console.error(`\nError: ${error.message}`);
    process.exit(1);
  } finally {
    // Cleanup temp directory
    if (fs.existsSync(tempDir)) {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }
  }
}

// Main execution
if (require.main === module) {
  // Check if download should be skipped
  if (process.env.SKIP_FASTVLM_DOWNLOAD === '1' || process.env.SKIP_FASTVLM_DOWNLOAD === 'true') {
    console.log('Skipping FastVLM model download (SKIP_FASTVLM_DOWNLOAD is set)');
    process.exit(0);
  }

  const config = parseArgs();
  downloadModel(config);
}

module.exports = { downloadModel, MODELS };
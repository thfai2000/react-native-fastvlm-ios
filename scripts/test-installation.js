#!/usr/bin/env node

// Simple test to validate npm installation workflow
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

console.log('Testing FastVLM npm installation workflow...\n');

// Test 1: Check if package.json has correct scripts
console.log('✓ Checking package.json scripts...');
const packageJson = require('../package.json');

if (!packageJson.scripts.postinstall) {
  console.error('❌ Missing postinstall script');
  process.exit(1);
}

if (!packageJson.scripts['download-model']) {
  console.error('❌ Missing download-model script');
  process.exit(1);
}

console.log('✓ Scripts found in package.json');

// Test 2: Check if model files are excluded
console.log('✓ Checking if model files are excluded...');
const hasModelExclusion = packageJson.files.some(file => file.includes('!ios/FastVLM/model'));
if (!hasModelExclusion) {
  console.error('❌ Model files not excluded from npm package');
  process.exit(1);
}

console.log('✓ Model files are excluded from npm package');

// Test 3: Check if scripts directory is included
console.log('✓ Checking if scripts directory is included...');
const hasScriptsIncluded = packageJson.files.includes('scripts');
if (!hasScriptsIncluded) {
  console.error('❌ Scripts directory not included in npm package');
  process.exit(1);
}

console.log('✓ Scripts directory is included in npm package');

// Test 4: Validate download script exists and is executable
console.log('✓ Checking download script...');
const downloadScript = path.join(__dirname, 'download-model.js');
if (!fs.existsSync(downloadScript)) {
  console.error('❌ Download script not found');
  process.exit(1);
}

console.log('✓ Download script exists');

// Test 5: Test help command
console.log('✓ Testing help command...');
exec('node scripts/download-model.js --help', (error, stdout, stderr) => {
  if (error) {
    console.error('❌ Help command failed:', error);
    process.exit(1);
  }
  
  if (!stdout.includes('Usage:') || !stdout.includes('Available model sizes:')) {
    console.error('❌ Help output invalid');
    process.exit(1);
  }
  
  console.log('✓ Help command works correctly');
  
  // Test 6: Test skip environment variable
  console.log('✓ Testing skip environment variable...');
  exec('SKIP_FASTVLM_DOWNLOAD=1 node scripts/download-model.js', (error, stdout, stderr) => {
    if (error) {
      console.error('❌ Skip test failed:', error);
      process.exit(1);
    }
    
    if (!stdout.includes('Skipping FastVLM model download')) {
      console.error('❌ Skip functionality not working');
      process.exit(1);
    }
    
    console.log('✓ Skip functionality works correctly');
    console.log('\n🎉 All tests passed! The npm installation workflow is ready.\n');
    
    console.log('Next steps:');
    console.log('1. Test with: npm pack');
    console.log('2. Install locally: npm install react-native-fastvlm-ios-0.1.0.tgz');
    console.log('3. Publish: npm publish');
    console.log('\nUsers can skip model download with:');
    console.log('SKIP_FASTVLM_DOWNLOAD=1 npm install react-native-fastvlm-ios');
  });
});
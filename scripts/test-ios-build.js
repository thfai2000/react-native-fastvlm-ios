#!/usr/bin/env node

/**
 * Test script to validate the iOS build integration
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

console.log('Testing iOS build integration...\n');

// Test 1: Check if build script exists and is executable
console.log('✓ Checking build script...');
const buildScript = path.join(__dirname, 'build-ios.js');
if (!fs.existsSync(buildScript)) {
  console.error('❌ Build script not found');
  process.exit(1);
}

const stats = fs.statSync(buildScript);
if (!(stats.mode & parseInt('111', 8))) {
  console.error('❌ Build script is not executable');
  process.exit(1);
}

console.log('✓ Build script found and executable');

// Test 2: Check if package.json has prepack script
console.log('✓ Checking package.json scripts...');
const packageJson = require('../package.json');

if (!packageJson.scripts.prepack) {
  console.error('❌ Missing prepack script');
  process.exit(1);
}

if (!packageJson.scripts['build-ios']) {
  console.error('❌ Missing build-ios script');
  process.exit(1);
}

console.log('✓ Scripts found in package.json');

// Test 3: Test help command
console.log('✓ Testing build script help command...');
exec('node scripts/build-ios.js --help', (error, stdout, stderr) => {
  if (error) {
    console.error('❌ Help command failed:', error);
    process.exit(1);
  }
  
  if (!stdout.includes('iOS Native Library Build Script')) {
    console.error('❌ Help output invalid');
    process.exit(1);
  }
  
  console.log('✓ Help command works correctly');
  
  // Test 4: Test skip functionality
  console.log('✓ Testing skip functionality...');
  exec('SKIP_IOS_BUILD=1 node scripts/build-ios.js', (error, stdout, stderr) => {
    if (error) {
      console.error('❌ Skip test failed:', error);
      process.exit(1);
    }
    
    if (!stdout.includes('Skipping iOS build')) {
      console.error('❌ Skip functionality not working');
      process.exit(1);
    }
    
    console.log('✓ Skip functionality works correctly');
    console.log('\n🎉 All iOS build integration tests passed!\n');
    
    console.log('Next steps:');
    console.log('1. Test with: npm pack');
    console.log('2. On macOS with Xcode: npm run build-ios');
    console.log('3. Publish with: npm publish --access public');
    console.log('\nThe iOS libraries will be automatically built during npm pack on macOS systems with Xcode.');
  });
});
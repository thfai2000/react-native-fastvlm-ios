#!/usr/bin/env node

/**
 * Test script to simulate iOS framework building and packaging
 * This helps validate the package structure on non-macOS systems
 */

const fs = require('fs');
const path = require('path');

const IOS_DIR = path.join(__dirname, '..', 'ios');
const FRAMEWORKS_DIR = path.join(IOS_DIR, 'Frameworks');

console.log('🧪 Testing iOS frameworks packaging simulation...\n');

// Test 1: Create mock frameworks structure
console.log('1️⃣ Creating mock frameworks structure...');

if (fs.existsSync(FRAMEWORKS_DIR)) {
  fs.rmSync(FRAMEWORKS_DIR, { recursive: true, force: true });
}
fs.mkdirSync(FRAMEWORKS_DIR, { recursive: true });

// Create mock framework structure
const frameworks = ['FastVLM.framework', 'Video.framework'];

for (const framework of frameworks) {
  const frameworkPath = path.join(FRAMEWORKS_DIR, framework);
  fs.mkdirSync(frameworkPath, { recursive: true });
  
  // Create mock framework files
  fs.writeFileSync(path.join(frameworkPath, framework.replace('.framework', '')), 'Mock binary');
  fs.writeFileSync(path.join(frameworkPath, 'Info.plist'), '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict></dict></plist>');
  
  console.log(`   ✅ Created ${framework}`);
}

// Create frameworks built marker
const markerFile = path.join(FRAMEWORKS_DIR, '.frameworks-built');
fs.writeFileSync(markerFile, `Built on: ${new Date().toISOString()}\nFrameworks: ${frameworks.length}/${frameworks.length}\n`);
console.log(`   ✅ Created frameworks marker`);

// Test 2: Test podspec detection
console.log('\n2️⃣ Testing podspec detection...');

const podspecPath = path.join(__dirname, '..', 'react-native-fastvlm-ios.podspec');
if (fs.existsSync(podspecPath)) {
  console.log('   ✅ Podspec found');
  console.log('   📋 Frameworks should be detected during pod install');
} else {
  console.log('   ❌ Podspec not found');
}

// Test 3: Test package contents
console.log('\n3️⃣ Testing package contents...');

try {
  const { exec } = require('child_process');
  exec('npm pack --dry-run', { cwd: path.join(__dirname, '..') }, (error, stdout, stderr) => {
    if (error) {
      console.log('   ⚠️ Cannot test npm pack:', error.message);
      cleanup();
      return;
    }
    
    const hasFrameworks = stdout.includes('ios/Frameworks/FastVLM.framework') && stdout.includes('ios/Frameworks/Video.framework');
    if (hasFrameworks) {
      console.log('   ✅ Frameworks will be included in npm package');
    } else {
      console.log('   ❌ Frameworks not found in package contents');
    }
    
    cleanup();
  });
} catch (error) {
  console.log('   ⚠️ Cannot test npm pack:', error.message);
  cleanup();
}

function cleanup() {
  console.log('\n🧹 Cleaning up mock frameworks...');
  if (fs.existsSync(FRAMEWORKS_DIR)) {
    fs.rmSync(FRAMEWORKS_DIR, { recursive: true, force: true });
    console.log('   ✅ Cleaned up mock frameworks');
  }
  
  console.log('\n✨ Test completed! ');
  console.log('\nThis simulation shows how the package would work with pre-built frameworks:');
  console.log('   • Frameworks are created in ios/Frameworks/');
  console.log('   • A .frameworks-built marker indicates they are available');
  console.log('   • The podspec detects this and uses vendored_frameworks');
  console.log('   • npm users get pre-built frameworks instead of compiling from source');
}

// Handle cleanup on exit
process.on('SIGINT', cleanup);
process.on('SIGTERM', cleanup);
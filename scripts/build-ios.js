#!/usr/bin/env node

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

/**
 * iOS build script for react-native-fastvlm-ios
 * Builds the iOS frameworks needed for the React Native module
 */

const REPO_ROOT = path.resolve(__dirname, '..');
const IOS_PROJECT_DIR = path.join(REPO_ROOT, 'ios');
const XCODE_PROJECT = path.join(IOS_PROJECT_DIR, 'FastVLM.xcodeproj');
const BUILD_DIR = path.join(IOS_PROJECT_DIR, 'build');
const FRAMEWORKS_DIR = path.join(BUILD_DIR, 'Release-iphoneos');

/**
 * Check if we're running on macOS with Xcode available
 */
function checkBuildEnvironment() {
  // Check if we're on macOS
  if (os.platform() !== 'darwin') {
    console.log('⚠️  iOS building skipped: Not running on macOS');
    return false;
  }

  // Check if Xcode command line tools are available
  try {
    execSync('which xcodebuild', { stdio: 'ignore' });
    return true;
  } catch (error) {
    console.log('⚠️  iOS building skipped: xcodebuild not found. Please install Xcode Command Line Tools.');
    return false;
  }
}

/**
 * Build iOS frameworks using xcodebuild
 */
function buildIOSFrameworks() {
  console.log('🔨 Building iOS frameworks...');

  // Clean previous builds
  if (fs.existsSync(BUILD_DIR)) {
    console.log('🧹 Cleaning previous build artifacts...');
    fs.rmSync(BUILD_DIR, { recursive: true, force: true });
  }

  const buildCommands = [
    // Build for iOS Device (arm64)
    {
      name: 'iOS Device',
      cmd: [
        'xcodebuild',
        '-project', XCODE_PROJECT,
        '-scheme', 'FastVLM',
        '-configuration', 'Release',
        '-sdk', 'iphoneos',
        '-arch', 'arm64',
        'build',
        `CONFIGURATION_BUILD_DIR=${FRAMEWORKS_DIR}`,
        'SKIP_INSTALL=NO',
        'BUILD_LIBRARY_FOR_DISTRIBUTION=YES'
      ]
    },
    // Build for iOS Simulator (x86_64 and arm64)
    {
      name: 'iOS Simulator',
      cmd: [
        'xcodebuild',
        '-project', XCODE_PROJECT,
        '-scheme', 'FastVLM',
        '-configuration', 'Release',
        '-sdk', 'iphonesimulator',
        '-arch', 'x86_64',
        '-arch', 'arm64',
        'build',
        `CONFIGURATION_BUILD_DIR=${path.join(BUILD_DIR, 'Release-iphonesimulator')}`,
        'SKIP_INSTALL=NO',
        'BUILD_LIBRARY_FOR_DISTRIBUTION=YES'
      ]
    }
  ];

  for (const build of buildCommands) {
    console.log(`📱 Building ${build.name}...`);
    try {
      execSync(build.cmd.join(' '), {
        cwd: IOS_PROJECT_DIR,
        stdio: 'inherit',
        maxBuffer: 1024 * 1024 * 10 // 10MB buffer for large outputs
      });
    } catch (error) {
      console.error(`❌ Failed to build ${build.name}:`, error.message);
      process.exit(1);
    }
  }

  console.log('✅ iOS frameworks built successfully');
}

/**
 * Create XCFramework from device and simulator builds
 */
function createXCFramework() {
  console.log('🔧 Creating XCFramework...');

  const deviceFramework = path.join(BUILD_DIR, 'Release-iphoneos', 'FastVLM.framework');
  const simulatorFramework = path.join(BUILD_DIR, 'Release-iphonesimulator', 'FastVLM.framework');
  const xcframeworkPath = path.join(BUILD_DIR, 'FastVLM.xcframework');

  // Remove existing xcframework if it exists
  if (fs.existsSync(xcframeworkPath)) {
    fs.rmSync(xcframeworkPath, { recursive: true, force: true });
  }

  const createXCFrameworkCmd = [
    'xcodebuild',
    '-create-xcframework',
    '-framework', deviceFramework,
    '-framework', simulatorFramework,
    '-output', xcframeworkPath
  ];

  try {
    execSync(createXCFrameworkCmd.join(' '), {
      cwd: IOS_PROJECT_DIR,
      stdio: 'inherit'
    });
    console.log('✅ XCFramework created successfully');
  } catch (error) {
    console.error('❌ Failed to create XCFramework:', error.message);
    process.exit(1);
  }
}

/**
 * Copy built frameworks to the package location
 */
function copyFrameworks() {
  console.log('📦 Copying frameworks for npm packaging...');

  const packageFrameworksDir = path.join(REPO_ROOT, 'ios', 'Frameworks');
  const xcframeworkPath = path.join(BUILD_DIR, 'FastVLM.xcframework');

  // Create the package frameworks directory
  if (!fs.existsSync(packageFrameworksDir)) {
    fs.mkdirSync(packageFrameworksDir, { recursive: true });
  }

  // Copy XCFramework
  const destinationPath = path.join(packageFrameworksDir, 'FastVLM.xcframework');
  if (fs.existsSync(destinationPath)) {
    fs.rmSync(destinationPath, { recursive: true, force: true });
  }

  fs.cpSync(xcframeworkPath, destinationPath, { recursive: true });
  console.log('✅ Frameworks copied for npm packaging');
}

/**
 * Main build function
 */
function main() {
  console.log('🚀 Starting iOS build for react-native-fastvlm-ios...');

  if (!checkBuildEnvironment()) {
    console.log('ℹ️  iOS build skipped - not a blocker for npm package preparation');
    process.exit(0);
  }

  try {
    buildIOSFrameworks();
    createXCFramework();
    copyFrameworks();

    console.log('🎉 iOS build completed successfully!');
    console.log(`📁 Built frameworks available at: ${path.join(REPO_ROOT, 'ios', 'Frameworks')}`);
  } catch (error) {
    console.error('❌ iOS build failed:', error.message);
    process.exit(1);
  }
}

// Handle command line arguments
if (require.main === module) {
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
Usage: node build-ios.js [options]

Options:
  --help, -h     Show this help message
  --check        Only check if build environment is available

This script builds iOS frameworks for the react-native-fastvlm-ios module.
It will automatically skip building if not running on macOS with Xcode.
`);
    process.exit(0);
  }

  if (args.includes('--check')) {
    const canBuild = checkBuildEnvironment();
    console.log(`iOS build environment available: ${canBuild}`);
    process.exit(canBuild ? 0 : 1);
  }

  main();
}

module.exports = {
  checkBuildEnvironment,
  buildIOSFrameworks,
  createXCFramework,
  copyFrameworks,
  main
};
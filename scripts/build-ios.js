#!/usr/bin/env node

/**
 * Build script for iOS native components
 * Builds FastVLM.framework, Video.framework, and FastVLM App during npm pack
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

// Configuration
const IOS_PROJECT_DIR = path.join(__dirname, '..', 'ios');
const BUILD_DIR = path.join(IOS_PROJECT_DIR, 'build');
const DERIVED_DATA_DIR = path.join(BUILD_DIR, 'DerivedData');
const PROJECT_FILE = path.join(IOS_PROJECT_DIR, 'FastVLM.xcodeproj');

// Build targets in order
const BUILD_TARGETS = ['Video', 'FastVLM', 'FastVLM App'];

/**
 * Check if we're in a macOS environment with Xcode available
 */
async function checkBuildEnvironment() {
  try {
    await execAsync('which xcodebuild');
    return true;
  } catch (error) {
    return false;
  }
}

/**
 * Clean build directory
 */
async function cleanBuild() {
  console.log('🧹 Cleaning build directory...');
  
  if (fs.existsSync(BUILD_DIR)) {
    fs.rmSync(BUILD_DIR, { recursive: true, force: true });
  }
  
  fs.mkdirSync(BUILD_DIR, { recursive: true });
}

/**
 * Build a specific target
 */
async function buildTarget(target, configuration = 'Release') {
  console.log(`🔨 Building ${target} (${configuration})...`);
  
  const buildCmd = [
    'xcodebuild',
    '-project', PROJECT_FILE,
    '-target', `"${target}"`,
    '-configuration', configuration,
    '-derivedDataPath', DERIVED_DATA_DIR,
    'build'
  ].join(' ');

  try {
    const { stdout, stderr } = await execAsync(buildCmd, {
      cwd: IOS_PROJECT_DIR,
      maxBuffer: 1024 * 1024 * 10 // 10MB buffer for build output
    });
    
    console.log(`✅ Successfully built ${target}`);
    
    if (stderr && stderr.trim()) {
      console.log(`   Warnings for ${target}:`, stderr.trim());
    }
    
    return true;
  } catch (error) {
    console.error(`❌ Failed to build ${target}:`, error.message);
    
    if (error.stdout) {
      console.log('Build output:', error.stdout);
    }
    if (error.stderr) {
      console.error('Build errors:', error.stderr);
    }
    
    return false;
  }
}

/**
 * Copy built frameworks to the package
 */
async function copyBuiltFrameworks() {
  console.log('📦 Copying built frameworks...');
  
  const buildProductsDir = path.join(DERIVED_DATA_DIR, 'Build', 'Products', 'Release');
  const packageFrameworksDir = path.join(IOS_PROJECT_DIR, 'Frameworks');
  
  // Create frameworks directory in package
  if (fs.existsSync(packageFrameworksDir)) {
    fs.rmSync(packageFrameworksDir, { recursive: true, force: true });
  }
  fs.mkdirSync(packageFrameworksDir, { recursive: true });
  
  // Copy frameworks
  const frameworkNames = ['FastVLM.framework', 'Video.framework'];
  let copiedCount = 0;
  
  for (const frameworkName of frameworkNames) {
    const srcPath = path.join(buildProductsDir, frameworkName);
    const destPath = path.join(packageFrameworksDir, frameworkName);
    
    if (fs.existsSync(srcPath)) {
      // Copy the entire framework bundle
      fs.cpSync(srcPath, destPath, { recursive: true });
      console.log(`   ✅ Copied ${frameworkName}`);
      copiedCount++;
      
      // Remove debug symbols to reduce package size (but keep if explicitly requested)
      const dSymPath = path.join(packageFrameworksDir, `${frameworkName}.dSYM`);
      if (fs.existsSync(dSymPath) && !process.env.KEEP_DSYMS) {
        fs.rmSync(dSymPath, { recursive: true, force: true });
        console.log(`   🗑️ Removed debug symbols for ${frameworkName}`);
      }
      
    } else {
      console.log(`   ⚠️ ${frameworkName} not found at ${srcPath}`);
    }
  }
  
  // Create a marker file to indicate frameworks are available
  if (copiedCount > 0) {
    const markerFile = path.join(packageFrameworksDir, '.frameworks-built');
    fs.writeFileSync(markerFile, `Built on: ${new Date().toISOString()}\nFrameworks: ${copiedCount}/2\n`);
  }
  
  return copiedCount;
}

/**
 * Main build function
 */
async function buildIOS() {
  console.log('🚀 Starting iOS library build process...\n');
  
  // Check if we can build (macOS with Xcode)
  const canBuild = await checkBuildEnvironment();
  
  if (!canBuild) {
    console.log('⚠️ Xcode not available. Skipping iOS build.');
    console.log('   This is expected on non-macOS environments.');
    console.log('   The package will include source files for native compilation during installation.\n');
    return true;
  }
  
  // Check if project exists
  if (!fs.existsSync(PROJECT_FILE)) {
    console.error(`❌ Xcode project not found at ${PROJECT_FILE}`);
    return false;
  }
  
  try {
    // Clean previous builds
    await cleanBuild();
    
    // Build all targets
    let buildSuccess = true;
    for (const target of BUILD_TARGETS) {
      const success = await buildTarget(target);
      if (!success) {
        buildSuccess = false;
        // Continue building other targets even if one fails
      }
    }
    
    if (!buildSuccess) {
      console.log('\n⚠️ Some builds failed, but continuing with packaging...');
    }
    
    // Copy frameworks to package
    const copiedFrameworks = await copyBuiltFrameworks();
    
    console.log(`\n🎉 iOS build process completed!`);
    console.log(`   Built frameworks: ${copiedFrameworks}/2`);
    
    if (copiedFrameworks === 0) {
      console.log('   No frameworks were copied. This may indicate build issues.');
      return false;
    }
    
    return true;
    
  } catch (error) {
    console.error('❌ Build process failed:', error.message);
    return false;
  }
}

// Help function
function showHelp() {
  console.log('iOS Native Library Build Script');
  console.log('');
  console.log('Usage:');
  console.log('  node scripts/build-ios.js [options]');
  console.log('');
  console.log('Options:');
  console.log('  --help, -h    Show this help message');
  console.log('  --skip        Skip the build (for testing)');
  console.log('');
  console.log('Environment Variables:');
  console.log('  SKIP_IOS_BUILD=1    Skip iOS build (useful for CI/CD on Linux)');
  console.log('');
  console.log('This script builds the following iOS components:');
  console.log('  • Video.framework     - Camera/video processing');
  console.log('  • FastVLM.framework   - Core FastVLM functionality');
  console.log('  • FastVLM App         - Example application');
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.includes('-h')) {
    showHelp();
    return;
  }
  
  if (args.includes('--skip') || process.env.SKIP_IOS_BUILD === '1') {
    console.log('⏭️ Skipping iOS build (SKIP_IOS_BUILD is set or --skip flag used)');
    return;
  }
  
  const success = await buildIOS();
  
  if (!success) {
    process.exit(1);
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

module.exports = { buildIOS, checkBuildEnvironment };
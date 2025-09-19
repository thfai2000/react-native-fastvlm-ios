#!/usr/bin/env node

/**
 * Integration test for the build process
 * Tests that all parts of the iOS build integration work correctly
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const REPO_ROOT = path.resolve(__dirname, '..');

function testBuildScriptAvailability() {
  console.log('✓ Testing build script availability...');
  
  const buildScript = path.join(REPO_ROOT, 'scripts', 'build-ios.js');
  if (!fs.existsSync(buildScript)) {
    console.error('❌ Build script not found:', buildScript);
    process.exit(1);
  }

  // Test that the script can be executed
  const { checkBuildEnvironment } = require('./build-ios.js');
  const canBuild = checkBuildEnvironment();
  console.log(`   Environment check: ${canBuild ? '✅ macOS+Xcode' : '⚠️ Non-macOS (expected)'}`);
  
  console.log('✅ Build script availability test passed');
}

function testPackageJsonIntegration() {
  console.log('✓ Testing package.json integration...');
  
  const packagePath = path.join(REPO_ROOT, 'package.json');
  const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
  
  // Check scripts
  const requiredScripts = ['build:js', 'build:ios', 'prepare', 'clean'];
  for (const script of requiredScripts) {
    if (!packageJson.scripts[script]) {
      console.error(`❌ Missing script: ${script}`);
      process.exit(1);
    }
  }

  // Check that prepare calls both build steps
  const prepareScript = packageJson.scripts.prepare;
  if (!prepareScript.includes('build:js') || !prepareScript.includes('build:ios')) {
    console.error('❌ Prepare script should call both build:js and build:ios');
    process.exit(1);
  }

  console.log('✅ Package.json integration test passed');
}

function testPodspecIntegration() {
  console.log('✓ Testing podspec integration...');
  
  const podspecPath = path.join(REPO_ROOT, 'react-native-fastvlm-ios.podspec');
  const podspecContent = fs.readFileSync(podspecPath, 'utf8');
  
  // Check that it includes vendored_frameworks when Frameworks directory exists
  if (!podspecContent.includes('vendored_frameworks')) {
    console.error('❌ Podspec should include vendored_frameworks configuration');
    process.exit(1);
  }

  if (!podspecContent.includes('ios/Frameworks')) {
    console.error('❌ Podspec should reference ios/Frameworks directory');
    process.exit(1);
  }

  console.log('✅ Podspec integration test passed');
}

function testBuildProcess() {
  console.log('✓ Testing build process...');
  
  return new Promise((resolve, reject) => {
    // Test the build process (should gracefully skip on non-macOS)
    exec('npm run build:ios', { cwd: REPO_ROOT }, (error, stdout, stderr) => {
      if (error) {
        console.error('❌ Build process failed:', error);
        reject(error);
        return;
      }

      // Should either build or gracefully skip
      if (stdout.includes('iOS build completed successfully') || 
          stdout.includes('iOS building skipped')) {
        console.log('✅ Build process test passed');
        resolve();
      } else {
        console.error('❌ Unexpected build output:', stdout);
        reject(new Error('Unexpected build output'));
      }
    });
  });
}

async function runTests() {
  console.log('🚀 Running iOS build integration tests...\n');
  
  try {
    testBuildScriptAvailability();
    testPackageJsonIntegration();
    testPodspecIntegration();
    await testBuildProcess();
    
    console.log('\n🎉 All integration tests passed!');
    console.log('\n📋 Summary:');
    console.log('   ✅ iOS build script is available and functional');
    console.log('   ✅ Package.json integration is correct');
    console.log('   ✅ Podspec is configured for built frameworks');
    console.log('   ✅ Build process works (gracefully skips on non-macOS)');
    console.log('\n🔧 Ready for npm publishing with iOS library building support!');
    
  } catch (error) {
    console.error('\n❌ Integration tests failed:', error.message);
    process.exit(1);
  }
}

// Run tests if called directly
if (require.main === module) {
  runTests();
}

module.exports = { runTests };
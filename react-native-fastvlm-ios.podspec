require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-fastvlm-ios"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/thfai2000/fastvlm-camera-swift.git", :tag => "#{s.version}" }

  # Check if pre-built frameworks are available
  frameworks_dir = File.join(__dir__, "ios", "Frameworks")
  frameworks_available = File.exist?(File.join(frameworks_dir, ".frameworks-built"))

  if frameworks_available
    # Use pre-built frameworks
    s.source_files = "ios/{FastVLMCamera.swift,FastVLMCameraModule.m,FastVLMCameraViewManager.m,FastVLMCamera-Bridging-Header.h}"
    
    # Include pre-built frameworks
    s.vendored_frameworks = "ios/Frameworks/FastVLM.framework", "ios/Frameworks/Video.framework"
    
    # Preserve module maps and framework contents
    s.preserve_paths = "ios/Frameworks/**/*"
    
    puts "📦 Using pre-built frameworks from ios/Frameworks/"
  else
    # Build from source files (fallback)
    s.source_files = "ios/**/*.{h,m,mm,swift}"
    
    puts "🔨 Building from source files (no pre-built frameworks found)"
  end

  s.dependency "React-Core"
  
  # Swift specific configurations
  s.swift_version = "5.0"
  s.frameworks = 'AVFoundation', 'CoreImage', 'CoreML', 'Vision'
  
  # Include model files
  s.resources = ['ios/FastVLM/model/**/*']
end
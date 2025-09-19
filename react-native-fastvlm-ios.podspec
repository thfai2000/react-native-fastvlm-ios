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

  s.source_files = "ios/**/*.{h,m,mm,swift}"

  s.dependency "React-Core"
  
  # Swift specific configurations
  s.swift_version = "5.0"
  s.frameworks = 'AVFoundation', 'CoreImage', 'CoreML', 'Vision'
  
  # Include model files
  s.resources = ['ios/FastVLM/model/**/*']
  
  # Include pre-built frameworks if available (from npm prepare)
  if File.directory?("ios/Frameworks")
    s.vendored_frameworks = ['ios/Frameworks/**/*.xcframework']
    s.preserve_paths = ['ios/Frameworks/**/*']
  end
end
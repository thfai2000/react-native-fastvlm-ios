require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-fastvlm-ios"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "18.0" }
  s.source       = { :git => "https://github.com/thfai2000/fastvlm-camera-swift.git", :tag => "#{s.version}" }

  # Include only necessary files for the React Native library
  s.source_files = [
    "ios/*.{h,m,mm,swift}",
    "ios/FastVLM/**/*.{h,m,mm,swift}",
    "ios/Video/**/*.{h,m,mm,swift}",
    "ios/FastVLM App/FastVLMModel.swift",
    'ios/FastVLM/model/fastvithd.mlpackage'
  ]
  
  # Exclude UI files that aren't needed for the React Native library
  s.exclude_files = [
    "ios/FastVLM App/ContentView.swift",
    "ios/FastVLM App/FastVLMApp.swift", 
    "ios/FastVLM App/InfoView.swift"
  ]

  s.dependency "React-Core"
  
  # Swift Package Manager dependencies for MLX frameworks
  if defined?(:spm_dependency)
    spm_dependency(s,
      url: 'https://github.com/ml-explore/mlx-swift',
      requirement: {kind: 'upToNextMajorVersion', minimumVersion: '0.25.6'},
      products: ['MLX', 'MLXFast', 'MLXNN', 'MLXRandom']
    )
    
    spm_dependency(s,
      url: 'https://github.com/ml-explore/mlx-swift-examples',
      requirement: {kind: 'upToNextMajorVersion', minimumVersion: '2.25.7'},
      products: ['MLXLMCommon', 'MLXVLM']
    )
    
    spm_dependency(s,
      url: 'https://github.com/huggingface/swift-transformers',
      requirement: {kind: 'upToNextMajorVersion', minimumVersion: '0.1.24'},
      products: ['Transformers']
    )
    
    spm_dependency(s,
      url: 'https://github.com/maiqingqiang/Jinja',
      requirement: {kind: 'upToNextMajorVersion', minimumVersion: '1.3.0'},
      products: ['Jinja']
    )
  else
    raise "Please upgrade React Native to >=0.75.0 to use SPM dependencies in react-native-fastvlm-ios."
  end
  
  # Swift specific configurations
  s.swift_version = "5.0"
  
  # System frameworks
  s.frameworks = 'AVFoundation', 'CoreImage', 'CoreML', 'Vision'
# Include model files - CoreML models need to be treated as resources that get compiled
  s.resources = ['ios/FastVLM/model/**/*']

end
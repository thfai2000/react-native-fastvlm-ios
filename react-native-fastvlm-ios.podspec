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
  s.source       = { :git => "https://github.com/thfai2000/react-native-fastvlm-ios.git", :tag => "#{s.version}" }

  # We use a pre-compile step to build the binary frameworks for the FastVLM
  # components (so consumers don't have to compile them and their heavy SPM
  # dependencies during pod install). The precompile script (below) will
  # produce frameworks into `ios/compiled/`.
  # Keep model package files as source resources.
  # Include package source files in ios/ but exclude any SPM checkouts or
  # derived build products that may exist during local development. Those
  # artifacts (found under ios/compiled or ios/**/SourcePackages) can lead
  # to duplicate-file conflicts when multiple pods embed the same SPM
  # packages. Keep model files as resources, not source files.
  s.source_files = [
    'ios/*.{h,m,mm,swift}',
    # 'ios/**/*.{h,m,mm,swift,mlmodelc,bin,txt,json,mlmodel,mlpackage}'
  ]


  s.resource_bundles = {
    'fastvithd' => ['ios/FastVLM/model/fastvithd.mlmodelc']
  }

  # Vendored XCFrameworks produced by the build script. The build script
  # creates XCFrameworks from Swift Package Manager dependencies using
  # swift-create-xcframework tool.
  s.vendored_frameworks = [
    'ios/xcframeworks/Gzip.xcframework',
    'ios/xcframeworks/MLX.xcframework',
    'ios/xcframeworks/MLXFast.xcframework',
    'ios/xcframeworks/MLXNN.xcframework',
    'ios/xcframeworks/MLXRandom.xcframework',
    'ios/xcframeworks/MLXLMCommon.xcframework',
    'ios/xcframeworks/MLXVLM.xcframework',
    'ios/xcframeworks/MLXLLM.xcframework',
    'ios/xcframeworks/MLXEmbedders.xcframework',
    'ios/xcframeworks/Numerics.xcframework',
    'ios/xcframeworks/Transformers.xcframework',
    'ios/xcframeworks/Collections.xcframework',
    'ios/xcframeworks/ArgumentParser.xcframework',
    'ios/xcframeworks/Jinja.xcframework'
  ]

  # Run the precompile script during `pod install` so the frameworks exist
  # before the Pod is integrated. Consumers can also run the script locally.
  s.prepare_command = <<-CMD
    set -e
    echo "Running prepare_command in react-native-fastvlm-ios podspec"
    pwd
    # Only download the pretrained model if the destination folder is empty
    if [ -z "$(ls -A ./ios/FastVLM/model 2>/dev/null)" ]; then
      echo "model folder empty — downloading pretrained MLX model"
      sh ./scripts/get_pretrained_mlx_model.sh --model 0.5b --dest ./ios/FastVLM/model
    else
      echo "model folder not empty — skipping pretrained model download"
    fi

    # Build XCFrameworks from SPM dependencies
    echo "Building XCFrameworks from SPM dependencies..."
    bash ./scripts/build_spm_xcframeworks.sh
  CMD


  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_INSTALL_OBJC_HEADER' => 'NO', # ← Important if mixing Swift/Obj-C
    'APPLICATION_EXTENSION_API_ONLY' => 'NO',
    'CLANG_ENABLE_MODULES' => 'YES'
  }

  s.dependency "React-Core"
  
  # Swift specific configurations
  s.swift_version = "5.0"
  
  # Build optimizations to speed up MLX Swift package compilation
  s.compiler_flags = '-DSWIFT_PACKAGE=1'
  
  # System frameworks
  s.frameworks = 'AVFoundation', 'CoreImage', 'CoreML', 'Vision', 'SwiftUI', 'UIKit'

  
end
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
  CMD


  s.pod_target_xcconfig = {
    # 'ALLOW_TARGET_PLATFORM_SPECIALIZATION' => 'YES',
    # 'ALWAYS_SEARCH_USER_PATHS' => 'NO',
    # 'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS' => 'YES',
  'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'NO',
    # 'CLANG_ANALYZER_NONNULL' => 'YES',
    # 'CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION' => 'YES_AGGRESSIVE',
    # 'CLANG_CXX_LANGUAGE_STANDARD' => 'gnu++20',
    # 'CLANG_ENABLE_OBJC_ARC' => 'YES',
    # 'CLANG_ENABLE_OBJC_WEAK' => 'YES',
    # 'CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING' => 'YES',
    # 'CLANG_WARN_BOOL_CONVERSION' => 'YES',
    # 'CLANG_WARN_COMMA' => 'YES',
    # 'CLANG_WARN_CONSTANT_CONVERSION' => 'YES',
    # 'CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS' => 'YES',
    # 'CLANG_WARN_DIRECT_OBJC_ISA_USAGE' => 'YES_ERROR',
    # 'CLANG_WARN_DOCUMENTATION_COMMENTS' => 'YES',
    # 'CLANG_WARN_EMPTY_BODY' => 'YES',
    # 'CLANG_WARN_ENUM_CONVERSION' => 'YES',
    # 'CLANG_WARN_INFINITE_RECURSION' => 'YES',
    # 'CLANG_WARN_INT_CONVERSION' => 'YES',
    # 'CLANG_WARN_NON_LITERAL_NULL_CONVERSION' => 'YES',
    # 'CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF' => 'YES',
    # 'CLANG_WARN_OBJC_LITERAL_CONVERSION' => 'YES',
    # 'CLANG_WARN_OBJC_ROOT_CLASS' => 'YES_ERROR',
    # 'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER' => 'YES',
    # 'CLANG_WARN_RANGE_LOOP_ANALYSIS' => 'YES',
    # 'CLANG_WARN_STRICT_PROTOTYPES' => 'YES',
    # 'CLANG_WARN_SUSPICIOUS_MOVE' => 'YES',
    # 'CLANG_WARN_UNGUARDED_AVAILABILITY' => 'YES_AGGRESSIVE',
    # 'CLANG_WARN_UNREACHABLE_CODE' => 'YES',
    # 'CLANG_WARN__DUPLICATE_METHOD_MATCH' => 'YES',
    # 'CODE_SIGN_IDENTITY' => "",
    # 'CODE_SIGN_STYLE' => 'Automatic',
    # 'COPY_PHASE_STRIP' => 'NO',
    # 'CURRENT_PROJECT_VERSION' => '1',
    # 'DEAD_CODE_STRIPPING' => 'YES',
    # 'DEBUG_INFORMATION_FORMAT' => 'dwarf-with-dsym',
    # 'ENABLE_NS_ASSERTIONS' => 'NO',
    # 'ENABLE_STRICT_OBJC_MSGSEND' => 'YES',
    # 'ENABLE_USER_SCRIPT_SANDBOXING' => 'YES',
    # 'GCC_C_LANGUAGE_STANDARD' => 'gnu17',
    # 'GCC_NO_COMMON_BLOCKS' => 'YES',
    # 'GCC_WARN_64_TO_32_BIT_CONVERSION' => 'YES',
    # 'GCC_WARN_ABOUT_RETURN_TYPE' => 'YES_ERROR',
    # 'GCC_WARN_UNDECLARED_SELECTOR' => 'YES',
    # 'GCC_WARN_UNINITIALIZED_AUTOS' => 'YES_AGGRESSIVE',
    # 'GCC_WARN_UNUSED_FUNCTION' => 'YES',
    # 'GCC_WARN_UNUSED_VARIABLE' => 'YES',
    # 'GENERATE_INFOPLIST_FILE' => 'YES',
    # 'INFOPLIST_KEY_NSHumanReadableCopyright' => "",
    # 'INSTALL_PATH' => '$(LOCAL_LIBRARY_DIR)/Frameworks',
    # 'LD_RUNPATH_SEARCH_PATHS' => '@executable_path/Frameworks @loader_path/Frameworks',
    # 'LD_RUNPATH_SEARCH_PATHS[sdk=macosx*]' => '@executable_path/../Frameworks @loader_path/Frameworks',
    # 'LOCALIZATION_PREFERS_STRING_CATALOGS' => 'YES',
    # 'MODULE_VERIFIER_SUPPORTED_LANGUAGES' => 'objective-c objective-c++',
    # 'MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS' => 'gnu17 gnu++20',
    # 'MTL_ENABLE_DEBUG_INFO' => 'NO',
    # 'MTL_FAST_MATH' => 'YES',
    # 'SDKROOT' => 'auto',
    # 'SUPPORTED_PLATFORMS' => 'iphoneos iphonesimulator',
    'SWIFT_COMPILATION_MODE' => 'wholemodule',
    'SWIFT_EMIT_LOC_STRINGS' => 'YES',
    'SWIFT_INSTALL_OBJC_HEADER' => 'NO',
    # 'TARGETED_DEVICE_FAMILY' => '1,2',
    # 'VERSIONING_SYSTEM' => 'apple-generic'
  }

  s.dependency "React-Core"
  
  # Swift specific configurations
  s.swift_version = "5.0"
  
  # Build optimizations to speed up MLX Swift package compilation
  # s.compiler_flags = '-DSWIFT_PACKAGE=1'
  
  # System frameworks
  s.frameworks = 'AVFoundation', 'CoreImage', 'CoreML', 'Vision', 'SwiftUI', 'UIKit'


    
  # Swift Package Manager dependencies for MLX frameworks
  if defined?(:spm_dependency)

    spm_dependency(s,
      url: 'https://github.com/1024jp/GzipSwift',
      requirement: {kind: 'exactVersion', version: '6.0.1'},
      products: ['Gzip']
    )

    spm_dependency(s,
      url: 'https://github.com/ml-explore/mlx-swift',
      requirement: {kind: 'exactVersion', version: '0.25.6'},
      products: ['MLX', 'MLXFast', 'MLXNN', 'MLXRandom']
    )
    
    spm_dependency(s,
      url: 'https://github.com/ml-explore/mlx-swift-examples',
      requirement: {kind: 'exactVersion', version: '2.25.7'},
      products: ['MLXLMCommon', 'MLXVLM', 'MLXLLM', 'MLXEmbedders']
    )

    spm_dependency(s,
      url: 'https://github.com/apple/swift-numerics',
      requirement: {kind: 'exactVersion', version: '1.1.0'},
      products: ['Numerics']
    )
    
    spm_dependency(s,
      url: 'https://github.com/huggingface/swift-transformers',
      requirement: {kind: 'exactVersion', version: '0.1.24'},
      products: ['Transformers']
    )

    spm_dependency(s,
      url: 'https://github.com/apple/swift-collections',
      requirement: {kind: 'exactVersion', version: '1.2.1'},
      products: ['Collections']
    )

    spm_dependency(s,
      url: 'https://github.com/apple/swift-argument-parser',
      requirement: {kind: 'exactVersion', version: '1.4.0'},
      products: ['ArgumentParser']
    )
    
    spm_dependency(s,
      url: 'https://github.com/maiqingqiang/Jinja',
      requirement: {kind: 'exactVersion', version: '1.3.0'},
      products: ['Jinja']
    )
  else
    raise "Please upgrade React Native to >=0.75.0 to use SPM dependencies in react-native-fastvlm-ios."
  end
  
end
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
    'ios/FastVLM/model/fastvithd.mlpackage',
    # include compiled .mlmodel sources (prepared at pod install time)
    'ios/FastVLM/model/compiled/*.mlmodel'
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
      requirement: {kind: 'exactVersion', version: '0.25.6'},
      products: ['MLX', 'MLXFast', 'MLXNN', 'MLXRandom']
    )
    
    spm_dependency(s,
      url: 'https://github.com/ml-explore/mlx-swift-examples',
      requirement: {kind: 'exactVersion', version: '2.25.7'},
      products: ['MLXLMCommon', 'MLXVLM']
    )
    
    spm_dependency(s,
      url: 'https://github.com/huggingface/swift-transformers',
      requirement: {kind: 'exactVersion', version: '0.1.24'},
      products: ['Transformers']
    )
    
    spm_dependency(s,
      url: 'https://github.com/maiqingqiang/Jinja',
      requirement: {kind: 'exactVersion', version: '1.3.0'},
      products: ['Jinja']
    )
  else
    raise "Please upgrade React Native to >=0.75.0 to use SPM dependencies in react-native-fastvlm-ios."
  end
  
  # Swift specific configurations
  s.swift_version = "5.0"
  
  # Build optimizations to speed up MLX Swift package compilation
  s.compiler_flags = '-DSWIFT_PACKAGE=1'
  s.pod_target_xcconfig = {
    'SWIFT_OPTIMIZATION_LEVEL' => '-O',
    'SWIFT_COMPILATION_MODE' => 'wholemodule',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'ENABLE_LIBRARY_EVOLUTION' => 'YES',
    'SWIFT_SERIALIZE_DEBUGGING_OPTIONS' => 'NO',
    'SWIFT_ENABLE_BATCH_MODE' => 'YES',
    'SWIFT_WHOLE_MODULE_OPTIMIZATION' => 'YES',
    'GCC_OPTIMIZATION_LEVEL' => '3',
    'ENABLE_NS_ASSERTIONS' => 'NO',
    'VALIDATE_PRODUCT' => 'NO',
    'MTL_ENABLE_DEBUG_INFO' => 'NO',
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => 'SWIFT_PACKAGE',
    # Reduce build parallelism to avoid memory issues
    'SWIFT_EXEC' => '$(TOOLCHAIN_DIR)/usr/bin/swiftc',
    'OTHER_SWIFT_FLAGS' => '-j4'
  }
  
  # System frameworks
  s.frameworks = 'AVFoundation', 'CoreImage', 'CoreML', 'Vision'

  # Prepare command: pre-compile/extract any .mlpackage into a .mlmodel so CocoaPods will add it as a source file.
  # This runs during `pod install` and ensures Xcode sees the .mlmodel in the project sources (so it can generate the Swift model class).
  s.prepare_command = <<-RUBY
    echo "Preparing CoreML models for react-native-fastvlm-ios..."
    set -e
    PODSPEC_DIR="#{File.dirname(__FILE__)}"
    MODEL_DIR="$PODSPEC_DIR/ios/FastVLM/model"
    COMPILED_DIR="$MODEL_DIR/compiled"
    mkdir -p "$COMPILED_DIR"

    # For each .mlpackage, try to extract any .mlmodel inside. If none is found, try to compile with xcrun coremlcompiler as a best-effort fallback.
    find "$MODEL_DIR" -type d -name "*.mlpackage" | while read -r pkg; do
      echo "Processing package: $pkg"
      # look for a .mlmodel inside the package
      mlmodel=$(find "$pkg" -type f -name "*.mlmodel" -print -quit || true)
      if [ -n "$mlmodel" ]; then
        echo "Found .mlmodel inside package: $mlmodel"
        cp -f "$mlmodel" "$COMPILED_DIR/$(basename "$mlmodel")"
      else
        if command -v xcrun >/dev/null 2>&1; then
          tmpout=$(mktemp -d)
          echo "No .mlmodel found; attempting to compile package to compiled modelc: $pkg -> $tmpout"
          xcrun coremlcompiler compile "$pkg" "$tmpout" || true
          # try to locate any .mlmodel produced (some toolchains may emit one), otherwise copy the .mlmodelc as a resource fallback
          found=$(find "$tmpout" -type f -name "*.mlmodel" -print -quit || true)
          if [ -n "$found" ]; then
            cp -f "$found" "$COMPILED_DIR/$(basename "$found")"
          else
            # fallback: copy the compiled .mlmodelc directory into compiled to be included as a resource by the Pod
            # CocoaPods treats .mlmodelc as resources rather than sources; we'll copy into compiled to keep artifacts grouped
            if find "$tmpout" -type d -name "*.mlmodelc" | grep -q .; then
              for d in $(find "$tmpout" -type d -name "*.mlmodelc"); do
                dest="$COMPILED_DIR/$(basename "$d")"
                rm -rf "$dest"
                cp -R "$d" "$dest"
              done
            else
              echo "warning: no .mlmodel or .mlmodelc produced for $pkg"
            fi
          fi
          rm -rf "$tmpout"
        else
          echo "warning: xcrun not found; cannot compile $pkg"
        fi
      fi
    done
  RUBY


end
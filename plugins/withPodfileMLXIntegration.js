const { withDangerousMod } = require('@expo/config-plugins');
const { withXcodeProject } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

// All MLX Swift Package Manager dependencies required for react-native-fastvlm-ios
const DEFAULT_MLX_PACKAGES = [
  ...["MLX", "MLXFast", "MLXNN","MLXRandom"].map(productName => ({
    repositoryUrl: 'https://github.com/ml-explore/mlx-swift',
    productName: productName,
    repoName: 'mlx-swift',
    version: '0.25.6'
  })),
  ...["MLXLMCommon", "MLXVLM"].map(productName => ({
    repositoryUrl: 'https://github.com/ml-explore/mlx-swift-examples',
    productName: productName,
    repoName: 'mlx-swift-examples',
    version: '2.25.7'
  })),
  ...["Transformers"].map(productName => ({
    repositoryUrl: 'https://github.com/huggingface/swift-transformers',
    productName: productName,
    repoName: 'swift-transformers',
    version: '0.1.24'
  })),
  ...["Jinja"].map(productName => ({
    repositoryUrl: 'https://github.com/maiqingqiang/Jinja',
    productName: productName,
    repoName: 'Jinja',
    version: '1.3.0'
  })),
];

const addSingleSPMDependency = (xcodeProject, options) => {
  const { version, repositoryUrl, repoName, productName } = options;
  
  // Ensure XCRemoteSwiftPackageReference section exists
  if (!xcodeProject.hash.project.objects['XCRemoteSwiftPackageReference']) {
    xcodeProject.hash.project.objects['XCRemoteSwiftPackageReference'] = {};
  }

  // Check if this package reference already exists
  const existingRefs = xcodeProject.hash.project.objects['XCRemoteSwiftPackageReference'];
  const existingRef = Object.keys(existingRefs).find(key => 
    existingRefs[key].repositoryURL === repositoryUrl
  );
  
  let packageReferenceUUID;
  if (existingRef) {
    packageReferenceUUID = existingRef.split(' ')[0];
  } else {
    packageReferenceUUID = xcodeProject.generateUuid();
    xcodeProject.hash.project.objects['XCRemoteSwiftPackageReference'][`${packageReferenceUUID} /* XCRemoteSwiftPackageReference "${repoName}" */`] = {
      isa: 'XCRemoteSwiftPackageReference',
      repositoryURL: repositoryUrl,
      requirement: {
        kind: 'upToNextMajorVersion',
        minimumVersion: version
      }
    };

    const projectId = Object.keys(xcodeProject.hash.project.objects['PBXProject'])[0];
    if (!xcodeProject.hash.project.objects['PBXProject'][projectId]['packageReferences']) {
      xcodeProject.hash.project.objects['PBXProject'][projectId]['packageReferences'] = [];
    }
    
    const packageRefComment = `${packageReferenceUUID} /* XCRemoteSwiftPackageReference "${repoName}" */`;
    if (!xcodeProject.hash.project.objects['PBXProject'][projectId]['packageReferences'].includes(packageRefComment)) {
      xcodeProject.hash.project.objects['PBXProject'][projectId]['packageReferences'].push(packageRefComment);
    }
  }

  return packageReferenceUUID;
};

const generatePodfilePostInstallHook = () => {
  return `
post_install do |installer|
  # Configure react-native-fastvlm-ios Pod to link against Swift Package Manager dependencies
  installer.pods_project.targets.each do |target|
    if target.name == 'react-native-fastvlm-ios'
      puts "Configuring Swift Package dependencies for react-native-fastvlm-ios Pod..."
      
      # Add Swift package product dependencies to the Pod target
      main_project = installer.aggregate_targets.first.user_project
      if main_project
        swift_packages = main_project.root_object.package_references
        swift_packages.each do |package_ref|
          package = main_project.objects[package_ref]
          if package && package.repository_url
            puts "  - Found Swift package: #{package.repository_url}"
            
            # Add package products to Pod target based on repository
            case package.repository_url
            when 'https://github.com/ml-explore/mlx-swift'
              ['MLX', 'MLXFast', 'MLXNN', 'MLXRandom'].each do |product_name|
                target.frameworks_build_phase.add_file_reference(
                  main_project.objects.select { |_, obj| 
                    obj.is_a?(Xcodeproj::Project::Object::XCSwiftPackageProductDependency) && 
                    obj.product_name == product_name 
                  }.first&.last
                )
              end
            when 'https://github.com/ml-explore/mlx-swift-examples'
              ['MLXLMCommon', 'MLXVLM'].each do |product_name|
                target.frameworks_build_phase.add_file_reference(
                  main_project.objects.select { |_, obj| 
                    obj.is_a?(Xcodeproj::Project::Object::XCSwiftPackageProductDependency) && 
                    obj.product_name == product_name 
                  }.first&.last
                )
              end
            when 'https://github.com/huggingface/swift-transformers'
              ['Transformers'].each do |product_name|
                target.frameworks_build_phase.add_file_reference(
                  main_project.objects.select { |_, obj| 
                    obj.is_a?(Xcodeproj::Project::Object::XCSwiftPackageProductDependency) && 
                    obj.product_name == product_name 
                  }.first&.last
                )
              end
            when 'https://github.com/maiqingqiang/Jinja'
              ['Jinja'].each do |product_name|
                target.frameworks_build_phase.add_file_reference(
                  main_project.objects.select { |_, obj| 
                    obj.is_a?(Xcodeproj::Project::Object::XCSwiftPackageProductDependency) && 
                    obj.product_name == product_name 
                  }.first&.last
                )
              end
            end
          end
        end
      end
    end
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end`;
};

const withPodfilePostInstall = (config) => {
  return withDangerousMod(config, [
    'ios',
    async (config) => {
      const podfilePath = path.join(config.modRequest.platformProjectRoot, 'Podfile');
      
      if (fs.existsSync(podfilePath)) {
        let podfileContent = fs.readFileSync(podfilePath, 'utf8');
        
        // Check if our MLX configuration already exists
        if (!podfileContent.includes('react-native-fastvlm-ios Pod to link against Swift Package Manager')) {
          
          // Find the existing post_install block and add our code inside it
          const postInstallRegex = /(post_install do \|installer\|[\s\S]*?)([\s\S]*?end\s*end)/;
          const match = podfileContent.match(postInstallRegex);
          
          if (match) {
            const mlxConfiguration = `
    # Configure react-native-fastvlm-ios Pod to link against Swift Package Manager dependencies
    installer.pods_project.targets.each do |target|
      if target.name == 'react-native-fastvlm-ios'
        puts "Configuring Swift Package dependencies for react-native-fastvlm-ios Pod..."
        
        # Add build settings to enable Swift Package Manager dependencies
        target.build_configurations.each do |config|
          # Enable Swift Package Manager modules
          config.build_settings['SWIFT_INCLUDE_PATHS'] = ['$(inherited)', '$(SRCROOT)/../node_modules/react-native-fastvlm-ios/ios']
          config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)', '-Xfrontend', '-enable-experimental-cross-module-incremental-build']
        end
      end
    end
`;
            
            // Insert our configuration before the final 'end'
            const beforeFinalEnd = match[1] + match[2].replace(/(\s*end\s*)$/, mlxConfiguration + '$1');
            podfileContent = podfileContent.replace(postInstallRegex, beforeFinalEnd);
          } else {
            // If no post_install found, add one
            const mlxPostInstall = `
post_install do |installer|
  # Configure react-native-fastvlm-ios Pod to link against Swift Package Manager dependencies
  installer.pods_project.targets.each do |target|
    if target.name == 'react-native-fastvlm-ios'
      puts "Configuring Swift Package dependencies for react-native-fastvlm-ios Pod..."
      
      # Add build settings to enable Swift Package Manager dependencies
      target.build_configurations.each do |config|
        # Enable Swift Package Manager modules
        config.build_settings['SWIFT_INCLUDE_PATHS'] = ['$(inherited)', '$(SRCROOT)/../node_modules/react-native-fastvlm-ios/ios']
        config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)', '-Xfrontend', '-enable-experimental-cross-module-incremental-build']
      end
    end
  end
end
`;
            podfileContent += mlxPostInstall;
          }
          
          fs.writeFileSync(podfilePath, podfileContent);
          console.log('Added MLX configuration to Podfile post_install hook');
        }
      }
      
      return config;
    },
  ]);
};

const withMLXSPMDependencies = (config, userOptions = {}) => {
  // First, add Swift packages to the main project
  config = withXcodeProject(config, config => {
    console.log('Adding MLX Swift Package Manager dependencies to main project...');
    
    DEFAULT_MLX_PACKAGES.forEach(packageOptions => {
      console.log(`  - Adding ${packageOptions.productName} from ${packageOptions.repositoryUrl}`);
      addSingleSPMDependency(config.modResults, packageOptions);
    });
    
    return config;
  });
  
  // Then, modify the Podfile to link Pod targets to the Swift packages
  config = withPodfilePostInstall(config);
  
  console.log('MLX SPM dependencies configuration completed!');
  
  return config;
};

module.exports = withMLXSPMDependencies;
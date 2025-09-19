const { withXcodeProject } = require('@expo/config-plugins');

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

const addSingleSPMDependency = (xcodeProject, options, targetsToUpdate = []) => {
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
    // Use existing reference
    packageReferenceUUID = existingRef.split(' ')[0];
  } else {
    // Create new package reference
    packageReferenceUUID = xcodeProject.generateUuid();
    xcodeProject.hash.project.objects['XCRemoteSwiftPackageReference'][`${packageReferenceUUID} /* XCRemoteSwiftPackageReference "${repoName}" */`] = {
      isa: 'XCRemoteSwiftPackageReference',
      repositoryURL: repositoryUrl,
      requirement: {
        kind: 'upToNextMajorVersion',
        minimumVersion: version
      }
    };

    // Add to project package references
    const projectId = Object.keys(xcodeProject.hash.project.objects['PBXProject'])[0];
    if (!xcodeProject.hash.project.objects['PBXProject'][projectId]['packageReferences']) {
      xcodeProject.hash.project.objects['PBXProject'][projectId]['packageReferences'] = [];
    }
    
    const packageRefComment = `${packageReferenceUUID} /* XCRemoteSwiftPackageReference "${repoName}" */`;
    if (!xcodeProject.hash.project.objects['PBXProject'][projectId]['packageReferences'].includes(packageRefComment)) {
      xcodeProject.hash.project.objects['PBXProject'][projectId]['packageReferences'].push(packageRefComment);
    }
  }

  // Ensure XCSwiftPackageProductDependency section exists
  if (!xcodeProject.hash.project.objects['XCSwiftPackageProductDependency']) {
    xcodeProject.hash.project.objects['XCSwiftPackageProductDependency'] = {};
  }

  // Check if this product dependency already exists
  const existingProducts = xcodeProject.hash.project.objects['XCSwiftPackageProductDependency'];
  const existingProduct = Object.keys(existingProducts).find(key => 
    existingProducts[key].productName === productName &&
    existingProducts[key].package && existingProducts[key].package.includes(packageReferenceUUID)
  );
  
  let packageUUID;
  if (existingProduct) {
    packageUUID = existingProduct.split(' ')[0];
  } else {
    // Create new product dependency
    packageUUID = xcodeProject.generateUuid();
    xcodeProject.hash.project.objects['XCSwiftPackageProductDependency'][`${packageUUID} /* ${productName} */`] = {
      isa: 'XCSwiftPackageProductDependency',
      package: `${packageReferenceUUID} /* XCRemoteSwiftPackageReference "${repoName}" */`,
      productName: productName
    };
  }

  // Add to frameworks build phase for each target
  targetsToUpdate.forEach(targetName => {
    // Find the target in the project
    const nativeTargets = xcodeProject.hash.project.objects['PBXNativeTarget'] || {};
    const targetId = Object.keys(nativeTargets).find(key => 
      nativeTargets[key].name === targetName
    );
    
    if (!targetId) {
      console.warn(`  Warning: Target '${targetName}' not found for ${productName}`);
      return;
    }
    
    // Get the frameworks build phase for this target
    const target = nativeTargets[targetId];
    const buildPhases = target.buildPhases || [];
    
    const frameworksBuildPhaseRef = buildPhases.find(phase => {
      const phaseId = phase.replace(/ \/\*.*\*\//, ''); // Remove comment part
      const buildPhase = xcodeProject.hash.project.objects['PBXFrameworksBuildPhase'][phaseId];
      return buildPhase && buildPhase.isa === 'PBXFrameworksBuildPhase';
    });
    
    if (!frameworksBuildPhaseRef) {
      console.warn(`  Warning: No frameworks build phase found for target '${targetName}'`);
      return;
    }
    
    const buildPhaseId = frameworksBuildPhaseRef.replace(/ \/\*.*\*\//, '');
    
    if (!xcodeProject.hash.project.objects['PBXFrameworksBuildPhase'][buildPhaseId]['files']) {
      xcodeProject.hash.project.objects['PBXFrameworksBuildPhase'][buildPhaseId]['files'] = [];
    }
    
    const frameworkUUID = xcodeProject.generateUuid();
    const frameworkComment = `${frameworkUUID} /* ${productName} in Frameworks */`;
    
    // Check if this framework is already added to this target
    const existingFramework = xcodeProject.hash.project.objects['PBXFrameworksBuildPhase'][buildPhaseId]['files'].find(file => 
      file.includes(productName)
    );
    
    if (!existingFramework) {
      xcodeProject.hash.project.objects['PBXBuildFile'][`${frameworkUUID}_comment`] = `${productName} in Frameworks`;
      xcodeProject.hash.project.objects['PBXBuildFile'][frameworkUUID] = {
        isa: 'PBXBuildFile',
        productRef: packageUUID,
        productRef_comment: productName
      };
      
      xcodeProject.hash.project.objects['PBXFrameworksBuildPhase'][buildPhaseId]['files'].push(frameworkComment);
      console.log(`    - Added ${productName} to ${targetName} target`);
    }
  });
};

const withMLXSPMDependencies = (config, userOptions = {}) => {
  return withXcodeProject(config, config => {
    const packagesToAdd = DEFAULT_MLX_PACKAGES;
    
    console.log('Adding MLX Swift Package Manager dependencies...');
    
    // Add packages to all targets that need them
    const targetsToUpdate = ['example', 'react-native-fastvlm-ios']; // Main app target and Pod target
    
    packagesToAdd.forEach(packageOptions => {
      console.log(`  - Adding ${packageOptions.productName} from ${packageOptions.repositoryUrl}`);
      addSingleSPMDependency(config.modResults, packageOptions, targetsToUpdate);
    });
    
    console.log('MLX SPM dependencies added successfully!');
    
    return config;
  });
};

module.exports = withMLXSPMDependencies;
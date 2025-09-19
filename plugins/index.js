// Simple plugin that adds MLX Swift Package dependencies to the main app target
// The main dependency resolution is handled by the podspec using :spm dependencies
const withMLXSPMDependencies = require('./addSPMDependenciesToMainTarget');

module.exports = withMLXSPMDependencies;
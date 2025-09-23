const { getDefaultConfig } = require('@expo/metro-config');

module.exports = async () => {
  const defaultConfig = await getDefaultConfig(__dirname);
  return {
    ...defaultConfig,
    // Your custom configurations that might depend on defaultConfig
    resolver: {
      ...defaultConfig.resolver,
      extraNodeModules: {
        ...defaultConfig.resolver.extraNodeModules,
        // 'react-native-fastvlm-ios': require('path').resolve(__dirname, '../lib/module'),
      },
    },
  };
};
const { getDefaultConfig } = require("expo/metro-config");
const path = require("path");

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, "..");

const config = getDefaultConfig(projectRoot);
const resolvePackage = (packageName) =>
  path.dirname(require.resolve(`${packageName}/package.json`));

config.watchFolders = [workspaceRoot];
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, "node_modules"),
  path.resolve(workspaceRoot, "node_modules"),
];
config.resolver.extraNodeModules = {
  "@react-native-async-storage/async-storage": resolvePackage(
    "@react-native-async-storage/async-storage",
  ),
};

module.exports = config;

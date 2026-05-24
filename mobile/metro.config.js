const fs = require("fs");
const Module = require("module");
const path = require("path");

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, "..");

process.env.NODE_PATH = [
  path.join(projectRoot, "node_modules"),
  path.join(workspaceRoot, "node_modules"),
  process.env.NODE_PATH,
]
  .filter(Boolean)
  .join(path.delimiter);
Module._initPaths();

const { getDefaultConfig } = require("expo/metro-config");
const config = getDefaultConfig(projectRoot);
const assetExts = new Set(config.resolver.assetExts ?? []);

const packageAliases = {
  "@ihub/core": path.join(workspaceRoot, "packages/core"),
  "@ihub/design": path.join(workspaceRoot, "packages/design"),
  "@ihub/supabase": path.join(workspaceRoot, "packages/supabase"),
};

config.watchFolders = (config.watchFolders ?? []).filter((folder) =>
  fs.existsSync(folder),
);
config.resolver.nodeModulesPaths = (
  config.resolver.nodeModulesPaths ?? []
).filter((folder) => fs.existsSync(folder));
assetExts.add("glb");
config.resolver.assetExts = Array.from(assetExts);
config.resolver.extraNodeModules = {
  ...(config.resolver.extraNodeModules ?? {}),
  ...packageAliases,
};

module.exports = config;

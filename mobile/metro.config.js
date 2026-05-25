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
const existingBlockList = config.resolver.blockList
  ? Array.isArray(config.resolver.blockList)
    ? config.resolver.blockList
    : [config.resolver.blockList]
  : [];

const packageAliases = {
  "@ihub/core": path.join(workspaceRoot, "packages/core"),
  "@ihub/design": path.join(workspaceRoot, "packages/design"),
  "@ihub/supabase": path.join(workspaceRoot, "packages/supabase"),
};
const ignoredWorkspaceFolders = [path.join(workspaceRoot, "web")];
const ignoredWorkspaceFolderSet = new Set(
  ignoredWorkspaceFolders.map((folder) => path.normalize(folder)),
);
const serverOnlyPackagePaths = [
  path.join(workspaceRoot, "node_modules", "next"),
  path.join(workspaceRoot, "node_modules", "@next"),
  path.join(workspaceRoot, "node_modules", "@opentelemetry"),
  path.join(workspaceRoot, "node_modules", "@vercel"),
];
const escapeRegex = (value) => value.replace(/[|\\{}()[\]^$+*?.]/g, "\\$&");
const pathBlockPattern = (targetPath) =>
  new RegExp(`${escapeRegex(path.normalize(targetPath))}(?:[/\\\\].*)?$`);

config.watchFolders = (config.watchFolders ?? []).filter((folder) =>
  fs.existsSync(folder) && !ignoredWorkspaceFolderSet.has(path.normalize(folder)),
);
config.resolver.nodeModulesPaths = [
  path.join(projectRoot, "node_modules"),
  path.join(workspaceRoot, "node_modules"),
].filter((folder) => fs.existsSync(folder));
assetExts.add("glb");
config.resolver.assetExts = Array.from(assetExts);
config.resolver.blockList = [
  ...existingBlockList,
  ...ignoredWorkspaceFolders.map(pathBlockPattern),
  ...serverOnlyPackagePaths.map(pathBlockPattern),
];
config.resolver.extraNodeModules = {
  ...(config.resolver.extraNodeModules ?? {}),
  ...packageAliases,
};

module.exports = config;

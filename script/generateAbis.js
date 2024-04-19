const fs = require("fs");
const path = require("path");

const CONTRACTS_DIR = "src";
const ARTIFACTS_DIR = "out";
const ABI_DIR = "out/abis";

const LIB_PREFIX = "./lib/";
const LIB_ENTRY_TYPES = ["event", "error"];

function getAbsolutePath(...parts) {
  return path.join(__dirname, "..", ...parts);
}

function getFiles(path) {
  return fs.readdirSync(path).filter(function (file) {
    return fs.statSync(path + "/" + file).isFile();
  });
}

function getContracts() {
  return getFiles(getAbsolutePath(CONTRACTS_DIR)).map(
    (fileName) => fileName.split(".sol")[0],
  );
}

function getArtifactOfContract(contractName) {
  const artifactPath = getAbsolutePath(
    ARTIFACTS_DIR,
    `${contractName}.sol/${contractName}.json`,
  );
  const artifactJson = readJsonFile(artifactPath);

  return artifactJson;
}

function getLibsContracts(ast) {
  const libs = [];
  ast.nodes.forEach((node) => {
    if (
      node.nodeType === "ImportDirective" &&
      node.file.startsWith(LIB_PREFIX)
    ) {
      const libName = node.file.split("/").slice(-1)[0].split(".sol")[0];
      if (libName) {
        libs.push(libName);
      }
    }
  });
  return libs;
}

function writeAbi(contractName, abi) {
  const targetDir = getAbsolutePath(ABI_DIR);
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir);
  }
  const content = JSON.stringify(abi, null, 2);
  const file = path.join(targetDir, `${contractName}.json`);
  fs.writeFileSync(file, content);
  console.log(`${ABI_DIR}/${contractName}.json`);
}

function readJsonFile(path) {
  return JSON.parse(fs.readFileSync(path));
}

function main() {
  const contracts = getContracts();
  contracts.forEach((contractName) => {
    const { abi: contractAbi, ast } = getArtifactOfContract(contractName);
    const libsContracts = getLibsContracts(ast);

    const libsAbi = libsContracts.flatMap((libName) => {
      const { abi } = getArtifactOfContract(libName);
      return abi
        .filter((entry) => LIB_ENTRY_TYPES.includes(entry.type))
        .filter(
          (entry) =>
            !contractAbi.find(
              (item) => item.name === entry.name && item.type === entry.type,
            ),
        );
    });

    const abi = contractAbi.concat(libsAbi);
    writeAbi(contractName, abi);
  });
}

try {
  main();
} catch (error) {
  console.error(error);
  process.exitCode = 1;
}

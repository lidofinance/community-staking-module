const fs = require("node:fs");
const readline = require("node:readline");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");

const csvFiles = [
  "sources/rated-solo-staker.csv",
  "sources/obol-techne-credential.csv",
  "sources/stake-cat-solo-stakers-B.csv",
  "sources/galxe-lido-point-holders.csv",
];

async function readCsvFiles(files) {
  const addresses = {};

  for (const file of files) {
    const fileStream = fs.createReadStream(file);
    const rl = readline.createInterface({
      input: fileStream,
      crlfDelay: Infinity,
    });

    let headerSkipped = false;

    for await (const line of rl) {
      if (!headerSkipped && file === "sources/rated-solo-staker.csv") {
        headerSkipped = true;
        continue;
      }
      const [address] = line.split(","); // Assuming CSV has only one column for addresses
      if (addresses[address]) {
        addresses[address].sources.push(file);
      } else {
        addresses[address] = { sources: [file] };
      }
    }
  }

  return addresses;
}

function buildMerkleTree(addresses) {
  const tree = StandardMerkleTree.of(
    addresses.map((address) => [address]),
    ["address"],
  );
  return { tree };
}

function buildCsvContent(addresses) {
  const header = ["address", ...csvFiles.map((file) => file.split("/").pop().split(".")[0])];
  let content = header.join(",") + "\n";
  for (const address in addresses) {
    content += `${address},${csvFiles.map((file) => (addresses[address].sources.includes(file) ? "X" : "")).join(",")}\n`;
  }
  return content;
}

(async function main() {
  const addresses = await readCsvFiles(csvFiles);
  const { tree } = buildMerkleTree(Object.keys(addresses));
  console.log("Merkle Root:", tree.root);

  const proofs = {}
  for (const [i, v] of tree.entries()) {
    proofs[v[0]] = tree.getProof(i);
  }

  const content = buildCsvContent(addresses);

  fs.writeFileSync("sources.csv", content);
  fs.writeFileSync("addresses.json", JSON.stringify(Object.keys(addresses), null, 2));
  fs.writeFileSync("merkle-tree.json", JSON.stringify(tree.dump()));
  fs.writeFileSync("merkle-proofs.json", JSON.stringify(proofs));
  console.log("Merkle tree and proofs have been written to files.");

  const sources = {};
  for (const source of csvFiles) {
    sources[source] = { total: 0, unique: 0, duplicate: 0 };
  }
  for (const [address, info] of Object.entries(addresses)) {
    if (info.sources.length > 1) {
      for (const source of info.sources) {
        sources[source].total++;
        sources[source].duplicate++;
      }
      continue;
    }
    sources[info.sources[0]].total++;
    sources[info.sources[0]].unique++;
  }

  console.log("Unique addresses for each source:");
  for (const fileName in sources) {
    console.log(fileName + ":");
    const fileData = sources[fileName];
    for (const key in fileData) {
      console.log(`  ${key}:`, fileData[key]);
    }
  }
  console.log("\nTotal unique addresses:", Object.keys(addresses).length);
})();

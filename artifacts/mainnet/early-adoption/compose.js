const fs = require("node:fs");
const readline = require("node:readline");
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");

const csvFiles = [
  "sources/galxe-lido-point-holders.csv",
  "sources/lido-dappnode-buyers.csv",
  "sources/obol-techne-credentials-base.csv",
  "sources/obol-techne-credentials-bronze.csv",
  "sources/obol-techne-credentials-silver.csv",
  "sources/rated-solo-stakers.csv",
  "sources/stake-cat-gnosischain-solo-stakers.csv",
  "sources/stake-cat-rocketpool-solo-stakers.csv",
  "sources/stake-cat-solo-stakers-B.csv",
];

const performersCsvFiles = [
    "sources/csm-testnet-good-performers.csv"
]

const allCsvFiles = [...csvFiles, ...performersCsvFiles];

const csvFilesToExclude = [
    "sources/exclude/ever-slashed.csv",
    "sources/exclude/pro-node-operators.csv",
    "sources/exclude/csm-testnet-bad-performers.csv",
    "sources/exclude/rated-solo-wc-addresses.csv",
    "sources/exclude/rocketpool-solo-stakers-deposit-addresses.csv",
]


async function readCsvFiles(files) {
  const addresses = {};

  for (const file of files) {
    const fileStream = fs.createReadStream(file);
    const rl = readline.createInterface({
      input: fileStream,
      crlfDelay: Infinity,
    });

    for await (const line of rl) {
      let [address] = line.split(","); // Assuming CSV has only one column for addresses
      address = address.toLowerCase();
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
  const header = ["address", ...allCsvFiles.map((file) => file.split("/").pop().split(".")[0])];
  let content = header.join(",") + "\n";
  for (const address in addresses) {
    content += `${address},${allCsvFiles.map((file) => (addresses[address].sources.includes(file) ? "X" : "")).join(",")}\n`;
  }
  return content;
}

function buildExclusionCsvContent(addresses, excludeAddresses, goodPerformers) {
  const header = ["address", "exclusion_reason", "sources"];
  let content = header.join(",") + "\n";
  for (const address in excludeAddresses) {
    if (Object.keys(addresses).includes(address) && !Object.keys(goodPerformers).includes(address)) {
      content += `${address},${excludeAddresses[address].sources.join(";")},${addresses[address].sources.join(";")}\n`;
    }
  }
  return content;
}

(async function main() {
  const allAddresses = await readCsvFiles(csvFiles);
  const excludeAddresses = await readCsvFiles(csvFilesToExclude);

  let addresses = {...allAddresses};
  for (const address in excludeAddresses) {
    delete addresses[address];
  }

  const goodPerformers = await readCsvFiles(performersCsvFiles);
  for (const address in goodPerformers) {
    if (addresses[address]) {
      addresses[address].sources.push(...goodPerformers[address].sources);
    } else {
      addresses[address] = { sources: goodPerformers[address].sources };
    }
  }

  console.log("Total addresses:", Object.keys(allAddresses).length);
  console.log("Total excluded:", Object.keys(excludeAddresses).length);

  const { tree } = buildMerkleTree(Object.keys(addresses));
  console.log("Merkle Root:", tree.root);

  const proofs = {}
  for (const [i, v] of tree.entries()) {
    proofs[v[0]] = tree.getProof(i);
  }

  const content = buildCsvContent(addresses);
  // we do not report as excluded addresses that are in good performers list
  const exclusionContent = buildExclusionCsvContent(allAddresses, excludeAddresses, goodPerformers);

  fs.writeFileSync("sources.csv", content);
  fs.writeFileSync("addresses.json", JSON.stringify(Object.keys(addresses), null, 2));
  fs.writeFileSync("merkle-tree.json", JSON.stringify(tree.dump()));
  fs.writeFileSync("merkle-proofs.json", JSON.stringify(proofs));
  fs.writeFileSync("exclusions.csv", exclusionContent);
  console.log("Merkle tree and proofs have been written to files.");

  const sources = {};
  for (const source of allCsvFiles) {
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

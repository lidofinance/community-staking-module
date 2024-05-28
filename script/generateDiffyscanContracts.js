const fs = require("fs");
const path = require("path");

const ARTIFACTS_DIR = "artifacts";

function readJsonFile(path) {
  return JSON.parse(fs.readFileSync(path));
}

function main() {
  let result = {};
  const possibleArtifacts = fs.readdirSync(ARTIFACTS_DIR);
  if (!possibleArtifacts.includes(process.argv[2])) {
    throw new Error(
      "Invalid arg. Possible values: " + possibleArtifacts.join(", "),
    );
  }
  const transactions = readJsonFile(
    path.join(ARTIFACTS_DIR, process.argv[2], "transactions.json"),
  ).transactions;
  transactions
    .filter((tx) => tx.transactionType === "CREATE")
    .forEach((tx) => {
      result[tx.contractAddress] = tx.contractName;
    });
  console.log(JSON.stringify(result, null, 2));
}

try {
  main();
} catch (error) {
  console.error(error);
  process.exitCode = 1;
}

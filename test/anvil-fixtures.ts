import "dotenv/config";
import { ChildProcess, spawn } from "child_process";
import { sleep } from "@nomicfoundation/hardhat-verify/internal/utilities";
import chalk from "chalk";

let anvilProcess: ChildProcess;
const NETWORK_NAME = "anvil";

async function createAnvil(loggingEnabled: boolean = true) {
  let forkArg = [];
  if (process.env.RPC_URL !== undefined) {
    forkArg.push("--fork-url", process.env.RPC_URL);
  }
  const anvil = spawn("anvil", ["--port", "7545", ...forkArg], {});
  let started: boolean = false;
  anvil.stdout.on("data", (data) => {
    if (loggingEnabled) {
      const dataList = data.toString().split("\n");
      process.stdout.write(chalk.green(dataList.slice(0, 1)) + "\n");
      process.stdout.write(`${dataList.slice(1).join("\n")}`);
    }
    if (!started && data.toString().includes("Listening on")) {
      started = true;
    }
  });
  anvil.stderr.on("data", (data) => {
    process.stderr.write(chalk.red(`${data}`));
  });
  while (!started) {
    await sleep(100);
  }
  return anvil;
}

export async function anvilStart() {
  const hre = await import("hardhat");
  const networkConfig = hre.userConfig.networks?.[NETWORK_NAME] ?? {};
  const loggingEnabled =
    "loggingEnabled" in networkConfig ? networkConfig.loggingEnabled : true;
  if (hre.network.name !== NETWORK_NAME) return;

  anvilProcess = await createAnvil(loggingEnabled);

  const originalRequest = hre.network.provider.request;
  hre.network.provider.request = (args) => {
    console.log(args.method);
    if (args.method === "web3_clientVersion") {
      return new Promise((resolve) => resolve("hardhatnetwork:anvil"));
    }
    return originalRequest.apply(hre.network.provider, [args]);
  };

  console.log("Anvil started");
}

export async function anvilStop() {
  const hre = await import("hardhat");
  if (hre.network.name !== "anvil") return;

  anvilProcess.kill();
  console.log("Anvil stopped");
}

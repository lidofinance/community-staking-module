import "dotenv/config";
import { ChildProcess, spawn } from "child_process";
import { sleep } from "@nomicfoundation/hardhat-verify/internal/utilities";

let anvilProcess: ChildProcess;

async function createAnvil() {
  let forkArg = [];
  if (process.env.RPC_URL !== undefined) {
    forkArg.push("--fork-url", process.env.RPC_URL);
  }
  const anvil = spawn("anvil", ["--port", "8545", ...forkArg], {});
  let started: boolean = false;
  anvil.stdout.on("data", (data) => {
    console.log(`anvil: ${data}`);
    if (!started && data.toString().includes("Listening on")) {
      started = true;
    }
  });
  anvil.stderr.on("data", (data) => {
    console.error(`anvil error: ${data}`);
  });
  // wait until started is true
  while (!started) {
    await sleep(100);
  }
  return anvil;
}

export async function anvilStart() {
  const hardhat = await import("hardhat");

  anvilProcess = await createAnvil();

  const originalRequest = hardhat.network.provider.request;
  hardhat.network.provider.request = (args) => {
    console.log(args.method);
    if (args.method === "web3_clientVersion") {
      return new Promise((resolve) => resolve("hardhatnetwork:anvil"));
    }
    return originalRequest.apply(hardhat.network.provider, [args]);
  };

  console.log("Anvil started");
}

export async function anvilStop() {
  anvilProcess.kill();
  console.log("Anvil stopped");
}

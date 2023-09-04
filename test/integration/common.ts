export function skipIfNoRpc(this: Mocha.Context) {
  if (process.env.RPC_URL === undefined) {
    console.log("Skipping test because RPC_URL is not defined");
    this.skip();
  }
}

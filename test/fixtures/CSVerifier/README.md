The json files in the directory are created based on the **generator.mjs** script output.

The **generator.mjs** does not create the fixtures for us, because the structure is
quite complex and should reflect the structures used in the CSVerifier tests.

The **generator.mjs** script requires `finalized.bin` file to be presented with a SSZ
representation of a BeaconState which is used as a seed for our fixtures data.

Consider running the following command to obtain it (it assumes httpie to be installed):

```sh
http -d $CL_URL/eth/v2/debug/beacon/states/finalized Accept:application/octet-stream
```

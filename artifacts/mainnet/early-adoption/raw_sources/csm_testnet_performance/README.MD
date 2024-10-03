# Good and bad performers form the CSM testnet

Source data is obtained using [modified version of CSM Performance Oracle](https://github.com/lidofinance/lido-oracle/tree/feat/perf-data-collector).

[process.py](process.py) is used to compile lists for the final usage. The main points of the script are:
- All addresses ever used by bad performers were taken
- One exceptional case was excluded from the bad performers (see comment in the script)
- For all detected Sybils only the very first created Node Operator was considered
- Bad performers addresses were excluded from the good performers list
- Node Operators with insufficient participation time were not considered

## How to build

```bash
python3 process.py
```

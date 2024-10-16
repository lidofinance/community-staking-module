#!/usr/bin/env python

from collections import defaultdict
import json

with open("log.json", mode="r") as f:
  log = json.load(f)

shares_of_op = defaultdict(int)
for op_id, op in log["operators"].items():
  for v in op["validators"].values():
      perf = v["perf"]["included"] / v["perf"]["assigned"]
      if not v["slashed"] and perf > log["threshold"]:
          shares_of_op[op_id] += v["perf"]["assigned"]

total_shares = sum(shares_of_op.values())
for op_id, op_share in shares_of_op.items():
  expected = log["distributable"] * op_share // total_shares
  actual = log["operators"][op_id]["distributed"]
  diff = actual - expected
  if diff != 0:
      print(f"[{op_id}]\t{actual} != {expected}, {diff=}")

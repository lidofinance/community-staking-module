import json

INPUT_JSON = "sources/associated_operators.json"
OUTPUT_JSON = "exclude/associated_operators.json"

with open(INPUT_JSON, "r") as infile:
    data = json.load(infile)

rest_values = []
for v in data.values():
    if v and len(v) > 1:
        rest_values.extend(v[1:])

rest_values = set(rest_values)  # Remove duplicates
rest_values = map(int, rest_values)  # Convert to integers
rest_values = sorted(rest_values)  # Sort the values

with open(OUTPUT_JSON, "w") as outfile:
    json.dump(rest_values, outfile)

print(f"Rest values written to {OUTPUT_JSON}")

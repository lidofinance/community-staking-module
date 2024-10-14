import json
import csv

bad_performers_filename = 'bad_performers'
good_performers_filename = 'good_performers'
sybils_filename = 'testnet-sybils-and-self-reports.csv'

# There is one unique case related to NO 2515 and 11. These NOs were created from the same address 0x4b36DaE68ae191443FDcfF240F070Ab8D7A4e00A
# The only validator created for NO 2515 was abandoned which resulted in the inclusion of the address 0x4b36DaE68ae191443FDcfF240F070Ab8D7A4e00A
# into bad performers, At the same time NO 11 demonstrated great performance. Taking into account the fact that abandoned validator
# https://holesky.beaconcha.in/validator/8dd95aeeb2195eb91a377de7668684a0d6b6e74ead6a6308d827846413be02d7288fde8a7c7fa5481fef1a87b6389632
# was eventually exited and outstanding participation of 0x4b36DaE68ae191443FDcfF240F070Ab8D7A4e00A in the other lists,
# it was decided not to exclude this address

not_bad_performers = ['0x4b36DaE68ae191443FDcfF240F070Ab8D7A4e00A']

# Prepare bad-performers csv
bad_performers_addresses = set()
with open(f'{bad_performers_filename}.json', 'r') as file:
    data = json.load(file)
    for key in data.keys():
        # Take all addresses used by bad performers
        for addr in data[key]["used_addresses"]:
            # Exclude not_bad_performers
            if not (addr in not_bad_performers):
                bad_performers_addresses.add(addr)

bad_performers_addresses = sorted(bad_performers_addresses)

with open(f'{bad_performers_filename}.csv', 'w') as csvfile:
    writer = csv.writer(csvfile, delimiter=',',
                            quotechar='|', quoting=csv.QUOTE_MINIMAL)
    for addr in bad_performers_addresses:
        writer.writerow([addr])

# Fetch sybils
sybil_nos = set()
with open(f'{sybils_filename}', mode='r') as file:
    csvFile = csv.reader(file)
    first_line = True
    for line in csvFile:
        if first_line:
            first_line = False
            continue
        sybil_nos.add(line[2])

# NO #71 missed all blocks while operating 198 keys. This case falls under
# > Node Operators who have demonstrated malicious behavior during testnet that is not explicitly covered
# > by the performance estimation algo (like intentionally skipping block proposals);
# NO 71 should be manually excluded
presumably_malicious_nos = ["71"]

# Prepare good-performers csv
good_performers_addresses = set()
with open(f'{good_performers_filename}.json', 'r') as file:
    data = json.load(file)
    for key in data.keys():
        # Exclude sybils and presumably_malicious_nos
        if key in sybil_nos or key in presumably_malicious_nos:
            continue
        addr = data[key]["manager_address"]
        # Exclude bad performers in case of collisions 
        if addr in bad_performers_addresses:
            continue
        good_performers_addresses.add(data[key]["manager_address"])

good_performers_addresses = sorted(good_performers_addresses)

with open(f'{good_performers_filename}.csv', 'w') as csvfile:
    writer = csv.writer(csvfile, delimiter=',',
                            quotechar='|', quoting=csv.QUOTE_MINIMAL)
    for addr in good_performers_addresses:
        writer.writerow([addr])

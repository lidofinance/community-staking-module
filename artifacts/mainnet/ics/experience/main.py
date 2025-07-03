# Proof of experience
# - eth-staker list https://github.com/ethstaker/solo-stakers/tree/main
# - stake-cat list B https://github.com/Stake-Cat/Solo-Stakers/blob/main/Solo-Stakers/Solo-Stakers-B.csv
# - Obol Techne Credentials
# - SSV Verified operators
# - CSM Testnet participation
# - CSM Mainnet participation

import sys
import csv
import os
import json
from typing import Iterable

scores = {
    "eth-staker": 1,
    "stake-cat": 1,
    "obol-techne-base": 1,
    "obol-techne-bronze": 1,
    "obol-techne-silver": 1,
    "ssv-verified": 1,
    "csm-testnet": 1,
    "csm-mainnet": 1
}

MIN_SCORE = 3
MAX_SCORE = 6

def is_eth_staker(addresses: Iterable[str]) -> bool:
    """
    Check if the address is in the eth-staker list.
    """
    with open("eth-staker-solo-stakers.csv", "r") as f:
        for line in f:
            if line.strip().lower() in addresses:
                return True
    return False

def is_stake_cat(addresses: Iterable[str]) -> bool:
    """
    Check if the address is in the stake-cat list.
    """
    with open("stake-cat-solo-B.csv", "r") as f:
        for line in f:
            if line.strip().lower() in addresses:
                return True
    return False

def is_obol_techne_base(addresses: Iterable[str]) -> bool:
    """
    Check if the address is in the Obol Techne Base credentials CSV.
    """
    with open("obol-techne-credentials-base.csv", newline="") as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            if row["HolderAddress"].strip().lower() in addresses:
                return True
    return False

def is_obol_techne_bronze(addresses: Iterable[str]) -> bool:
    """
    Check if the address is in the Obol Techne Bronze credentials CSV.
    """
    with open("obol-techne-credentials-bronze.csv", newline="") as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            if row["HolderAddress"].strip().lower() in addresses:
                return True
    return False

def is_obol_techne_silver(addresses: Iterable[str]) -> bool:
    """
    Check if the address is in the Obol Techne Silver credentials CSV.
    """
    with open("obol-techne-credentials-silver.csv", newline="") as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            if row["HolderAddress"].strip().lower() in addresses:
                return True
    return False

def is_ssv_verified(addresses: Iterable[str]) -> bool:
    """
    Check if the address is in the SSV verified operators list.
    """
    with open("ssv-verified-operators.csv", "r") as f:
        for line in f:
            if line.strip().lower() in addresses:
                return True
    return False

def is_csm_testnet(addresses: Iterable[str]) -> bool:
    """
    Checks if any of the addresses is a CSM testnet operator with all validators above the threshold in all logs.
    """
    return _check_csm_performance_logs(addresses, "node_operator_addresses_hoodi.json", "hoodi-performance-logs")

def is_csm_mainnet(addresses: Iterable[str]) -> bool:
    """
    Checks if any of the addresses is a CSM Mainnet operator with all validators above the threshold in all logs.
    """
    return _check_csm_performance_logs(addresses, "node_operator_addresses_mainnet.json", "mainnet-performance-logs")

def _check_csm_performance_logs(addresses: Iterable[str], node_operators_file_name, perf_logs_dir) -> bool:
    with open(node_operators_file_name, 'r') as f:
        node_operators = json.load(f)

    address_to_id = {}
    for no_id, info in node_operators.items():
        for key in ['managerAddress', 'rewardAddress']:
            addr = info.get(key, '').lower()
            if addr:
                address_to_id[addr] = no_id

    addresses = set(addresses)
    found_ids = set(address_to_id[a] for a in addresses if a in address_to_id)
    if not found_ids:
        return False

    for fname in os.listdir(perf_logs_dir):
        if not fname.endswith('.json'):
            continue
        with open(os.path.join(perf_logs_dir, fname), 'r') as f:
            data = json.load(f)
        threshold = data.get('threshold', 0)
        operators = data.get('operators', {})
        # If any operator id for the addresses is eligible in this log, continue
        eligible_in_log = False
        for no_id in found_ids:
            no = operators.get(no_id)
            if not no:
                continue
            all_valid = True
            for v in no.get('validators', {}).values():
                perf = v.get('perf', {})
                assigned = perf.get('assigned', 0)
                included = perf.get('included', 0)
                if assigned == 0:
                    continue
                if included / assigned < threshold:
                    all_valid = False
                    break
            if all_valid:
                eligible_in_log = True
                break
        if not eligible_in_log:
            return False
    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python main.py <address1> [<address2> ...]")
        return
    addresses = set([a.strip().lower() for a in sys.argv[1:]])
    print(f"Your addresses: {', '.join(addresses)}")
    print("Checking addresses for proof of experience...")

    results = {
        "eth-staker": is_eth_staker(addresses),
        "stake-cat": is_stake_cat(addresses),
        "obol-techne-base": is_obol_techne_base(addresses),
        "obol-techne-bronze": is_obol_techne_bronze(addresses),
        "obol-techne-silver": is_obol_techne_silver(addresses),
        "ssv-verified": is_ssv_verified(addresses),
        "csm-testnet": is_csm_testnet(addresses),
        "csm-mainnet": is_csm_mainnet(addresses)
    }

    total_score = 0
    for key, present in results.items():
        print(f"{key.replace('-', ' ').title()}: {'✅' if present else '❌'}")
        if present:
            total_score += scores[key]
    print(f"Total score: {total_score}")
    if total_score < MIN_SCORE:
        print(f"❌ Score is below the minimum required in the category ({MIN_SCORE}).")
    else:
        final_score = min(total_score, MAX_SCORE)
        if total_score > MAX_SCORE:
            print(f"Score exceeds the maximum allowed for the category ({MAX_SCORE}). Final score capped at {MAX_SCORE}.")
        print(f"Final Proof of Experience score: {final_score}")

if __name__ == '__main__':
    main()

# Proof of experience
# - eth-staker list https://github.com/ethstaker/solo-stakers/tree/main
# - stake-cat list B https://github.com/Stake-Cat/Solo-Stakers/blob/main/Solo-Stakers/Solo-Stakers-B.csv
# - Obol Techne Credentials
# - SSV Verified operators
# - CSM Testnet participation
# - CSM Mainnet participation

import sys
import csv
import json
import time
from typing import Iterable
from datetime import datetime

import requests

scores = {
    # TODO exclude slashed
    "eth-staker": 6,
    "stake-cat": 6,
    "obol-techne-base": 4,
    "obol-techne-bronze": 5,
    "obol-techne-silver": 6,
    "ssv-verified": 7,
    "csm-testnet": 4,  # TODO Circles verification should give 5 here
    "csm-mainnet": 6,
    "sdvtm-testnet": 5,
    "sdvtm-mainnet": 7
}

MIN_SCORE = 5
MAX_SCORE = 8


def is_addresses_in_csv(addresses: Iterable[str], csv_file: str) -> bool:
    """
    Returns True if any address in `addresses` is found in the first column of the given CSV file.
    The CSV file should contain a single column with addresses or a header with 'Address'.
    """
    with open(csv_file, "r") as f:
        reader = csv.reader(f)
        for row in reader:
            if row and row[0].strip().lower() in addresses:
                print(f"    Found address {row[0]} in {csv_file}")
                return True
    return False


def eth_staker_score(addresses: Iterable[str]) -> int:
    """
    Returns the score for EthStaker solo-staker list if any address is present, otherwise 0.
    """
    if is_addresses_in_csv(addresses, "eth-staker-solo-stakers.csv"):
        return scores["eth-staker"]
    return 0

def stake_cat_score(addresses: Iterable[str]) -> int:
    """
    Returns the score for StakeCat solo-staker list (mainnet or gnosis) if any address is present, otherwise 0.
    """
    if is_addresses_in_csv(addresses, "stake-cat-solo-B.csv"):
        return scores["stake-cat"]
    if is_addresses_in_csv(addresses, "stake-cat-gnosischain.csv"):
        return scores["stake-cat"]
    return 0

def obol_techne_score(addresses: Iterable[str]) -> int:
    """
    Returns the highest Obol Techne credential score for the given addresses, or 0 if none found.
    """

    if is_addresses_in_csv(addresses, "obol-techne-credentials-silver.csv"):
        return scores["obol-techne-silver"]
    elif is_addresses_in_csv(addresses, "obol-techne-credentials-bronze.csv"):
        return scores["obol-techne-bronze"]
    elif is_addresses_in_csv(addresses, "obol-techne-credentials-base.csv"):
        return scores["obol-techne-base"]
    return 0

def ssv_verified_score(addresses: Iterable[str]) -> int:
    """
    Returns the score for SSV Verified Operators if any address is present, otherwise 0.
    """
    if is_addresses_in_csv(addresses, "ssv-verified-operators.csv"):
        return scores["ssv-verified"]
    return 0


def sdvtm_testnet_score(addresses: Iterable[str]) -> int:
    """
    Returns the score for SDVTM testnet participation if any address is eligible, otherwise 0.
    """
    if is_addresses_in_csv(addresses, "sdvtm-testnet.csv"):
        return scores["sdvtm-testnet"]
    return 0


def sdvtm_mainnet_score(addresses: Iterable[str]) -> int:
    """
    Returns the score for SDVTM mainnet participation if any address is eligible, otherwise 0.
    """
    if is_addresses_in_csv(addresses, "sdvtm-mainnet.csv"):
        return scores["sdvtm-mainnet"]
    return 0


def csm_testnet_score(addresses: Iterable[str]) -> int:
    """
    Returns the score for CSM testnet participation if any address is eligible, otherwise 0.
    """
    perf_reports = [
        "QmTpTekd8qV9mn46pYzT9fkHtYHyQguZrbGdF233YYibvY"
    ]
    if _check_csm_performance_logs(
            addresses,
            "node_operator_owners_hoodi.json",
            perf_reports,
            "Testnet"  # Network name for logging
    ):
        return scores["csm-testnet"]
    return 0

def csm_mainnet_score(addresses: Iterable[str]) -> int:
    """
    Returns the score for CSM mainnet participation if any address is eligible, otherwise 0.
    """
    perf_reports = [
        "QmaHU6Ah99Yk6kQVtSrN4inxqqYoU6epZ5UKyDvwdYUKAS"
    ]
    if _check_csm_performance_logs(
            addresses,
            "node_operator_owners_mainnet.json",
            perf_reports,
            "Mainnet"  # Network name for logging
    ):
        return scores["csm-mainnet"]
    return 0

def _request_performance_report(report_file, retries=3, delay=2):
    url = f"https://ipfs.io/ipfs/{report_file}"
    for attempt in range(retries):
        try:
            response = requests.get(url)
            response.raise_for_status()
            return response.json()
        except (requests.HTTPError, requests.JSONDecodeError) as e:
            print(f"Error fetching report {report_file}: {e}")
            if attempt < retries - 1:
                time.sleep(delay)
                continue
            raise e
    raise Exception(f"Failed to fetch report {report_file}")


def _check_csm_performance_logs(addresses: Iterable[str], no_owners_file_name, perf_reports, network_name) -> bool:
    """
    Returns True if any address is a node operator with all validators above the threshold in all logs.
    Used for both testnet and mainnet CSM checks.
    """
    with open(no_owners_file_name, 'r') as f:
        node_operators = json.load(f)

    address_to_id = {}
    for no_id, addr in node_operators.items():
        address_to_id[addr.lower()] = no_id

    addresses = set(addresses)
    found_ids = set(address_to_id[a] for a in addresses if a in address_to_id)
    if not found_ids:
        return False
    print(f"    Found node operator IDs for given addresses on {network_name}:", ", ".join(found_ids))

    for report in perf_reports:
        data = _request_performance_report(report)
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
                report_data = datetime.fromtimestamp(data['blockstamp']['block_timestamp'])
                report_block = data['blockstamp']['block_number']
                print(f"    {network_name} Node Operator {no_id} is eligible in performance report {report} at {report_data} (block {report_block}).")
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
    print("Checking addresses for Proof of Experience...")

    results: dict[str, int] = {
        "eth-staker": eth_staker_score(addresses),
        "stake-cat": stake_cat_score(addresses),
        "obol-techne": obol_techne_score(addresses),
        "ssv-verified": ssv_verified_score(addresses),
        "sdvtm-testnet": sdvtm_testnet_score(addresses),
        "sdvtm-mainnet": sdvtm_mainnet_score(addresses),
        "csm-testnet": csm_testnet_score(addresses),
        "csm-mainnet": csm_mainnet_score(addresses)
    }

    print("\nResults:")
    total_score = 0
    for key, score in results.items():
        print(f"    {key.replace('-', ' ').title()}: {score if score else '❌'}")
        if score:
            total_score += score
    print(f"Aggregate score from all sources: {total_score}")
    if total_score < MIN_SCORE:
        print(f"❌ The score is below the minimum required for this category ({MIN_SCORE}).")
    else:
        final_score = min(total_score, MAX_SCORE)
        if total_score > MAX_SCORE:
            print(f"Score exceeds the maximum allowed for the category ({MAX_SCORE}). Final score capped at {MAX_SCORE}.")
        print(f"Final Proof of Experience score: {final_score}")

if __name__ == '__main__':
    main()

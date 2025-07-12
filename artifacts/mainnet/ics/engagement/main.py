# Proof of engagement
import json
import sys
from typing import Iterable
import os

import requests
from web3 import Web3

scores = {
    "snapshot-vote": 1,
    "aragon-vote": 2,
    "galxe-score-4-10": 4,
    "galxe-score-above-10": 5,
    "git-poap": 2
}

MIN_SCORE = 3
MAX_SCORE = 6


def snapshot_vote(addresses: Iterable[str]) -> bool:
    """
    Check if the address has participated in Snapshot votes.
    """
    lido_space = "lido-snapshot.eth"
    query = """
    query Votes {
      votes (
        first: 1
        where: {
          space: "%s"
          voter_in: [%s]
        }
      ) {
        id
        voter
        created
        choice
        space {
          id
        }
      }
    }
    """ % (lido_space, ", ".join(map(lambda x: '"' + x + '"', addresses)))
    result = requests.get("https://hub.snapshot.org/graphql", json={"query": query}).json()
    if result["data"]["votes"]:
        return True
    return False


def aragon_vote(addresses: Iterable[str]) -> bool:
    """
    Check if the address has participated in Aragon votes.
    """
    # Ethereum mainnet RPC endpoint. Preferably use Infura or other provider allowing fetching logs with no strict range limits.
    rpc_url = os.environ.get("http://localhost:8545/")
    w3 = Web3(Web3.HTTPProvider(rpc_url))

    voting_address = Web3.to_checksum_address("0x2e59A20f205bB85a89C53f1936454680651E618e")
    voting_deployment_block = 11473216

    # event CastVote(uint256 indexed voteId, address indexed voter, bool supports, uint256 stake);
    event_signature_hash = w3.keccak(text="CastVote(uint256,address,bool,uint256)").hex()
    logs = w3.eth.get_logs({
        "fromBlock": voting_deployment_block,
        "toBlock": "latest",
        "address": voting_address,
        "topics": [event_signature_hash]
    })
    # topic1 is voteId, topic2 is voter
    for log in logs:
        voter = "0x" + log["topics"][2].hex()[-40:]
        if voter.lower() in addresses:
            return True
    return False


def galxe_scores(addresses: Iterable[str]) -> bool:
    with open("galxe_scores.json", "r") as f:
        addr_to_points = {item["address"]["address"].lower(): item["points"] for item in json.load(f)}

    score = 0
    for address in addresses:
        point = addr_to_points.get(address, 0)
        if point > 10:
            score += scores["galxe-score-above-10"]
        elif 4 <= point <= 10:
            score += scores["galxe-score-4-10"]
    return score


def gitpoap(addresses: Iterable[str]) -> bool:
    url = "https://public-api.gitpoap.io/v1"

    gitpoap_events = {
        129: "2022 NiceNode Contributor",
        807: "2023 NiceNode Contributor",
        985: "2023 Rocket Rescue Node Contributor",
        1107: "2024 Rocket Rescue Node Contributor",
        1088: "2024 CoinCashew Contributor",
        733: "2023 CoinCashew Contributor",
        512: "2022 CoinCashew Contributor",
        511: "2021 CoinCashew Contributor",
        510: "2020 CoinCashew Contributor",
        861: "2023 DAppNode Contributor",
        1133: "2025 Stereum Contributor",
        1084: "2024 Stereum Contributor",
        838: "2023 Stereum Contributor",
        122: "2022 Stereum Contributor",
        121: "2021 Stereum Contributor",
        2: "2022 Wagyu Key Gen Contributor",
        854: "2023 Wagyu Key Gen Contributor",
        23: "2021 Wagyu Key Gen Contributor"
    }
    s = requests.Session()
    a = requests.adapters.HTTPAdapter(max_retries=3)
    s.mount('https://', a)

    for event_id, event_name in gitpoap_events.items():
        response = s.get(f"{url}/gitpoaps/{event_id}/addresses")
        response.raise_for_status()

        poap_holders = response.json().get("addresses", [])
        if any(address.lower() in poap_holders for address in addresses):
            print(f"Found GitPoap for event '{event_name}'")
            return True
        else:
            print(f"No GitPoap found for event '{event_name}' in the provided addresses.")

    return False


def main():
    if len(sys.argv) < 2:
        print("Usage: python main.py <address1> [<address2> ...]")
        return
    addresses = set([a.strip().lower() for a in sys.argv[1:]])
    print(f"Your addresses: {', '.join(addresses)}")
    print("Checking addresses for proof of engagement...")

    results = {
        "snapshot-vote": snapshot_vote(addresses),
        "aragon-vote": aragon_vote(addresses),
        "galxe-score": galxe_scores(addresses),
        "git-poap": gitpoap(addresses)
    }

    total_score = sum(results.values())
    for key, present in results.items():
        print(f"{key.replace('-', ' ').title()}: {'✅' if present else '❌'}")
    print(f"Total score: {total_score}")
    if total_score < MIN_SCORE:
        print(f"❌ Score is below the minimum required in the category ({MIN_SCORE}).")
    else:
        final_score = min(total_score, MAX_SCORE)
        if total_score > MAX_SCORE:
            print(f"Score exceeds the maximum allowed for the category ({MAX_SCORE}). Final score capped at {MAX_SCORE}.")
        print(f"Final Proof of Engagement score: {final_score}")

if __name__ == '__main__':
    main()

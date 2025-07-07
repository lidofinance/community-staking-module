# Proof of engagement
import json
import sys
from typing import Iterable
import os

import requests
from web3 import Web3

scores = {
    "snapshot-vote": 1,
    "aragon-vote": 1,
    "galxe-score": 1
}

MIN_SCORE = 3
MAX_SCORE = 6

REQUIRED_GALXE_POINTS = 5


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
        eligible_addresses = [item["address"]["address"].lower() for item in json.load(f) if item["points"] >= REQUIRED_GALXE_POINTS]
    for eligible_address in eligible_addresses:
        if eligible_address in addresses:
            return True

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
        "galxe-score": galxe_scores(addresses)
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
        print(f"Final Proof of Engagement score: {final_score}")

if __name__ == '__main__':
    main()

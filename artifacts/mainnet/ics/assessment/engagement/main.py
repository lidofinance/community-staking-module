# Proof of engagement
import csv
import os
import sys
from datetime import datetime
from pathlib import Path

import requests
from web3 import Web3

scores = {
    "snapshot-vote": 1,
    "aragon-vote": 2,
    "galxe-score-4-10": 4,
    "galxe-score-above-10": 5,
    "git-poap": 2,
    "high-signal-30": 2,
    "high-signal-40": 3,
    "high-signal-60": 4,
    "high-signal-80": 5,
}

MIN_SCORE = 2
MAX_SCORE = 7

SNAPSHOT_VOTE_TIMESTAMP = 1756890119  # TODO update
REQUIRED_SNAPSHOT_VOTES = 3
REQUIRED_SNAPSHOT_VP = 100  # 100 LDO
REQUIRED_ARAGON_VOTES = 2

# TODO update dates
HIGH_SIGNAL_START_DATE = datetime(2025, 7, 1)  # YYYY, MM, DD
HIGH_SIGNAL_END_DATE = datetime(2025, 9, 3)  # YYYY, MM, DD

current_dir = Path(__file__).parent.resolve()


def snapshot_vote(addresses: set[str]) -> int:
    """
    Check if the address has participated in Snapshot votes.
    """
    lido_space = "lido-snapshot.eth"
    query = """
    query Votes {
      votes (
        first: %s
        where: {
          space: "%s"
          voter_in: [%s]
          vp_gt: %s
          created_lt: %s
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
    """ % (
        REQUIRED_SNAPSHOT_VOTES,
        lido_space,
        ", ".join(map(lambda x: '"' + x + '"', addresses)),
        REQUIRED_SNAPSHOT_VP,
        SNAPSHOT_VOTE_TIMESTAMP
    )
    response = requests.post("https://hub.snapshot.org/graphql", json={"query": query})
    response.raise_for_status()
    result = response.json()
    if "errors" in result:
        raise Exception(f"Error fetching Snapshot votes: {result['errors']}", query)
    votes_count = len(result["data"]["votes"])
    if votes_count >= REQUIRED_SNAPSHOT_VOTES:
        print(f"    Found {votes_count} Snapshot votes (in sum) for given addresses")
        return scores["snapshot-vote"]
    return 0


def aragon_vote(addresses: set[str]) -> int:
    """
    Check if the address has participated in Aragon votes.
    """

    with open(current_dir / "aragon_voters.csv", "r") as f:
        reader = csv.DictReader(f)
        total_votes_count = 0
        for row in reader:
            address = row["Address"]
            votes_count = int(row["VoteCount"])
            if address.strip().lower() in addresses:
                total_votes_count += votes_count
                print(f"    Found {votes_count} Aragon votes for address {address}")
    if total_votes_count >= REQUIRED_ARAGON_VOTES:
        return scores["aragon-vote"]
    return 0


def galxe_scores(addresses: set[str]) -> int:
    api_url = "https://graphigo.prd.galaxy.eco/query"
    lido_space_id = 22849
    query = """
        query($spaceId: Int, $cursor: String) {
      space(id:$spaceId) {
        id
        name
        loyaltyPointsRanks(first:100,cursorAfter:$cursor)
        {
          pageInfo{
            hasNextPage
            endCursor
          }
          edges {
            node {
              points
              address {
                username
                address
              }
            }
          }
        }
      }
    }
    """

    def fetch_all_items():
        cursor = None
        all_items = []
        while True:
            variables = {"spaceId": lido_space_id, "cursor": cursor}
            response = requests.post(
                api_url,
                json={"query": query, "variables": variables},
                headers={"Content-Type": "application/json"}
            )
            response.raise_for_status()
            data = response.json()['data']['space']['loyaltyPointsRanks']

            for edge in data['edges']:
                all_items.append(edge['node'])

            page_info = data['pageInfo']
            if not page_info['hasNextPage']:
                break
            cursor = page_info['endCursor']
        return all_items

    all_items = fetch_all_items()
    addr_to_points = {item["address"]["address"].lower(): item["points"] for item in all_items}

    score = 0
    for address in addresses:
        point = addr_to_points.get(address, 0)
        if point > 10:
            score = scores["galxe-score-above-10"]
            # max score, no need to check further
            print(f"    Found {point} Galxe score for address {address}")
            return score
        elif 4 <= point <= 10:
            print(f"    Found {point} Galxe score for address {address}")
            score = scores["galxe-score-4-10"]
    return score


def gitpoap(addresses: set[str]) -> int:
    url = "https://public-api.gitpoap.io/v1"

    with open(current_dir / "gitpoap_events.csv", "r") as f:
        reader = csv.DictReader(f)
        gitpoap_events = {row["ID"]: row["Name"] for row in reader}
    s = requests.Session()
    a = requests.adapters.HTTPAdapter(max_retries=3)
    s.mount('https://', a)

    final_score = 0
    for event_id, event_name in gitpoap_events.items():
        response = s.get(f"{url}/gitpoaps/{event_id}/addresses")
        response.raise_for_status()

        poap_holders = response.json().get("addresses", [])
        if any(address.lower() in poap_holders for address in addresses):
            print(f"    Found GitPoap for event '{event_name}'")
            final_score = scores["git-poap"]

    return final_score


def high_signal(addresses: set[str]) -> int:
    if api_key := os.getenv("HIGH_SIGNAL_API_KEY"):
        high_signal_url = "https://app.highsignal.xyz/api/data/v1/user"
        params = {
            "apiKey": api_key,
            "project": "lido",
            "searchType": "address",
            "startDate": HIGH_SIGNAL_START_DATE.strftime("%Y-%m-%d"),
            "endDate": HIGH_SIGNAL_END_DATE.strftime("%Y-%m-%d"),
        }

        high_signal_score = 0
        for address in addresses:
            params["searchValue"] = Web3.to_checksum_address(address)
            response = requests.get(high_signal_url, params=params)
            if response.status_code == 404:
                continue
            response.raise_for_status()
            response = response.json()
            address_score = response.get("totalScores", 0)[0]["totalScore"]

            high_signal_score = max(address_score, high_signal_score)
            print(f"    Found High-signal score {address_score} for address {address}")

        if high_signal_score == 0:
            print("    No High-signal score found for the given addresses.")
            return 0
    else:
        print("    ⚠️ For taking into account high-signal score, please visit the https://app.highsignal.xyz/ and enter the given score manually")
        try:
            high_signal_score = float(input("    High-signal score (0-100): "))
        except ValueError:
            print("    Invalid input for high-signal score. Defaulting to 0.")
            return 0
    if high_signal_score < 0 or high_signal_score > 100:
        print("    Invalid input for high-signal score. Defaulting to 0.")
        return 0
    elif 30 <= high_signal_score <= 40:
        hs_points = scores["high-signal-30"]
    elif 40 < high_signal_score <= 60:
        hs_points = scores["high-signal-40"]
    elif 60 < high_signal_score <= 80:
        hs_points = scores["high-signal-60"]
    elif high_signal_score > 80:
        hs_points = scores["high-signal-80"]
    else:
        print("    High-signal score is below the minimum threshold (30). No additional points awarded.")
        return 0
    return hs_points

def main():
    if len(sys.argv) < 2:
        print("Usage: python main.py <address1> [<address2> ...]")
        return
    addresses = set([a.strip().lower() for a in sys.argv[1:]])
    print(f"Your addresses: {', '.join(addresses)}")
    print("Checking addresses for Proof of Engagement...")

    results = {
        "snapshot-vote": snapshot_vote(addresses),
        "aragon-vote": aragon_vote(addresses),
        "galxe-score": galxe_scores(addresses),
        "git-poap": gitpoap(addresses),
        "high-signal": high_signal(addresses)
    }

    total_score = 0
    print("\nResults:")
    for key, score in results.items():
        print(f"    {key.replace('-', ' ').title()}: {score if score else '❌'}")
        if score:
            total_score += score
    print(f"Aggregate score from all sources: {total_score}")
    if total_score < MIN_SCORE:
        print(f"❌ The score is below the minimum required for this category ({MIN_SCORE}).")
        final_score = 0
    else:
        final_score = min(total_score, MAX_SCORE)
        if total_score > MAX_SCORE:
            print(f"Score exceeds the maximum allowed for the category ({MAX_SCORE}). Final score capped at {MAX_SCORE}.")
        print(f"Final Proof of Engagement score: {final_score}")
    return final_score

if __name__ == '__main__':
    main()

# Proof of engagement
import csv
import sys
from typing import Iterable

import requests

scores = {
    "snapshot-vote": 1,
    "aragon-vote": 2,
    "galxe-score-4-10": 4,
    "galxe-score-above-10": 5,
    "git-poap": 2
}

HIGH_SIGNAL_MIN_SCORE = 2
HIGH_SIGNAL_MAX_SCORE = 5

MIN_SCORE = 2
MAX_SCORE = 7

SNAPSHOT_VOTE_TIMESTAMP = 1750758263  # TODO update


def snapshot_vote(addresses: Iterable[str]) -> int:
    """
    Check if the address has participated in Snapshot votes.
    """
    lido_space = "lido-snapshot.eth"
    required_vp = 100
    required_votes_count = 3
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
        required_votes_count,
        lido_space,
        ", ".join(map(lambda x: '"' + x + '"', addresses)),
        required_vp,
        SNAPSHOT_VOTE_TIMESTAMP
    )
    result = requests.get("https://hub.snapshot.org/graphql", json={"query": query}).json()
    if len(result["data"]["votes"]) == required_votes_count:
        return scores["snapshot-vote"]
    return 0


def aragon_vote(addresses: Iterable[str]) -> int:
    """
    Check if the address has participated in Aragon votes.
    """

    with open("eligible_aragon_voters.csv", "r") as f:
        reader = csv.reader(f)
        for row in reader:
            if row and row[0].strip().lower() in addresses:
                return scores["aragon-vote"]
    return 0


def galxe_scores(addresses: Iterable[str]) -> int:
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
            score += scores["galxe-score-above-10"]
        elif 4 <= point <= 10:
            score += scores["galxe-score-4-10"]
    return score


def gitpoap(addresses: Iterable[str]) -> int:
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
            print(f"    Found GitPoap for event '{event_name}'")
            return scores["git-poap"]

    return 0


def high_signal() -> int:
    print("For taking into account high-signal score, please visit the https://app.highsignal.xyz/ and enter the given score manually")
    hs_points = 0
    try:
        high_signal_score = int(input("High-signal score (0-100): "))
    except ValueError:
        print("Invalid input for high-signal score. Defaulting to 0.")
        hs_points = 0
    else:
        if high_signal_score < 0 or high_signal_score > 100:
            print("Invalid input for high-signal score. Defaulting to 0.")
            hs_points = 0
        # - 2 points if 30 ≤ High Signal score ≤ 40
        # - 3 points if 40 < High Signal score ≤ 60
        # - 4 points if 60 < High Signal score ≤ 80
        # - 5 points if High Signal score > 80
        elif 30 <= high_signal_score <= 40:
            hs_points = 2
        elif 40 < high_signal_score <= 60:
            hs_points = 3
        elif 60 < high_signal_score <= 80:
            hs_points = 4
        elif high_signal_score > 80:
            hs_points = 5
        else:
            print("High-signal score is below the minimum threshold (30). No additional points awarded.")
    return hs_points

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
        "git-poap": gitpoap(addresses),
        "high-signal": high_signal()
    }

    total_score = 0
    for key, score in results.items():
        print(f"{key.replace('-', ' ').title()}: {score if score else '❌'}")
        if score:
            total_score += score
    print(f"Aggregate score from all categories: {total_score}")
    if total_score < MIN_SCORE:
        print(f"❌ The score is below the minimum required for this category ({MIN_SCORE}).")
    else:
        final_score = min(total_score, MAX_SCORE)
        if total_score > MAX_SCORE:
            print(f"Score exceeds the maximum allowed for the category ({MAX_SCORE}). Final score capped at {MAX_SCORE}.")
        print(f"Final Proof of Engagement score: {final_score}")

if __name__ == '__main__':
    main()

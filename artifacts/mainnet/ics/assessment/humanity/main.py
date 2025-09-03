import csv
import os
import sys
from pathlib import Path

import requests

scores = {
    "human-passport-min": 3,
    "human-passport-max": 8,
    "circles-verified": 4,
    "discord-account": 2,
    "x-account": 1
}

MIN_SCORE = 4
MAX_SCORE = 8

HUMAN_PASSPORT_SCORER_ID = 11737
HUMAN_PASSPORT_API_URL = "https://api.passport.xyz/v2/stamps/{scorer_id}/score/{address}"

current_dir = Path(__file__).parent.resolve()

def human_passport_score(addresses: set[str]) -> int:
    api_key = os.getenv("HUMAN_PASSPORT_API_KEY", None)
    if not api_key:
        print("    ⚠️ For taking into account Human Passport score, please visit the https://app.passport.xyz/#/lido_csm/ and enter the given score manually")
        try:
            final_score = float(input("    Human Passport score (0-20): "))
        except ValueError:
            print("    Invalid input for Human Passport score. Defaulting to 0.")
            return 0
    else:
        final_score = 0
        for address in addresses:
            url = HUMAN_PASSPORT_API_URL.format(scorer_id=HUMAN_PASSPORT_SCORER_ID, address=address)
            headers = {
                "X-API-Key": api_key,
            }
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            data = response.json()
            score = float(data.get("score", 0))
            if score:
                print(f"    Found Human Passport score {score} for address {address}")
            if score > final_score:
                final_score = score
    if final_score and final_score < scores["human-passport-min"]:
        print(f"    Human Passport score {final_score} is below the minimum required ({scores['human-passport-min']}).")
        return 0
    if final_score > scores["human-passport-max"]:
        print(f"    Human Passport score {final_score} exceeds the maximum allowed ({scores['human-passport-max']}). Capping to {scores['human-passport-max']}.")
        return scores["human-passport-max"]
    return final_score


def circles_verified_score(addresses: set[str]) -> int:
    with open(current_dir / "circle_group_members.csv", "r") as f:
        reader = csv.reader(f)
        for row in reader:
            if row and row[0].strip().lower() in addresses:
                print(f"    Found address {row[0]} in Circles group members")
                return scores["circles-verified"]


def discord_account_score() -> int:
    has_discord = input("⚠️ Discord account provided? (yes/no): ").strip().lower()
    if has_discord in ["yes", "y"]:
        return scores["discord-account"]
    elif has_discord in ["no", "n"]:
        print("No Discord handle provided. Returning score of 0.")
        return 0
    else:
        print("Invalid input. Please enter 'yes' or 'no'.")
        return discord_account_score()


def x_account_score() -> int:
    has_x = input("⚠️ X account provided? (yes/no): ").strip().lower()
    if has_x in ["yes", "y"]:
        return scores["x-account"]
    elif has_x in ["no", "n"]:
        print("No X handle provided. Returning score of 0.")
        return 0
    else:
        print("Invalid input. Please enter 'yes' or 'no'.")
        return x_account_score()


def main():
    if len(sys.argv) < 2:
        print("Usage: python main.py <address1> [<address2> ...]")
        return
    addresses = set([a.strip().lower() for a in sys.argv[1:]])
    print(f"Your addresses: {', '.join(addresses)}")
    print("Checking addresses for Proof of Humanity...")

    results = {
        "human-passport": human_passport_score(addresses),
        "circles-verified": circles_verified_score(addresses),
        "discord-account": discord_account_score(),
        "x-account": x_account_score(),
    }

    total_score = 0
    print("\nResults:")
    for key, score in results.items():
        print(f"    {key.replace('-', ' ').title()}: {str(score) + ' ✅' if score else '❌'}")
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
        print(f"Final Proof of Humanity score: {final_score}")
    return final_score

if __name__ == '__main__':
    main()

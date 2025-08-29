
import csv
import requests

def main():
    items = requests.get("https://api.ssv.network/api/v4/mainnet/operators?type=verified_operator&page=1&perPage=1000").json()["operators"]
    output_csv = "ssv-verified-operators.csv"

    items = set([item["owner_address"] for item in items])

    with open(output_csv, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        for address in items:
            writer.writerow([address])

if __name__ == "__main__":
    main()


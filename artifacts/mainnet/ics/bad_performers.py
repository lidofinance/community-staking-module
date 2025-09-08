import json
import time

import requests

with open("sources/ea.json", "r") as file:
    EA_NOS = json.load(file)

PERFORMANCE_REPORTS = [
    "QmaHU6Ah99Yk6kQVtSrN4inxqqYoU6epZ5UKyDvwdYUKAS",  # 05/2025
    "Qmemm9gD2fQgwNziBsf9mAaveNXJ3eJvHpqBTWKoLdUXXV"  # 06/2025
]

def request_performance_report(report_file, retries=3, delay=2):
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


def process_bad_performers():
    bad_performance_counts = {}

    for report_file in PERFORMANCE_REPORTS:
        report = request_performance_report(report_file)
        threshold = report["threshold"]
        for no_id in EA_NOS:
            if str(no_id) in report["operators"].keys():
                validators = report["operators"][str(no_id)]["validators"]
                for validator in validators:
                    performance = validators[validator]["perf"]["included"] / validators[validator]["perf"]["assigned"]
                    if performance < threshold:
                        inc_or_add(bad_performance_counts, no_id, 1)
                        break

    bad_performing_nos = []

    for no_id in bad_performance_counts.keys():
        if bad_performance_counts[no_id] > 1:
            bad_performing_nos.append(no_id)

    print(f"EA Node Operators with low performance in the recent frames: {bad_performing_nos}")

    with open('exclude/bad_performers.json', 'w') as f:
        json.dump(bad_performing_nos, f)


def inc_or_add(mapping, key, value):
    if key in mapping.keys():
        mapping[key] += value
    else:
        mapping[key] = value


if __name__ == "__main__":
    process_bad_performers()

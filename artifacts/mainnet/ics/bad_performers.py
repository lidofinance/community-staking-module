import json

with open("sources/ea.json", "r") as file:
    EA_NOS = json.load(file)

PERFORMANCE_REPORTS = ["sources/performance_log_05_2025.json", "sources/performance_log_06_2025.json"]


def process_bad_performers():
    bad_performance_counts = {}

    for report_file in PERFORMANCE_REPORTS:
        with open(report_file, "r") as file:
            report = json.load(file)
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

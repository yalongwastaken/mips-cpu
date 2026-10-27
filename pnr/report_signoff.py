"""Print a LibreLane run's sign-off counts and fail on what LibreLane only warns.

Usage: python3 report_signoff.py <run>/final/metrics.json

Prints every sign-off count and the worst setup and hold slack to standard
output. LibreLane itself fails a run on every count here except antenna and
fanout violations, so this exits 1 when either of those is nonzero, and 2 when
the metrics file lacks a metric, which means LibreLane renamed it.
"""

import json
import sys
from pathlib import Path

SIGNOFF_COUNT_LABELS = {
    "magic__drc_error__count": "Magic DRC errors",
    "klayout__drc_error__count": "KLayout DRC errors",
    "magic__illegal_overlap__count": "Magic illegal overlaps",
    "route__drc_errors": "routing DRC errors",
    "design__lvs_error__count": "LVS errors",
    "design__xor_difference__count": "XOR differences",
    "design__disconnected_pin__count": "disconnected pins",
    "design__power_grid_violation__count": "power grid violations",
    "antenna__violating__nets": "antenna violations",
    "design__max_slew_violation__count": "slew violations",
    "design__max_cap_violation__count": "load violations",
    "design__max_fanout_violation__count": "fanout violations",
    "timing__setup_vio__count": "setup violations",
    "timing__hold_vio__count": "hold violations",
}
COUNTS_LIBRELANE_ONLY_WARNS_ON = [
    "antenna__violating__nets",
    "design__max_fanout_violation__count",
]
SLACK_LABELS = {
    "timing__setup__ws": "worst setup slack (ns)",
    "timing__hold__ws": "worst hold slack (ns)",
}


def main() -> int:
    metrics_path = Path(sys.argv[1])
    run_metrics = json.loads(metrics_path.read_text())
    run_dir = metrics_path.parent.parent

    missing_metric_names = [
        metric_name
        for metric_name in [*SIGNOFF_COUNT_LABELS, *SLACK_LABELS]
        if metric_name not in run_metrics
    ]
    if missing_metric_names:
        print(
            f"{metrics_path} lacks {', '.join(missing_metric_names)}; LibreLane "
            "renamed these metrics, so update their names in report_signoff.py",
            file=sys.stderr,
        )
        return 2

    all_labels = [*SIGNOFF_COUNT_LABELS.values(), *SLACK_LABELS.values()]
    label_width = max(len(metric_label) for metric_label in all_labels)
    for metric_name, metric_label in SIGNOFF_COUNT_LABELS.items():
        print(f"{metric_label:<{label_width}}  {run_metrics[metric_name]}")
    for metric_name, metric_label in SLACK_LABELS.items():
        print(f"{metric_label:<{label_width}}  {run_metrics[metric_name]:.3f}")

    failing_count_names = [
        metric_name
        for metric_name in COUNTS_LIBRELANE_ONLY_WARNS_ON
        if run_metrics[metric_name] != 0
    ]
    for metric_name in failing_count_names:
        print(
            f"sign-off failed on {SIGNOFF_COUNT_LABELS[metric_name]}: "
            f"{run_metrics[metric_name]}; the reports are under {run_dir}",
            file=sys.stderr,
        )
    return 1 if failing_count_names else 0


if __name__ == "__main__":
    sys.exit(main())

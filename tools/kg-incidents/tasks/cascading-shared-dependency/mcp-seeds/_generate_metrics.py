"""One-off generator for metrics.json. Produces 24h of 5-minute buckets for the
planted series per spec §4.3. Run once; output is committed as metrics.json.

Not called at runtime. Kept in repo as documentation of the seed's shape.
"""

from datetime import datetime, timedelta, timezone
import json
import random


INCIDENT_NOW = datetime(2026, 4, 17, 14, 0, 0, tzinfo=timezone.utc)
WINDOW = timedelta(hours=24)
BUCKET = timedelta(minutes=5)


def buckets(start: datetime, end: datetime):
    t = start
    while t < end:
        yield t
        t += BUCKET


def series(baseline: float, spike_start_hours_ago: float, spike_value: float,
           unit: str, seed: int):
    """Generate a series that is baseline until spike_start, then rises linearly to spike_value."""
    rng = random.Random(seed)
    spike_start = INCIDENT_NOW - timedelta(hours=spike_start_hours_ago)
    out = []
    for t in buckets(INCIDENT_NOW - WINDOW, INCIDENT_NOW):
        if t < spike_start:
            v = baseline + rng.uniform(-0.05, 0.05) * baseline
        else:
            progress = min(1.0, (t - spike_start) / timedelta(hours=1))  # 1h ramp
            target = baseline + (spike_value - baseline) * progress
            v = target + rng.uniform(-0.03, 0.03) * target
        out.append({
            "t": t.isoformat().replace("+00:00", "Z"),
            "p50": round(v * 0.85, 2),
            "p99": round(v * 1.4, 2),
            "avg": round(v, 2),
            "count": rng.randint(30, 60),
        })
    return {"unit": unit, "buckets": out}


def stable(baseline: float, unit: str, seed: int):
    rng = random.Random(seed)
    return {
        "unit": unit,
        "buckets": [
            {
                "t": t.isoformat().replace("+00:00", "Z"),
                "p50": round(baseline * 0.85 + rng.uniform(-0.03, 0.03) * baseline, 2),
                "p99": round(baseline * 1.4 + rng.uniform(-0.03, 0.03) * baseline, 2),
                "avg": round(baseline + rng.uniform(-0.03, 0.03) * baseline, 2),
                "count": rng.randint(30, 60),
            }
            for t in buckets(INCIDENT_NOW - WINDOW, INCIDENT_NOW)
        ]
    }


catalog = [
    # (service, metric, unit, kind, params)
    ("ai-description", "latency_p99_ms", "ms", "spike", {"baseline": 1300, "spike_start_hours_ago": 2.25, "spike_value": 4200}),
    ("ai-description", "latency_p50_ms", "ms", "stable", {"baseline": 650}),
    ("ai-description", "llm_call_latency_ms", "ms", "spike", {"baseline": 700, "spike_start_hours_ago": 2.0, "spike_value": 2700}),
    ("ai-description", "error_rate", "pct", "stable", {"baseline": 0.5}),
    ("warehouse", "db_query_rate", "qpm", "spike", {"baseline": 50, "spike_start_hours_ago": 4.0, "spike_value": 2000}),
    ("warehouse", "request_rate", "rpm", "stable", {"baseline": 120}),
    ("warehouse", "error_rate", "pct", "stable", {"baseline": 0.1}),
    ("host-app", "db_connection_pool_usage_pct", "pct", "spike", {"baseline": 40, "spike_start_hours_ago": 4.0, "spike_value": 98}),
    ("host-app", "request_rate", "rpm", "stable", {"baseline": 1400}),
    ("host-app", "error_rate", "pct", "stable", {"baseline": 0.2}),
    ("litellm-proxy", "latency_p99_ms", "ms", "spike", {"baseline": 800, "spike_start_hours_ago": 2.0, "spike_value": 2900}),
    ("litellm-proxy", "token_rate", "tpm", "stable", {"baseline": 4500}),
    ("litellm-proxy", "cost_per_hour_usd", "usd", "stable", {"baseline": 0.75}),
]


metrics = []
seed_counter = 1000
for service, metric, unit, kind, params in catalog:
    if kind == "spike":
        data = series(params["baseline"], params["spike_start_hours_ago"], params["spike_value"], unit, seed=seed_counter)
    else:
        data = stable(params["baseline"], unit, seed=seed_counter)
    metrics.append({"service": service, "metric": metric, "unit": unit, "buckets": data["buckets"]})
    seed_counter += 1


with open("metrics.json", "w") as f:
    json.dump({"metrics": metrics}, f, separators=(",", ":"))
print(f"wrote {len(metrics)} series")

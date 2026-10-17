"""Automated reasoning stage: deterministic bounds checks.

Contract: check(sensors: dict[str, float]) -> {"passed": bool, "violations": list[dict]}
Owner of this module can replace RULES freely; keep the contract.
"""
from typing import Any

# name -> (min, max). PLACEHOLDER bounds: tune from SWaT normal.csv.
BOUNDS: dict[str, tuple[float, float]] = {
    "LIT101": (200.0, 1000.0),  # raw water tank level
    "LIT301": (200.0, 1000.0),  # UF feed tank level
    "LIT401": (200.0, 1000.0),  # RO feed tank level
    "FIT101": (0.0, 5.0),       # inflow
    "AIT202": (6.0, 9.0),       # pH
}


def check(sensors: dict[str, float]) -> dict[str, Any]:
    violations: list[dict] = []
    for name, (lo, hi) in BOUNDS.items():
        v = sensors.get(name)
        if v is not None and not (lo <= v <= hi):
            violations.append({"rule": "bounds", "sensor": name, "value": v, "min": lo, "max": hi})
    # Consistency: pump P101 running (2) with no inflow
    if sensors.get("P101") == 2 and sensors.get("FIT101", 1.0) <= 0.0:
        violations.append({"rule": "pump_flow", "detail": "P101 on but FIT101 flow is 0"})
    return {"passed": not violations, "violations": violations}

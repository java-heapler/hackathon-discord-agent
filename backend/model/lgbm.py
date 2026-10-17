"""LightGBM stage.

Contract: score(sensors) -> {"score": float, "label": "normal"|"attack"}
Loads model/model.txt if present (train with train.py). Otherwise returns a
clearly-flagged stub so the pipeline runs before the model exists.
"""
import json
import os
from typing import Any

import numpy as np

_DIR = os.path.dirname(__file__)
MODEL_PATH = os.path.join(_DIR, "model.txt")
FEATURES_PATH = os.path.join(_DIR, "features.json")
THRESHOLD = 0.5

_booster = None
_features: list[str] = []


def _load():
    global _booster, _features
    if _booster is None and os.path.exists(MODEL_PATH) and os.path.exists(FEATURES_PATH):
        import lightgbm as lgb
        _booster = lgb.Booster(model_file=MODEL_PATH)
        _features = json.load(open(FEATURES_PATH))
    return _booster


def loaded() -> bool:
    return _load() is not None


def score(sensors: dict[str, float]) -> dict[str, Any]:
    b = _load()
    if b is None:
        return {"score": 0.0, "label": "normal", "stub": True}
    x = np.array([[sensors.get(f, np.nan) for f in _features]], dtype=float)
    p = float(b.predict(x)[0])
    return {"score": p, "label": "attack" if p >= THRESHOLD else "normal", "stub": False}

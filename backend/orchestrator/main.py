"""Thin orchestrator: reasoning screen first, LightGBM only if it passes."""
import logging
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from model import lgbm
from reasoning import rules

log = logging.getLogger("orchestrator")
app = FastAPI(title="Water defense backend")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o for o in os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(",") if o],
    allow_methods=["*"],
    allow_headers=["*"],
)


class Reading(BaseModel):
    sensors: dict[str, float]


@app.get("/health")
def health():
    return {"ok": True, "model_loaded": lgbm.loaded()}


@app.post("/predict")
def predict(r: Reading):
    degraded = False
    try:
        res = rules.check(r.sensors)
    except Exception:  # fail open to ML, flag it
        log.exception("reasoning stage failed")
        res, degraded = {"passed": True, "violations": []}, True
    if not res["passed"]:
        return {"verdict": "attack", "stage": "reasoning", "violations": res["violations"],
                "score": None, "degraded": False}
    m = lgbm.score(r.sensors)
    return {"verdict": m["label"], "stage": "ml", "violations": [],
            "score": m["score"], "degraded": degraded, "model_stub": m.get("stub", False)}

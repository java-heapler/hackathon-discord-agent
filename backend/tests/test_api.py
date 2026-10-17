from fastapi.testclient import TestClient

from orchestrator.main import app

c = TestClient(app)


def test_health():
    assert c.get("/health").status_code == 200


def test_rules_fail_short_circuits():
    j = c.post("/predict", json={"sensors": {"LIT101": 5000}}).json()
    assert j["verdict"] == "attack" and j["stage"] == "reasoning" and j["violations"]


def test_pass_goes_to_ml():
    j = c.post("/predict", json={"sensors": {"LIT101": 500}}).json()
    assert j["stage"] == "ml" and j["violations"] == []


def test_reasoning_error_fails_open(monkeypatch):
    from reasoning import rules
    monkeypatch.setattr(rules, "check", lambda s: 1 / 0)
    j = c.post("/predict", json={"sensors": {"LIT101": 500}}).json()
    assert j["stage"] == "ml" and j["degraded"] is True

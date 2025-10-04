from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    r = client.get("/")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"

def test_debate_flow():
    # start
    r = client.post("/debate/start", json={"mode":"debate"})
    assert r.status_code == 200
    sid = r.json()["session_id"]

    # respond
    r = client.post("/debate/respond", json={"session_id": sid, "mode":"debate", "user_input":"AI will replace jobs"})
    assert r.status_code == 200
    assert "ai_response" in r.json()

    # end
    r = client.post("/debate/end", json={"session_id": sid})
    assert r.status_code == 200
    assert r.json()["session_id"] == sid

    # history
    r = client.get("/history")
    assert r.status_code == 200
    assert isinstance(r.json(), list)

from app.services.feedback_service import analyze

def test_feedback_basic():
    msgs = [
        {"role":"user","content":"AI creates jobs because new industries emerge. For example, labeling grew 20%."},
        {"role":"ai","content":"ok"},
    ]
    fb = analyze(msgs, "debate", {"turn_s":60,"rounds":2})
    assert 0 < fb["overall"] <= 100
    assert isinstance(fb["tips"], list)

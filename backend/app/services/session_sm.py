from app.models.models import Session as S

class InvalidTransition(Exception): ...

def advance_to_prep(s: S):
    if s.state != "created": raise InvalidTransition("must be created")
    s.state = "prep"

def start_round(s: S):
    if s.state not in {"created","prep","live"}: raise InvalidTransition("bad state")
    s.state = "live"
    s.round_no = (s.round_no or 0) + 1
    s.turn = "user"

def switch_turn(s: S):
    if s.state != "live": raise InvalidTransition("not live")
    s.turn = "ai" if s.turn == "user" else "user"

def end_session(s: S):
    s.state = "ended"

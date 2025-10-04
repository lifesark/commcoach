import re

def _count_fillers(text):
    return len(re.findall(r"\b(um|uh|like|you know|uhm|erm|sort of|kind of)\b", text, flags=re.I))

def _has_structure(text):
    cues = ["first", "second", "finally", "because", "therefore", "for example", "e.g.", "data", "study"]
    return sum(c in text.lower() for c in cues)

def analyze(messages, mode, config):
    user_text = " ".join(m["content"] for m in messages if m["role"]=="user")
    fillers = _count_fillers(user_text)
    clarity = max(50, 75 - fillers*2)
    structure = 50 + min(50, _has_structure(user_text)*10)
    pers = 50 + min(40, int(len(user_text)/220))
    fluency = max(40, 85 - fillers*3)
    time_score = 70  # TODO: compute from timestamps
    overall = int((clarity + structure + pers + fluency + time_score)/5)

    tips = []
    if fillers>3: tips.append("Reduce fillers (um/uh). Pause briefly instead.")
    if structure<70: tips.append("Use claim → evidence → impact → takeaway.")
    if pers<70: tips.append("Add one statistic or credible source.")
    if fluency<70: tips.append("Use shorter sentences; emphasize keywords.")
    if time_score<80: tips.append("Aim to land the point within the time limit.")

    return {"clarity": clarity, "structure": structure, "persuasiveness": pers,
            "fluency": fluency, "time": time_score, "overall": overall, "tips": tips[:3]}

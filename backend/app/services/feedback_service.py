import re
import math
from typing import List, Dict, Any

def _count_fillers(text):
    """Count filler words and phrases"""
    filler_patterns = [
        r"\b(um|uh|like|you know|uhm|erm|sort of|kind of)\b",
        r"\b(actually|basically|literally|obviously|clearly)\b",
        r"\b(so|well|right|okay|ok)\b(?=\s|$)",
        r"\b(and|but|or)\b(?=\s(um|uh|like|you know))"
    ]
    total_fillers = 0
    for pattern in filler_patterns:
        total_fillers += len(re.findall(pattern, text, flags=re.I))
    return total_fillers

def _analyze_structure(text):
    """Analyze structural elements in the text"""
    # Transition words and phrases
    transitions = ["first", "second", "third", "finally", "moreover", "furthermore", 
                  "however", "therefore", "consequently", "in addition", "on the other hand"]
    
    # Logical connectors
    connectors = ["because", "since", "as a result", "due to", "for this reason"]
    
    # Evidence indicators
    evidence_words = ["data", "study", "research", "statistics", "example", "for instance", 
                     "according to", "studies show", "research indicates"]
    
    # Structure score based on presence of these elements
    structure_elements = sum(1 for word in transitions + connectors + evidence_words 
                           if word in text.lower())
    
    # Check for clear beginning, middle, end
    has_intro = any(word in text.lower()[:100] for word in ["introduction", "let me", "i'll", "we'll"])
    has_conclusion = any(word in text.lower()[-100:] for word in ["conclusion", "summary", "in summary", "to conclude"])
    
    structure_score = min(100, 30 + structure_elements * 5 + (20 if has_intro else 0) + (20 if has_conclusion else 0))
    
    return structure_score, structure_elements

def _analyze_persuasiveness(text, mode):
    """Analyze persuasiveness based on mode and content"""
    # Word count and complexity
    word_count = len(text.split())
    avg_word_length = sum(len(word) for word in text.split()) / max(word_count, 1)
    
    # Emotional language
    emotional_words = ["important", "crucial", "significant", "vital", "essential", 
                      "amazing", "incredible", "outstanding", "remarkable"]
    emotional_score = sum(1 for word in emotional_words if word in text.lower())
    
    # Evidence and examples
    evidence_indicators = ["data", "study", "research", "statistics", "example", "case", "instance"]
    evidence_score = sum(1 for word in evidence_indicators if word in text.lower())
    
    # Mode-specific scoring
    mode_multipliers = {
        "debate": 1.2,  # Higher standards for debate
        "interview": 1.0,
        "presentation": 1.1,
        "casual": 0.8,
        "general": 1.0
    }
    
    base_score = min(100, 40 + (word_count / 10) + (emotional_score * 5) + (evidence_score * 8))
    return int(base_score * mode_multipliers.get(mode, 1.0))

def _analyze_fluency(text):
    """Analyze fluency and flow"""
    sentences = re.split(r'[.!?]+', text)
    sentences = [s.strip() for s in sentences if s.strip()]
    
    if not sentences:
        return 50
    
    # Average sentence length
    avg_sentence_length = sum(len(s.split()) for s in sentences) / len(sentences)
    
    # Sentence length variation (good fluency has variation)
    sentence_lengths = [len(s.split()) for s in sentences]
    length_variance = sum((x - avg_sentence_length) ** 2 for x in sentence_lengths) / len(sentence_lengths)
    
    # Filler word impact
    fillers = _count_fillers(text)
    filler_penalty = min(30, fillers * 3)
    
    # Fluency score
    fluency_score = max(30, 80 - filler_penalty - abs(avg_sentence_length - 15) * 0.5)
    
    return int(fluency_score)

def _analyze_clarity(text):
    """Analyze clarity and comprehensibility"""
    # Filler words impact
    fillers = _count_fillers(text)
    filler_penalty = min(25, fillers * 2)
    
    # Sentence complexity (simpler is often clearer)
    sentences = re.split(r'[.!?]+', text)
    sentences = [s.strip() for s in sentences if s.strip()]
    
    if not sentences:
        return 50
    
    # Check for run-on sentences (too long)
    long_sentences = sum(1 for s in sentences if len(s.split()) > 30)
    complexity_penalty = long_sentences * 5
    
    # Check for very short sentences (might be choppy)
    short_sentences = sum(1 for s in sentences if len(s.split()) < 3)
    choppiness_penalty = min(10, short_sentences * 2)
    
    # Clarity score
    clarity_score = max(40, 85 - filler_penalty - complexity_penalty - choppiness_penalty)
    
    return int(clarity_score)

def _analyze_timing(messages, config):
    """Analyze timing and pace"""
    # This is a simplified version - in a real implementation, you'd use actual timestamps
    turn_s = config.get("turn_s", 60)
    
    # Estimate based on text length (rough approximation)
    user_text = " ".join(m["content"] for m in messages if m["role"] == "user")
    word_count = len(user_text.split())
    
    # Assume average speaking rate of 150 words per minute
    estimated_time = (word_count / 150) * 60
    
    # Score based on how well they used their time
    if estimated_time <= turn_s * 0.8:  # Used less than 80% of time
        time_score = 60
    elif estimated_time <= turn_s:  # Used time well
        time_score = 90
    else:  # Went over time
        time_score = max(30, 90 - (estimated_time - turn_s) * 2)
    
    return int(time_score)

def analyze(messages: List[Dict], mode: str, config: Dict) -> Dict[str, Any]:
    """
    Enhanced feedback analysis with more sophisticated scoring
    """
    user_text = " ".join(m["content"] for m in messages if m["role"] == "user")
    
    if not user_text.strip():
        return {
            "clarity": 0, "structure": 0, "persuasiveness": 0,
            "fluency": 0, "time": 0, "overall": 0, "tips": ["No speech detected"]
        }
    
    # Analyze each dimension
    clarity = _analyze_clarity(user_text)
    structure_score, structure_elements = _analyze_structure(user_text)
    persuasiveness = _analyze_persuasiveness(user_text, mode)
    fluency = _analyze_fluency(user_text)
    time_score = _analyze_timing(messages, config)
    
    # Calculate overall score
    overall = int((clarity + structure_score + persuasiveness + fluency + time_score) / 5)
    
    # Generate personalized tips
    tips = []
    
    # Clarity tips
    fillers = _count_fillers(user_text)
    if fillers > 3:
        tips.append(f"Reduce filler words (found {fillers}). Pause briefly instead of using 'um' or 'uh'.")
    if clarity < 70:
        tips.append("Use shorter, clearer sentences. Break down complex ideas into simpler parts.")
    
    # Structure tips
    if structure_score < 70:
        tips.append("Improve structure: Use transitions like 'first', 'second', 'however' to guide your audience.")
    if structure_elements < 2:
        tips.append("Add evidence: Include examples, data, or studies to support your points.")
    
    # Persuasiveness tips
    if persuasiveness < 70:
        tips.append("Strengthen your argument: Add specific examples or statistics to make your point more compelling.")
    
    # Fluency tips
    if fluency < 70:
        tips.append("Improve flow: Vary your sentence length and use connecting words to create smoother transitions.")
    
    # Timing tips
    if time_score < 80:
        tips.append("Work on timing: Practice delivering your key points within the allocated time.")
    
    # Mode-specific tips
    if mode == "debate" and persuasiveness < 80:
        tips.append("For debates: Address counterarguments directly and use stronger evidence.")
    elif mode == "interview" and structure_score < 80:
        tips.append("For interviews: Use the STAR method (Situation, Task, Action, Result) to structure your answers.")
    elif mode == "presentation" and clarity < 80:
        tips.append("For presentations: Speak clearly and use visual cues to emphasize key points.")
    
    return {
        "clarity": clarity,
        "structure": structure_score,
        "persuasiveness": persuasiveness,
        "fluency": fluency,
        "time": time_score,
        "overall": overall,
        "tips": tips[:4]  # Limit to top 4 tips
    }

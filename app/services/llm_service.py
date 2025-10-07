import time
from typing import Iterable
from app.core.settings import settings
import google.generativeai as genai
from app.services.persona_service import persona_service, PersonaType

class LLMService:
    def __init__(self):
        genai.configure(api_key=settings.GEMINI_API_KEY)
        self.model_name = settings.GEMINI_MODEL
        self._consec_fail = 0
        self._open = False

    def persona_system(self, mode, topic, round_no, rounds, turn, turn_s, persona_type=None):
        """
        Get system prompt based on persona type and context
        """
        if persona_type:
            try:
                persona_enum = PersonaType(persona_type)
                return persona_service.get_system_prompt(
                    persona_enum, mode, topic, round_no, rounds, turn, turn_s
                )
            except ValueError:
                pass
        
        # Fallback to mode-based persona selection
        persona_enum = persona_service.get_persona_for_mode(mode)
        return persona_service.get_system_prompt(
            persona_enum, mode, topic, round_no, rounds, turn, turn_s
        )

    def _fallback(self, _):
        return ("Let’s refine the claim, add one example or statistic, and tie it to impact. "
                "What’s your strongest evidence?")

    def generate(self, mode, topic, round_no, rounds, turn, turn_s, user_text, persona_type=None):
        if self._open: return self._fallback(user_text)
        system = self.persona_system(mode, topic, round_no, rounds, turn, turn_s, persona_type)
        backoff = 0.6
        for _ in range(4):
            try:
                model = genai.GenerativeModel(self.model_name, system_instruction=system)
                resp = model.generate_content(
                    contents=[{"role":"user","parts":[{"text":user_text}]}],
                    generation_config={"temperature":0.6, "max_output_tokens":256, "top_p":0.9, "top_k":40},
                )
                text = (resp.text or "").strip()
                if not text: raise RuntimeError("Empty response")
                self._consec_fail = 0
                return text
            except Exception:
                self._consec_fail += 1
                if self._consec_fail >= 3: self._open = True; break
                time.sleep(backoff); backoff *= 2
        return self._fallback(user_text)

    def stream(self, mode, topic, round_no, rounds, turn, turn_s, user_text, persona_type=None) -> Iterable[str]:
        if self._open:
            yield self._fallback(user_text); return
        system = self.persona_system(mode, topic, round_no, rounds, turn, turn_s, persona_type)
        backoff = 0.6
        for _ in range(4):
            try:
                model = genai.GenerativeModel(self.model_name, system_instruction=system)
                resp = model.generate_content(
                    contents=[{"role":"user","parts":[{"text":user_text}]}],
                    generation_config={"temperature":0.6, "max_output_tokens":256, "top_p":0.9, "top_k":40},
                    stream=True,
                )
                for event in resp:
                    try:
                        if hasattr(event, "text") and event.text:
                            yield event.text
                    except Exception:
                        continue
                self._consec_fail = 0
                return
            except Exception:
                self._consec_fail += 1
                if self._consec_fail >= 3: self._open = True; break
                time.sleep(backoff); backoff *= 2
        yield self._fallback(user_text)

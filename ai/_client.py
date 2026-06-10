"""
Client LLM unifié (Anthropic Claude Fable 5 ou Ollama local).

- Anthropic : claude-fable-5 par défaut (configurable via ANTHROPIC_MODEL),
  retries automatiques du SDK + sorties JSON structurées quand un schéma est fourni.
- Ollama : modèle local configurable, format JSON natif quand un schéma est fourni.
"""
import time

from config import config
from utils import console


class LLMClient:
    def __init__(self):
        self._client = None

    def _get(self):
        if self._client is None:
            if config.provider == "ollama":
                import ollama
                self._client = ollama.Client(host=config.ollama_base_url)
            else:
                import anthropic
                if not config.anthropic_api_key:
                    raise ValueError("ANTHROPIC_API_KEY manquante dans .env")
                self._client = anthropic.Anthropic(
                    api_key=config.anthropic_api_key,
                    max_retries=3,
                )
        return self._client

    def generate(
        self,
        system: str,
        user: str,
        max_tokens: int = 2048,
        json_schema: dict | None = None,
        cache_system: bool = True,
    ) -> str:
        """Retourne le texte de complétion. Si json_schema est fourni, la réponse
        est contrainte à du JSON valide respectant ce schéma (quand le provider
        le supporte ; sinon le schéma est rappelé dans le prompt)."""
        client = self._get()
        if config.provider == "ollama":
            return self._ollama(client, system, user, json_schema)
        return self._anthropic(client, system, user, max_tokens, json_schema, cache_system)

    # ─── Anthropic ────────────────────────────────────────────────────────────

    def _anthropic(self, client, system, user, max_tokens, json_schema, cache_system) -> str:
        system_blocks = [{"type": "text", "text": system}]
        if cache_system:
            system_blocks[0]["cache_control"] = {"type": "ephemeral"}

        kwargs: dict = {
            "model": config.anthropic_model,
            "max_tokens": max_tokens,
            "system": system_blocks,
            "messages": [{"role": "user", "content": user}],
        }
        if json_schema is not None:
            # Sorties structurées : le JSON retourné est garanti valide et conforme
            kwargs["output_config"] = {"format": {"type": "json_schema", "schema": json_schema}}

        try:
            response = client.messages.create(**kwargs)
        except TypeError:
            # SDK anthropic trop ancien pour output_config → fallback prompt simple
            kwargs.pop("output_config", None)
            response = client.messages.create(**kwargs)

        return next((b.text for b in response.content if b.type == "text"), "").strip()

    # ─── Ollama ───────────────────────────────────────────────────────────────

    def _ollama(self, client, system, user, json_schema) -> str:
        kwargs: dict = {
            "model": config.ollama_model,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
            "options": {"temperature": 0, "num_ctx": 8192},
        }
        if json_schema is not None:
            # Ollama supporte les sorties structurées via format=<schema>
            kwargs["format"] = json_schema

        last_err = None
        for attempt in range(3):
            try:
                response = client.chat(**kwargs)
                return response.message.content.strip()
            except Exception as e:
                last_err = e
                if attempt < 2:
                    wait = 2 ** attempt
                    console.print(f"[dim]Ollama indisponible, nouvel essai dans {wait}s...[/dim]")
                    time.sleep(wait)
        raise last_err

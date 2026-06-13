"""
Client LLM unifié avec routage par tâche (Ollama local / API Anthropic).

Chaque tâche IA ("prescore", "match", "letter") peut être routée vers un
backend différent via .env :

    AI_MATCH_BACKEND=local      # ou claude — vide = suivre PROVIDER
    AI_MATCH_MODEL=llama3.2     # vide = modèle par défaut du backend
    AI_FALLBACK=claude          # si le backend échoue : none|local|claude

Répartition recommandée : pré-scoring en masse → local (gratuit, volume),
analyse détaillée + lettres → claude (qualité de rédaction supérieure).

- Anthropic : claude-fable-5 par défaut (configurable via ANTHROPIC_MODEL),
  retries automatiques du SDK + sorties JSON structurées quand un schéma est fourni.
- Ollama : modèle local configurable, format JSON natif quand un schéma est fourni.
"""
import time

from config import config
from app_utils import console

TASKS = ("prescore", "match", "letter", "review")

_BACKEND_ALIASES = {
    "local": "ollama", "ollama": "ollama",
    "claude": "anthropic", "anthropic": "anthropic",
}


def resolve_backend(task: str) -> tuple[str, str]:
    """Retourne (backend, modèle) effectifs pour une tâche.
    backend ∈ {"ollama", "anthropic"}."""
    raw = getattr(config, f"ai_{task}_backend", "") if task in TASKS else ""
    backend = _BACKEND_ALIASES.get(raw or config.provider, "anthropic")
    model = getattr(config, f"ai_{task}_model", "") if task in TASKS else ""
    if not model:
        model = config.ollama_model if backend == "ollama" else config.anthropic_model
    return backend, model


def _fallback_backend(primary: str) -> tuple[str, str] | None:
    """Backend de secours configuré via AI_FALLBACK, ou None.
    Jamais le même que le backend primaire."""
    fb = _BACKEND_ALIASES.get(config.ai_fallback, "")
    if not fb or fb == primary:
        return None
    model = config.ollama_model if fb == "ollama" else config.anthropic_model
    return fb, model


class LLMClient:
    def __init__(self, task: str = "match"):
        self.task = task if task in TASKS else "match"
        self._clients: dict[str, object] = {}

    def _timeout(self) -> float:
        try:
            return float(config.llm_timeout)
        except (TypeError, ValueError):
            return 120.0

    def _get(self, backend: str):
        if backend not in self._clients:
            timeout = self._timeout()
            if backend == "ollama":
                import ollama
                # Un serveur Ollama bloqué ne doit pas figer un scan/lettre.
                self._clients[backend] = ollama.Client(host=config.ollama_base_url, timeout=timeout)
            else:
                import anthropic
                if not config.anthropic_api_key:
                    raise ValueError("ANTHROPIC_API_KEY manquante dans .env")
                self._clients[backend] = anthropic.Anthropic(
                    api_key=config.anthropic_api_key,
                    max_retries=3,
                    timeout=timeout,
                )
        return self._clients[backend]

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
        le supporte ; sinon le schéma est rappelé dans le prompt).

        Le backend est résolu selon la tâche du client ; en cas d'échec, le
        backend de secours (AI_FALLBACK) est tenté s'il est configuré."""
        backend, model = resolve_backend(self.task)
        try:
            return self._call(backend, model, system, user, max_tokens, json_schema, cache_system)
        except Exception as primary_error:
            fallback = _fallback_backend(backend)
            if fallback is None:
                raise
            fb_backend, fb_model = fallback
            console.print(
                f"[yellow]Backend {backend} indisponible pour la tâche "
                f"« {self.task} » ({type(primary_error).__name__}) — "
                f"bascule sur {fb_backend}.[/yellow]"
            )
            return self._call(fb_backend, fb_model, system, user, max_tokens, json_schema, cache_system)

    def _call(self, backend, model, system, user, max_tokens, json_schema, cache_system) -> str:
        client = self._get(backend)
        if backend == "ollama":
            return self._ollama(client, model, system, user, json_schema)
        return self._anthropic(client, model, system, user, max_tokens, json_schema, cache_system)

    # ─── Anthropic ────────────────────────────────────────────────────────────

    def _anthropic(self, client, model, system, user, max_tokens, json_schema, cache_system) -> str:
        system_blocks = [{"type": "text", "text": system}]
        if cache_system:
            system_blocks[0]["cache_control"] = {"type": "ephemeral"}

        kwargs: dict = {
            "model": model,
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

    def _ollama(self, client, model, system, user, json_schema) -> str:
        kwargs: dict = {
            "model": model,
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

    # ─── Streaming (récupération du partiel en cas d'interruption) ─────────────

    def stream(self, system: str, user: str, max_tokens: int = 2048,
               cache_system: bool = True):
        """Génère en flux, yieldant le texte au fur et à mesure. L'appelant peut
        ainsi conserver ce qui a déjà été produit si l'opération est interrompue
        (timeout, coupure réseau). Pas de json_schema en streaming."""
        backend, model = resolve_backend(self.task)
        client = self._get(backend)
        if backend == "ollama":
            yield from self._ollama_stream(client, model, system, user)
        else:
            yield from self._anthropic_stream(client, model, system, user, max_tokens, cache_system)

    def _anthropic_stream(self, client, model, system, user, max_tokens, cache_system):
        system_blocks = [{"type": "text", "text": system}]
        if cache_system:
            system_blocks[0]["cache_control"] = {"type": "ephemeral"}
        with client.messages.stream(
            model=model, max_tokens=max_tokens, system=system_blocks,
            messages=[{"role": "user", "content": user}],
        ) as stream:
            for text in stream.text_stream:
                if text:
                    yield text

    def _ollama_stream(self, client, model, system, user):
        for chunk in client.chat(
            model=model,
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
            options={"temperature": 0, "num_ctx": 8192},
            stream=True,
        ):
            msg = getattr(chunk, "message", None)
            part = getattr(msg, "content", None) if msg is not None else None
            if part is None and isinstance(chunk, dict):
                part = (chunk.get("message") or {}).get("content")
            if part:
                yield part

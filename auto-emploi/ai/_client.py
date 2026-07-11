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

# Tâches d'analyse de masse (pré-scoring + analyse détaillée) : plafond très
# large plutôt qu'aucun. Sur un modèle local lent, on laisse l'analyse aller
# au bout — mais un plafond fini reste indispensable : un appel réellement
# suspendu (connexion TCP morte, serveur figé) tiendrait sinon _SCAN_LOCK /
# _GEN_LOCK pour toujours et bloquerait scans et générations jusqu'au
# redémarrage. Les tâches interactives (lettres, relecture) gardent LLM_TIMEOUT.
_UNBOUNDED_TASKS = ("prescore", "match")
_SLOW_TASK_CEILING = 1800.0  # 30 min par appel : jamais atteint sauf blocage réel

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


def llm_available(task: str = "match") -> bool:
    """Indique si un backend LLM est vraisemblablement utilisable pour la tâche.
    - Anthropic exige une clé API ; sans clé, on ne le considère dispo que si un
      fallback Ollama est configuré.
    - Ollama est supposé disponible (un ping bloquant à chaque scan serait
      coûteux) ; un serveur réellement éteint est rattrapé en aval (bascule sur
      le scoring local sans IA).
    Sert à choisir, au lancement d'un scan, entre l'analyse IA et le repli code
    pur — plutôt que d'échouer faute de modèle."""
    backend, _ = resolve_backend(task)
    if backend == "anthropic" and not config.anthropic_api_key:
        fb = _fallback_backend("anthropic")
        return fb is not None and fb[0] == "ollama"
    return True


def _is_model_not_found(exc: Exception) -> bool:
    """Vrai si l'exception Ollama indique que le modèle n'est pas installé."""
    msg = str(exc).lower()
    return "not found" in msg or "no such file" in msg or "pull the model" in msg


def _estimate_model_gb(name: str) -> float | None:
    """Estime la taille d'un modèle en GB à partir de son nom.
    Ex. gemma3:12b → ~7.8 GB (12 × 0.65), qwen2.5:3b → ~1.95 GB."""
    import re
    m = re.search(r"(\d+\.?\d*)b", name.lower())
    if m:
        return float(m.group(1)) * 0.65  # approximation q4
    return None


def _pick_best_available(missing: str) -> str | None:
    """Choisit le meilleur modèle installé comme remplaçant de `missing`.
    Stratégie : équivalent ou modèle le moins cher juste en-dessous (même
    qualité, moins de VRAM) ; à défaut, le moins cher juste au-dessus.
    Retourne None si Ollama est injoignable ou aucun modèle installé."""
    try:
        from integrations.local_models import probe_ollama
        result = probe_ollama()
    except Exception:
        return None
    if not result:
        return None
    models = [(m["name"], m["size_gb"] or 0.0)
              for m in result.get("models", []) if m.get("name")]
    if not models:
        return None

    target_gb = _estimate_model_gb(missing)
    if target_gb is None:
        # Taille inconnue : prendre le plus gros modèle disponible
        return max(models, key=lambda x: x[1])[0]

    models.sort(key=lambda x: x[1])
    below = [(n, s) for n, s in models if s <= target_gb]
    if below:
        return max(below, key=lambda x: x[1])[0]   # le plus grand en-dessous
    above = [(n, s) for n, s in models if s > target_gb]
    if above:
        return min(above, key=lambda x: x[1])[0]   # le plus petit au-dessus
    return models[0][0]


def _model_env_key(task: str, model: str) -> str:
    """Clé .env à mettre à jour : la clé de tâche si c'est elle qui porte le
    modèle manquant, sinon OLLAMA_MODEL (le modèle par défaut du backend)."""
    if task in TASKS:
        task_model = getattr(config, f"ai_{task}_model", "")
        if task_model == model:
            return f"AI_{task.upper()}_MODEL"
    return "OLLAMA_MODEL"


def _save_model(task: str, old_model: str, new_model: str) -> None:
    """Persiste le nouveau modèle dans .env (save_to_env met aussi à jour
    l'attribut correspondant de config en mémoire)."""
    from config import save_to_env
    try:
        save_to_env(_model_env_key(task, old_model), new_model)
    except Exception as exc:
        console.print(f"[dim]Impossible d'enregistrer le nouveau modèle dans .env : {exc}[/dim]")


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
        """Délai max d'un appel LLM en secondes — toujours fini : un appel
        suspendu ne doit jamais tenir indéfiniment les verrous de scan ou de
        génération. « Illimité » (tâches d'analyse, LLM_TIMEOUT=0) signifie en
        réalité un plafond très large (_SLOW_TASK_CEILING)."""
        if self.task in _UNBOUNDED_TASKS:
            return _SLOW_TASK_CEILING
        try:
            seconds = float(config.llm_timeout)
        except (TypeError, ValueError):
            return 120.0
        return seconds if seconds > 0 else _SLOW_TASK_CEILING

    def _get(self, backend: str):
        if backend not in self._clients:
            timeout = self._timeout()
            if backend == "ollama":
                import ollama
                # Plafond fini même pour les analyses : un serveur Ollama figé
                # ne doit jamais bloquer indéfiniment un scan ou une lettre.
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

        text = next((b.text for b in response.content if b.type == "text"), "").strip()
        if not text:
            # Réponse sans bloc texte (refus, max_tokens épuisé…) : lever plutôt
            # que renvoyer "" en silence — le retry/fallback existant s'enclenche
            # au lieu de propager des scores nuls ou une lettre vide.
            raise ValueError("réponse LLM vide (aucun bloc texte)")
        return text

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
                text = (response.message.content or "").strip()
                if not text:
                    raise ValueError("réponse LLM vide")
                return text
            except Exception as e:
                last_err = e
                # Modèle absent : choisir automatiquement le meilleur remplaçant
                # installé (équivalent ou juste en-dessous en taille, sinon juste
                # au-dessus) et le persister dans .env pour les prochains appels.
                if _is_model_not_found(e):
                    old = kwargs["model"]
                    replacement = _pick_best_available(old)
                    if replacement and replacement != old:
                        console.print(
                            f"[yellow]Ollama : modèle « {old} » introuvable — "
                            f"sélection automatique de « {replacement} » et sauvegarde dans .env.[/yellow]"
                        )
                        _save_model(self.task, old, replacement)
                        kwargs["model"] = replacement
                        continue
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
        (timeout, coupure réseau). Pas de json_schema en streaming.

        Bascule sur le backend de secours (AI_FALLBACK) si le primaire échoue
        *avant* d'avoir produit le moindre texte ; une fois le flux entamé on
        relaie l'erreur telle quelle (relancer dupliquerait le partiel déjà émis,
        que l'appelant récupère via son mécanisme de sauvegarde)."""
        backend, model = resolve_backend(self.task)
        yielded = False
        try:
            for text in self._stream_backend(backend, model, system, user, max_tokens, cache_system):
                yielded = True
                yield text
        except Exception as primary_error:
            fallback = _fallback_backend(backend)
            if yielded or fallback is None:
                raise
            fb_backend, fb_model = fallback
            console.print(
                f"[yellow]Backend {backend} indisponible pour la tâche "
                f"« {self.task} » ({type(primary_error).__name__}) — "
                f"bascule sur {fb_backend}.[/yellow]"
            )
            yield from self._stream_backend(fb_backend, fb_model, system, user, max_tokens, cache_system)

    def _stream_backend(self, backend, model, system, user, max_tokens, cache_system):
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

    def _ollama_stream(self, client, model, system, user, _retried: bool = False):
        try:
            yield from self._ollama_stream_inner(client, model, system, user)
        except Exception as e:
            if _is_model_not_found(e) and not _retried:
                replacement = _pick_best_available(model)
                if replacement and replacement != model:
                    console.print(
                        f"[yellow]Ollama : modèle « {model} » introuvable en streaming — "
                        f"sélection automatique de « {replacement} » et sauvegarde dans .env.[/yellow]"
                    )
                    _save_model(self.task, model, replacement)
                    yield from self._ollama_stream(client, replacement, system, user, _retried=True)
                    return
            raise

    def _ollama_stream_inner(self, client, model, system, user):
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

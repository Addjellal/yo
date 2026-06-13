"""
Arborescence du dossier output/ — un sous-dossier par type de donnée :

    output/
        cv/                  CV importés via l'interface web
        offres/brutes/       offres scrapées avant analyse IA (mode test inclus)
        offres/analysees/    exports JSON/CSV des offres scorées
        offres/ecartees/     offres collectées mais non retenues (traçabilité)
        lettres/par_offre/   lettres générées (.txt + .pdf)
        logs/                journaux applicatifs (web.log)

Les fichiers d'état (.tracker.json, .sessions.json, .cvs.json) restent à la
racine de output/ : ce sont des données internes, pas des sauvegardes.

Compatibilité : les anciens fichiers écrits à la racine de output/ restent
lisibles — `find_output_file()` cherche dans les sous-dossiers puis à la racine.
"""
from pathlib import Path

from config import config


def _ensure(path: Path) -> Path:
    path.mkdir(parents=True, exist_ok=True)
    return path


def output_root() -> Path:
    return _ensure(Path(config.output_dir))


def cv_dir() -> Path:
    return _ensure(output_root() / "cv")


def offers_raw_dir() -> Path:
    return _ensure(output_root() / "offres" / "brutes")


def offers_scored_dir() -> Path:
    return _ensure(output_root() / "offres" / "analysees")


def offers_dropped_dir() -> Path:
    return _ensure(output_root() / "offres" / "ecartees")


def letters_dir() -> Path:
    return _ensure(output_root() / "lettres" / "par_offre")


def logs_dir() -> Path:
    return _ensure(output_root() / "logs")


# Sous-dossiers où un téléchargement par nom nu peut résider (jamais de chemin
# fourni par le client : le serveur cherche le nom dans cette liste fermée).
_SEARCH_SUBDIRS = (
    ("lettres", "par_offre"),
    ("offres", "analysees"),
    ("offres", "brutes"),
    ("offres", "ecartees"),
)


def find_output_file(name: str) -> Path | None:
    """Résout un nom de fichier nu (sans chemin) dans les sous-dossiers connus
    puis à la racine de output/ (anciens exports). None si introuvable."""
    name = Path(name).name  # défense en profondeur : jamais de chemin
    root = Path(config.output_dir).resolve()
    candidates = [root.joinpath(*parts, name) for parts in _SEARCH_SUBDIRS]
    candidates.append(root / name)
    for candidate in candidates:
        resolved = candidate.resolve()
        # Le fichier doit rester sous output/ (pas de symlink sortant)
        if resolved.is_file() and root in resolved.parents:
            return resolved
    return None


# Routage des anciens fichiers (versions antérieures écrivaient à la racine).
# Par extension : exports → offres/analysees, lettres → lettres/par_offre.
_LEGACY_ROUTES = {
    ".txt": letters_dir, ".pdf": letters_dir,
    ".csv": offers_scored_dir, ".json": offers_scored_dir,
}


def migrate_legacy_files() -> int:
    """Range les fichiers laissés à la RACINE d'output/ par d'anciennes versions
    dans leurs sous-dossiers. Idempotent et prudent : ignore les sous-dossiers,
    les fichiers d'état interne (dotfiles : .tracker.json, .sessions.json…) et
    les .corrupt ; n'écrase jamais un fichier déjà présent à destination.
    Retourne le nombre de fichiers déplacés."""
    root = Path(config.output_dir)
    if not root.is_dir():
        return 0
    moved = 0
    for entry in list(root.iterdir()):
        # Dossiers intacts ; dotfiles = état interne, jamais déplacés.
        if not entry.is_file() or entry.name.startswith("."):
            continue
        dest_dir = _LEGACY_ROUTES.get(entry.suffix.lower())
        if dest_dir is None:
            continue
        dest = dest_dir() / entry.name
        if dest.exists():
            continue  # ne jamais écraser une version déjà rangée
        try:
            entry.rename(dest)
            moved += 1
        except OSError:
            pass
    return moved

import logging
import logging.handlers

from rich.console import Console

console = Console()

_logger: logging.Logger | None = None


def get_logger() -> logging.Logger:
    """Journal applicatif persistant (output/logs/web.log, rotation 1 Mo × 3).
    Trace le cycle de vie des jobs web (scan, lettre, analyse CV) avec les
    erreurs complètes — la console ne montre que des messages courts."""
    global _logger
    if _logger is not None:
        return _logger
    logger = logging.getLogger("autoemploi")
    logger.setLevel(logging.INFO)
    if not logger.handlers:
        try:
            from output_paths import logs_dir
            handler = logging.handlers.RotatingFileHandler(
                logs_dir() / "web.log", maxBytes=1_000_000, backupCount=3,
                encoding="utf-8",
            )
            handler.setFormatter(logging.Formatter(
                "%(asctime)s %(levelname)s %(message)s", datefmt="%Y-%m-%d %H:%M:%S",
            ))
            logger.addHandler(handler)
        except OSError:
            logger.addHandler(logging.NullHandler())
    _logger = logger
    return logger

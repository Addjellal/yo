"""Notification desktop (Windows/macOS/Linux) — silencieuse si plyer absent."""


def desktop_notify(title: str, message: str) -> bool:
    try:
        from plyer import notification
        notification.notify(
            title=title[:64],
            message=message[:256],
            app_name="Auto Emploi",
            timeout=10,
        )
        return True
    except Exception:
        return False

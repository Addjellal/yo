import base64
from pathlib import Path


def parse_cv(cv_path: str) -> str:
    path = Path(cv_path)
    if not path.exists():
        raise FileNotFoundError(f"CV introuvable : {cv_path}")

    suffix = path.suffix.lower()
    if suffix == ".pdf":
        return _parse_pdf(path)
    elif suffix in (".docx", ".doc"):
        return _parse_docx(path)
    elif suffix == ".txt":
        return path.read_text(encoding="utf-8")
    else:
        raise ValueError(f"Format non supporté : {suffix}. Utilisez PDF, DOCX ou TXT.")


def _parse_pdf(path: Path) -> str:
    """Try native text extraction first; fall back to Claude Vision OCR for image-based PDFs."""
    text = _extract_text_native(path)
    if text:
        return text
    # PDF is image-based (scanned/rasterised) — use Claude Vision
    return _extract_text_vision(path)


def _extract_text_native(path: Path) -> str:
    """Extract selectable text using PyMuPDF (fast, no API call)."""
    try:
        import fitz  # pymupdf
        doc = fitz.open(str(path))
        pages = [page.get_text() for page in doc]
        return "\n".join(p for p in pages if p.strip())
    except ImportError:
        pass

    # Fallback: pdfplumber
    try:
        import pdfplumber
        with pdfplumber.open(path) as pdf:
            pages = [page.extract_text() or "" for page in pdf.pages]
        return "\n".join(p for p in pages if p.strip())
    except ImportError:
        pass

    return ""


def _extract_text_vision(path: Path) -> str:
    """Render each PDF page as an image and send to Claude Vision for OCR."""
    try:
        import fitz
    except ImportError:
        raise ValueError(
            "PDF image-based détecté mais PyMuPDF non installé.\n"
            "Installez-le : pip install pymupdf"
        )

    import anthropic
    from config import config

    if not config.anthropic_api_key:
        raise ValueError("ANTHROPIC_API_KEY manquante — impossible de faire l'OCR du CV scanné.")

    client = anthropic.Anthropic(api_key=config.anthropic_api_key)
    doc = fitz.open(str(path))

    from utils import console
    console.print(f"[yellow]PDF image-based détecté ({len(doc)} page(s)) — OCR via Claude Vision...[/yellow]")

    all_text: list[str] = []

    for page_num, page in enumerate(doc):
        pix = page.get_pixmap(dpi=150)
        img_bytes = pix.tobytes("png")
        img_b64 = base64.standard_b64encode(img_bytes).decode()

        response = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=4096,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/png",
                                "data": img_b64,
                            },
                        },
                        {
                            "type": "text",
                            "text": (
                                "Voici la page d'un CV. Extrait tout le texte visible "
                                "en préservant la structure (sections, puces, dates). "
                                "Réponds uniquement avec le texte extrait, sans commentaire."
                            ),
                        },
                    ],
                }
            ],
        )

        page_text = response.content[0].text.strip()
        if page_text:
            all_text.append(f"--- Page {page_num + 1} ---\n{page_text}")
        console.print(f"[dim]  Page {page_num + 1}/{len(doc)} traitée[/dim]")

    if not all_text:
        raise ValueError("Impossible d'extraire le texte du CV, même via OCR.")

    return "\n\n".join(all_text)


def _parse_docx(path: Path) -> str:
    from docx import Document
    doc = Document(path)
    paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                if cell.text.strip():
                    paragraphs.append(cell.text.strip())
    return "\n".join(paragraphs)

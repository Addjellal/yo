import re
from pathlib import Path
import anthropic
from scrapers.base import JobOffer
from config import config


class CoverLetterGenerator:
    """Generate personalized cover letters using Claude with prompt caching."""

    def __init__(self, cv_text: str):
        self.cv_text = cv_text
        self.client = anthropic.Anthropic(api_key=config.anthropic_api_key)
        Path(config.output_dir).mkdir(parents=True, exist_ok=True)

    def generate(self, job: JobOffer) -> str:
        response = self.client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1200,
            system=[
                {
                    "type": "text",
                    "text": (
                        "Tu es un expert en rédaction de lettres de motivation en français. "
                        "Tu rédiges des lettres personnalisées, professionnelles et convaincantes "
                        "qui mettent en valeur les compétences du candidat par rapport à l'offre. "
                        "Style : naturel, direct, sans formules creuses. Longueur : 3 paragraphes, max 350 mots.\n\n"
                        f"CV du candidat :\n{self.cv_text}"
                    ),
                    "cache_control": {"type": "ephemeral"},
                }
            ],
            messages=[
                {
                    "role": "user",
                    "content": (
                        f"Rédige une lettre de motivation pour ce poste.\n\n"
                        f"Offre :\n{job.to_text()}\n\n"
                        "La lettre doit :\n"
                        "1. Commencer par une accroche qui montre la connaissance de l'entreprise/poste\n"
                        "2. Mettre en avant 2-3 compétences clés du CV qui correspondent à l'offre\n"
                        "3. Conclure avec une invitation à un entretien\n"
                        "4. Utiliser un ton professionnel mais authentique\n"
                        "5. Inclure les formules de politesse habituelles\n\n"
                        "Commence directement par la lettre (sans titre ni commentaires)."
                    ),
                }
            ],
        )
        return response.content[0].text.strip()

    def save(self, job: JobOffer, letter: str) -> tuple[Path, Path]:
        safe_name = re.sub(r"[^a-z0-9_-]", "_", f"{job.title}_{job.company}".lower())[:60]
        txt_path = Path(config.output_dir) / f"{safe_name}.txt"
        pdf_path = Path(config.output_dir) / f"{safe_name}.pdf"

        txt_path.write_text(
            f"Poste : {job.title}\nEntreprise : {job.company}\nSource : {job.source}\nURL : {job.url}\n\n"
            + "=" * 60 + "\n\n" + letter,
            encoding="utf-8",
        )

        self._save_pdf(pdf_path, job, letter)
        return txt_path, pdf_path

    def _save_pdf(self, path: Path, job: JobOffer, letter: str) -> None:
        try:
            from fpdf import FPDF

            pdf = FPDF()
            pdf.add_page()
            pdf.set_auto_page_break(auto=True, margin=20)
            pdf.set_margins(25, 25, 25)

            # En-tête
            pdf.set_font("Helvetica", "B", 12)
            pdf.cell(0, 8, f"{job.title} – {job.company}", ln=True)
            pdf.set_font("Helvetica", "", 9)
            pdf.set_text_color(100, 100, 100)
            pdf.cell(0, 6, job.url, ln=True)
            pdf.set_text_color(0, 0, 0)
            pdf.ln(6)

            # Corps de la lettre
            pdf.set_font("Helvetica", "", 11)
            for paragraph in letter.split("\n\n"):
                paragraph = paragraph.strip()
                if paragraph:
                    # fpdf2 gère l'UTF-8 nativement
                    pdf.multi_cell(0, 6, paragraph)
                    pdf.ln(4)

            pdf.output(str(path))
        except ImportError:
            pass  # PDF optionnel, le TXT suffit
        except Exception:
            pass

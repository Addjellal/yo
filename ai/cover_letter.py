import re
from pathlib import Path
from scrapers.base import JobOffer
from config import config
from utils import console

SYSTEM_PROMPT = (
    "Tu es un expert en rédaction de lettres de motivation en français. "
    "Tu rédiges des lettres personnalisées, professionnelles et convaincantes "
    "qui mettent en valeur les compétences du candidat par rapport à l'offre. "
    "Style : naturel, direct, sans formules creuses. Longueur : 3 paragraphes, max 350 mots.\n\n"
    "CV du candidat :\n{cv}"
)

USER_PROMPT = (
    "Rédige une lettre de motivation pour ce poste.\n\n"
    "Offre :\n{job}\n\n"
    "La lettre doit :\n"
    "1. Commencer par une accroche qui montre la connaissance de l'entreprise/poste\n"
    "2. Mettre en avant 2-3 compétences clés du CV qui correspondent à l'offre\n"
    "3. Conclure avec une invitation à un entretien\n"
    "4. Utiliser un ton professionnel mais authentique\n"
    "5. Inclure les formules de politesse habituelles\n\n"
    "Commence directement par la lettre (sans titre ni commentaires)."
)


class CoverLetterGenerator:
    def __init__(self, cv_text: str):
        self.cv_text = cv_text
        self._client = None
        Path(config.output_dir).mkdir(parents=True, exist_ok=True)

    def _get_client(self):
        if self._client is None:
            if config.provider == "ollama":
                import ollama
                self._client = ollama.Client(host=config.ollama_base_url)
            else:
                import anthropic
                self._client = anthropic.Anthropic(api_key=config.anthropic_api_key)
        return self._client

    def generate(self, job: JobOffer) -> str:
        self._get_client()
        system = SYSTEM_PROMPT.format(cv=self.cv_text)
        user = USER_PROMPT.format(job=job.to_text())

        if config.provider == "ollama":
            return self._call_ollama(system, user)
        return self._call_anthropic(system, user)

    def _call_anthropic(self, system: str, user: str) -> str:
        import anthropic
        response = self._client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1200,
            system=[{"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}],
            messages=[{"role": "user", "content": user}],
        )
        return response.content[0].text.strip()

    def _call_ollama(self, system: str, user: str) -> str:
        response = self._client.chat(
            model=config.ollama_model,
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        )
        return response.message.content.strip()

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
            pdf.set_font("Helvetica", "B", 12)
            pdf.cell(0, 8, f"{job.title} – {job.company}", ln=True)
            pdf.set_font("Helvetica", "", 9)
            pdf.set_text_color(100, 100, 100)
            pdf.cell(0, 6, job.url, ln=True)
            pdf.set_text_color(0, 0, 0)
            pdf.ln(6)
            pdf.set_font("Helvetica", "", 11)
            for paragraph in letter.split("\n\n"):
                paragraph = paragraph.strip()
                if paragraph:
                    pdf.multi_cell(0, 6, paragraph)
                    pdf.ln(4)
            pdf.output(str(path))
        except ImportError:
            pass
        except Exception as e:
            console.print(f"[yellow]Avertissement : PDF échoué ({e}). TXT disponible.[/yellow]")

#!/usr/bin/env python3
"""Extrai conhecimento dos PDFs de psicologia e gera assets/data/mindo_psychology_knowledge.json."""

from __future__ import annotations

import json
import re
import unicodedata
from pathlib import Path

from pypdf import PdfReader

PDF_DIR = Path(r"c:\Users\Beani\OneDrive\Desktop\mente mindo")
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "data"
OUT_FILE = OUT_DIR / "mindo_psychology_knowledge.json"

# Limite por PDF e total para manter o app leve
MAX_PAGES_PER_PDF = 80
MAX_CHARS_PER_CHUNK = 420
MIN_CHUNK_CHARS = 120
MAX_ENTRIES_TOTAL = 360
MAX_ENTRIES_PER_SOURCE = 30

TOPIC_KEYWORDS: dict[str, list[str]] = {
    "ansiedade": [
        "ansiedade", "ansioso", "angustia", "panico", "preocupacao", "nervosismo",
    ],
    "tristeza": [
        "tristeza", "depressao", "luto", "melancolia", "sofrimento", "choro",
    ],
    "psicanalise": [
        "psicanalise", "freud", "inconsciente", "transferencia", "sonho", "ego",
        "superego", "id", "libido", "complexo", "jung", "arquetipo",
    ],
    "comportamento": [
        "comportamento", "condicionamento", "reforco", "punicao", "habito",
        "aprendizagem", "estimulo", "resposta",
    ],
    "cognitivo": [
        "cognitivo", "pensamento", "crenca", "reestruturacao", "distorsao",
        "esquema", "automatico",
    ],
    "neurociencia": [
        "neurociencia", "cerebro", "neurônio", "neuronio", "amigdala", "cortex",
        "dopamina", "serotonina",
    ],
    "relacionamento": [
        "relacionamento", "vinculo", "apego", "amor", "casal", "familia",
    ],
    "trauma": [
        "trauma", "abuso", "ptsd", "estresse pos-traumatico", "violencia",
    ],
    "sono": [
        "sono", "insonia", "dormir", "pesadelo",
    ],
    "meditacao": [
        "meditacao", "mindfulness", "relaxamento", "respiracao",
    ],
    "clinica": [
        "terapia", "clinica", "diagnostico", "tratamento", "paciente",
        "psicoterapia", "entrevista",
    ],
    "educacao": [
        "educacao", "escola", "aprendizagem", "desenvolvimento infantil",
    ],
    "organizacional": [
        "organizacao", "trabalho", "lideranca", "equipe", "burnout",
    ],
}

PDF_SOURCES = [
    ("manual-de-tecnica-psicanalitica-uma-revisc3a3o-zimmerman.pdf", "Manual de Técnica Psicanalítica (Zimmerman)"),
    ("marcos_bulcao_nascimento_posdoc_2008.pdf", "Bulcão Nascimento — Psicanálise"),
    ("Portuguese_about.pdf", "Sobre psicologia (PT)"),
    ("Psicanálise em perspectiva_Livro2_2017_PDF-A.pdf", "Psicanálise em Perspectiva (2017)"),
    ("Psicologia-e-Análise-do-Comportamento_Conceitos-e-Aplicações-à-Educação-Organizações-Saúde-e-Clínica.pdf", "Psicologia e Análise do Comportamento"),
    ("psicologia-neurociencias-comportamento.pdf", "Psicologia, Neurociências e Comportamento"),
    ("revista53.pdf", "Revista de Psicologia"),
    ("4_jung_freud_e_a_psicanalise.pdf", "Jung, Freud e a Psicanálise"),
    ("2766Compendio-da-Psicanalise.pdf", "Compêndio da Psicanálise"),
    ("A) Psicologia Geral.pdf", "Psicologia Geral"),
    ("doc_1472159178.pdf", "Documento de Psicologia"),
    ("fundamentos-da-psicanc3a1lise.pdf", "Fundamentos da Psicanálise"),
]


def normalize(text: str) -> str:
    text = unicodedata.normalize("NFD", text)
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    return text.lower()


def clean_text(raw: str) -> str:
    raw = re.sub(r"\s+", " ", raw)
    raw = re.sub(r"[^\w\s.,;:!?()\-–—\"'áàâãéèêíìîóòôõúùûçÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇ]", " ", raw)
    return raw.strip()


def detect_topics(text: str) -> list[str]:
    norm = normalize(text)
    topics = []
    for topic, keywords in TOPIC_KEYWORDS.items():
        if any(kw in norm for kw in keywords):
            topics.append(topic)
    return topics or ["geral"]


def extract_keywords(text: str, limit: int = 12) -> list[str]:
    norm = normalize(text)
    words = re.findall(r"[a-záàâãéèêíìîóòôõúùûç]{5,}", norm)
    stop = {
        "sobre", "quando", "porque", "entre", "desta", "deste", "nesta", "neste",
        "como", "mais", "muito", "pode", "pela", "pelo", "para", "essa", "esse",
        "isso", "aquela", "aquele", "tambem", "ainda", "sendo", "forma", "parte",
        "todo", "toda", "todos", "todas", "onde", "qual", "quais", "seria",
    }
    seen: set[str] = set()
    result: list[str] = []
    for w in words:
        if w in stop or w in seen:
            continue
        seen.add(w)
        result.append(w)
        if len(result) >= limit:
            break
    return result


def chunk_paragraphs(text: str) -> list[str]:
    parts = re.split(r"\n{2,}|(?<=[.!?])\s+(?=[A-ZÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇ])", text)
    chunks: list[str] = []
    buf = ""
    for part in parts:
        part = clean_text(part)
        if len(part) < 40:
            continue
        if len(buf) + len(part) < MAX_CHARS_PER_CHUNK:
            buf = f"{buf} {part}".strip() if buf else part
        else:
            if len(buf) >= MIN_CHUNK_CHARS:
                chunks.append(buf[:MAX_CHARS_PER_CHUNK].strip())
            buf = part
        if len(buf) >= MAX_CHARS_PER_CHUNK:
            chunks.append(buf[:MAX_CHARS_PER_CHUNK].strip())
            buf = ""
    if len(buf) >= MIN_CHUNK_CHARS:
        chunks.append(buf[:MAX_CHARS_PER_CHUNK].strip())
    return chunks


def find_pdf(filename: str) -> Path | None:
    if (PDF_DIR / filename).exists():
        return PDF_DIR / filename
    # fallback: match por prefixo (encoding)
    stem = filename.split(".")[0][:20].lower()
    for p in PDF_DIR.glob("*.pdf"):
        if stem in p.name.lower() or p.name.lower().startswith(stem[:12]):
            return p
    return None


def extract_pdf(path: Path, source_label: str) -> list[dict]:
    reader = PdfReader(str(path))
    full_text = []
    pages = min(len(reader.pages), MAX_PAGES_PER_PDF)
    for i in range(pages):
        try:
            page_text = reader.pages[i].extract_text() or ""
        except Exception:
            continue
        if page_text.strip():
            full_text.append(page_text)
    text = "\n\n".join(full_text)
    entries: list[dict] = []
    for idx, chunk in enumerate(chunk_paragraphs(text)):
        if len(chunk) < MIN_CHUNK_CHARS:
            continue
        topics = detect_topics(chunk)
        entries.append({
            "id": f"{path.stem}_{idx}",
            "source": source_label,
            "sourceFile": path.name,
            "topics": topics,
            "keywords": extract_keywords(chunk),
            "content": chunk,
        })
        if len(entries) >= MAX_ENTRIES_PER_SOURCE:
            break
    return entries


def main() -> None:
    per_source: list[list[dict]] = []
    sources_meta: list[dict] = []

    for filename, label in PDF_SOURCES:
        path = find_pdf(filename)
        if not path:
            print(f"AVISO: não encontrado {filename}")
            continue
        print(f"Processando: {path.name}")
        entries = extract_pdf(path, label)
        per_source.append(entries)
        sources_meta.append({
            "file": path.name,
            "label": label,
            "entries": len(entries),
        })

    def score(e: dict) -> int:
        generic = 1 if e["topics"] == ["geral"] else 0
        return len(e["topics"]) * 3 + len(e["keywords"]) - generic * 5

    ranked_buckets = [
        sorted(bucket, key=score, reverse=True) for bucket in per_source
    ]

    # Mescla round-robin para representar todos os PDFs
    all_entries: list[dict] = []
    idx = 0
    while len(all_entries) < MAX_ENTRIES_TOTAL:
        added = False
        for bucket in ranked_buckets:
            if idx < len(bucket):
                all_entries.append(bucket[idx])
                added = True
                if len(all_entries) >= MAX_ENTRIES_TOTAL:
                    break
        if not added:
            break
        idx += 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": 1,
        "description": "Base de conhecimento em psicologia, psicanálise e comportamento para o Mindo.",
        "sources": sources_meta,
        "entryCount": len(all_entries),
        "entries": all_entries,
    }
    OUT_FILE.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    size_kb = OUT_FILE.stat().st_size / 1024
    print(f"\nGerado: {OUT_FILE} ({size_kb:.1f} KB, {len(all_entries)} entradas)")


if __name__ == "__main__":
    main()

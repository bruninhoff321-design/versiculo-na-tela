#!/usr/bin/env python3
"""Importa a edição Textus Receptus 2018.2.0 da Bíblia Livre sem alterar textos.

Uso: python scripts/importar_biblia_livre.py caminho/bliv-tr_vpl.zip
Fonte: https://github.com/blivre/BibliaLivre/releases/tag/2018.2.0
Licença e crédito: veja LICENCIAMENTO-TRADUCAO.md.
"""

import argparse
import hashlib
import json
import re
from pathlib import Path
from zipfile import ZipFile


SOURCE_SHA256 = "af8d9876919c4ca67195b8d8adcb9998a63f25ea4509750574ab6a7eedb9e2f1"
VERSE_RE = re.compile(r"^([A-Z0-9]+) ([0-9]+):([0-9]+) (.+)$")

# Ordem e nomes da edição protestante de 66 livros; as abreviações mantêm
# os IDs já usados pela versão de amostra para preservar favoritos e histórico.
BOOKS = [
    ("GEN", "Gênesis", "gen"), ("EXO", "Êxodo", "exo"),
    ("LEV", "Levítico", "lev"), ("NUM", "Números", "num"),
    ("DEU", "Deuteronômio", "deu"), ("JOS", "Josué", "jos"),
    ("JDG", "Juízes", "jui"), ("RUT", "Rute", "rut"),
    ("1SA", "1 Samuel", "1sa"), ("2SA", "2 Samuel", "2sa"),
    ("1KI", "1 Reis", "1re"), ("2KI", "2 Reis", "2re"),
    ("1CH", "1 Crônicas", "1cr"), ("2CH", "2 Crônicas", "2cr"),
    ("EZR", "Esdras", "esd"), ("NEH", "Neemias", "nee"),
    ("EST", "Ester", "est"), ("JOB", "Jó", "job"),
    ("PSA", "Salmos", "sal"), ("PRO", "Provérbios", "pro"),
    ("ECC", "Eclesiastes", "ecl"), ("SOL", "Cânticos", "can"),
    ("ISA", "Isaías", "isa"), ("JER", "Jeremias", "jer"),
    ("LAM", "Lamentações", "lam"), ("EZE", "Ezequiel", "eze"),
    ("DAN", "Daniel", "dan"), ("HOS", "Oseias", "ose"),
    ("JOE", "Joel", "joe"), ("AMO", "Amós", "amo"),
    ("OBA", "Obadias", "oba"), ("JON", "Jonas", "jon"),
    ("MIC", "Miqueias", "miq"), ("NAH", "Naum", "nau"),
    ("HAB", "Habacuque", "hab"), ("ZEP", "Sofonias", "sof"),
    ("HAG", "Ageu", "age"), ("ZEC", "Zacarias", "zac"),
    ("MAL", "Malaquias", "mal"), ("MAT", "Mateus", "mat"),
    ("MAR", "Marcos", "mar"), ("LUK", "Lucas", "luc"),
    ("JOH", "João", "joa"), ("ACT", "Atos", "ato"),
    ("ROM", "Romanos", "rom"), ("1CO", "1 Coríntios", "1co"),
    ("2CO", "2 Coríntios", "2co"), ("GAL", "Gálatas", "gal"),
    ("EPH", "Efésios", "efe"), ("PHI", "Filipenses", "fil"),
    ("COL", "Colossenses", "col"), ("1TH", "1 Tessalonicenses", "1te"),
    ("2TH", "2 Tessalonicenses", "2te"), ("1TI", "1 Timóteo", "1ti"),
    ("2TI", "2 Timóteo", "2ti"), ("TIT", "Tito", "tit"),
    ("PHM", "Filemom", "fim"), ("HEB", "Hebreus", "heb"),
    ("JAM", "Tiago", "tia"), ("1PE", "1 Pedro", "1pe"),
    ("2PE", "2 Pedro", "2pe"), ("1JO", "1 João", "1jo"),
    ("2JO", "2 João", "2jo"), ("3JO", "3 João", "3jo"),
    ("JUD", "Judas", "jud"), ("REV", "Apocalipse", "apo"),
]
BOOK_BY_CODE = {code: (number, name, abbr)
                for number, (code, name, abbr) in enumerate(BOOKS, 1)}


def import_verses(source: Path, curated_path: Path, output: Path) -> list[dict]:
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError(f"Arquivo-fonte diferente da edição validada: {digest}")
    with ZipFile(source) as archive:
        lines = archive.read("bliv-tr_vpl.txt").decode("utf-8-sig").splitlines()
    curated = json.loads(curated_path.read_text(encoding="utf-8"))
    verses = []
    seen = set()
    for line_number, line in enumerate(lines, 1):
        match = VERSE_RE.fullmatch(line)
        if match is None:
            raise ValueError(f"Linha {line_number} fora do formato VPL")
        code, chapter, verse_number, text = match.groups()
        number, book, abbr = BOOK_BY_CODE[code]
        verse_id = f"{abbr}.{chapter}.{verse_number}"
        if verse_id in seen:
            raise ValueError(f"Referência duplicada: {verse_id}")
        seen.add(verse_id)
        metadata = curated.get(verse_id, {})
        verses.append({
            "id": verse_id,
            "book": book,
            "bookAbbr": abbr,
            "bookNumber": number,
            "chapter": int(chapter),
            "verse": int(verse_number),
            "text": text,
            "translationId": "blivre-tr-2018.2.0",
            "themes": metadata.get("themes", []),
            "keywords": metadata.get("keywords", []),
        })
    if len(verses) != 31102 or len({v["book"] for v in verses}) != 66:
        raise ValueError("A edição esperada tem 31.102 versículos e 66 livros")
    if set(curated) - seen:
        raise ValueError(f"Referências temáticas ausentes: {set(curated) - seen}")
    output.write_text(json.dumps(verses, ensure_ascii=False, separators=(",", ":")),
                      encoding="utf-8")
    return verses


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--curated", type=Path,
                        default=Path("assets/curated_tags.json"))
    parser.add_argument("--output", type=Path,
                        default=Path("assets/verses.json"))
    args = parser.parse_args()
    result = import_verses(args.source, args.curated, args.output)
    print(f"Importados {len(result)} versículos para {args.output}")

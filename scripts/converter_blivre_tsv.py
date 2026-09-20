#!/usr/bin/env python3
"""
converter_blivre_tsv.py
------------------------
Converte o texto-fonte da Bíblia Livre (BLIVRE), no formato bliv.tsv, para o
schema JSON usado pelo banco de versículos do app "Versículo na Tela".

FONTE DO ARQUIVO DE ENTRADA (baixe um dos dois, mesmo texto/licença):
  - Oficial:  https://github.com/blivre/BibliaLivre/releases/tag/2018.2.0
              (baixe vpl.zip e converta as linhas "livro capitulo:versiculo texto"
              para o formato TSV abaixo, ou use o mirror já pronto:)
  - Mirror TSV pronto: https://github.com/DomBito/bliv/raw/refs/heads/main/bliv.tsv

FORMATO DE ENTRADA ESPERADO (TSV, sem cabeçalho, 6 colunas separadas por TAB):
  1. nome do livro       (ex: "Salmos")
  2. abreviação do livro (ex: "sal")
  3. número do livro     (ex: 19)
  4. capítulo            (ex: 23)
  5. versículo           (ex: 1)
  6. texto do versículo

LICENÇA DO TEXTO: Bíblia Livre (BLIVRE) — Creative Commons Atribuição 3.0
Brasil (CC BY 3.0 BR). Uso comercial permitido com atribuição. Ver
LICENCIAMENTO-TRADUCAO.md para o texto de crédito obrigatório.

O QUE ESTE SCRIPT FAZ:
  - Lê o TSV e gera um verses.json no schema do app (book, chapter, verse,
    text, translationId, themes, keywords).
  - Sugere temas automaticamente por correspondência de palavras-chave contra
    taxonomia_temas.json. Isso é só um ponto de partida (campo
    "suggestedThemes") — a curadoria final ("themes") deve ser revisada por
    uma pessoa antes de ir para produção. Nenhum texto de versículo é gerado
    ou alterado por este processo: só classificação de texto já existente.

USO:
  python3 converter_blivre_tsv.py bliv.tsv --taxonomia taxonomia_temas.json --saida verses.json
  python3 converter_blivre_tsv.py bliv.tsv --amostra 500   (para testar rápido com só 500 linhas)
"""

import argparse
import json
import sys
import unicodedata
from pathlib import Path


def normalizar(texto: str) -> str:
    """minúsculas + remove acentos, para comparação de palavras-chave."""
    texto = texto.lower()
    texto = unicodedata.normalize("NFD", texto)
    texto = "".join(c for c in texto if unicodedata.category(c) != "Mn")
    return texto


def carregar_taxonomia(caminho: Path):
    with open(caminho, encoding="utf-8") as f:
        data = json.load(f)
    temas = []
    for tema in data["temas"]:
        temas.append({
            "id": tema["id"],
            "keywords_normalizadas": [normalizar(k) for k in tema["keywords"]],
        })
    return temas


def sugerir_temas(texto_normalizado: str, temas) -> list:
    sugestoes = []
    for tema in temas:
        for kw in tema["keywords_normalizadas"]:
            if kw in texto_normalizado:
                sugestoes.append(tema["id"])
                break
    return sugestoes


def converter(entrada: Path, saida: Path, taxonomia_path: Path, limite: int | None):
    temas = carregar_taxonomia(taxonomia_path) if taxonomia_path else []
    versiculos = []
    ignoradas = 0

    with open(entrada, encoding="utf-8", errors="replace") as f:
        for i, linha in enumerate(f):
            if limite is not None and i >= limite:
                break
            linha = linha.rstrip("\n")
            if not linha:
                continue
            campos = linha.split("\t")
            if len(campos) != 6:
                ignoradas += 1
                continue
            livro, abrev, num_livro, capitulo, versiculo, texto = campos
            try:
                capitulo_i = int(capitulo)
                versiculo_i = int(versiculo)
                num_livro_i = int(num_livro)
            except ValueError:
                ignoradas += 1
                continue

            texto = texto.strip()
            texto_norm = normalizar(texto)
            registro = {
                "id": f"{abrev.strip().lower()}.{capitulo_i}.{versiculo_i}",
                "book": livro.strip(),
                "bookAbbr": abrev.strip(),
                "bookNumber": num_livro_i,
                "chapter": capitulo_i,
                "verse": versiculo_i,
                "text": texto,
                "translationId": "blivre-tr",
                "themes": [],
                "suggestedThemes": sugerir_temas(texto_norm, temas),
                "keywords": [],
            }
            versiculos.append(registro)

            if (i + 1) % 5000 == 0:
                print(f"  processados {i + 1} linhas...", file=sys.stderr)

    with open(saida, "w", encoding="utf-8") as f:
        json.dump(versiculos, f, ensure_ascii=False, indent=1)

    print(f"OK: {len(versiculos)} versículos gravados em {saida}")
    if ignoradas:
        print(f"AVISO: {ignoradas} linhas ignoradas (formato inesperado)")
    com_sugestao = sum(1 for v in versiculos if v["suggestedThemes"])
    print(f"{com_sugestao} versículos receberam ao menos 1 tema sugerido automaticamente "
          f"({com_sugestao * 100 // max(len(versiculos), 1)}%). Revise antes de usar em produção.")


def main():
    parser = argparse.ArgumentParser(description="Converte bliv.tsv (Bíblia Livre) para o schema JSON do app.")
    parser.add_argument("entrada", type=Path, help="caminho do arquivo bliv.tsv baixado")
    parser.add_argument("--saida", type=Path, default=Path("verses.json"), help="arquivo JSON de saída")
    parser.add_argument("--taxonomia", type=Path, default=Path("taxonomia_temas.json"),
                         help="arquivo de taxonomia de temas/palavras-chave")
    parser.add_argument("--amostra", type=int, default=None,
                         help="processar só as N primeiras linhas (para teste rápido)")
    args = parser.parse_args()

    if not args.entrada.exists():
        sys.exit(f"Arquivo de entrada não encontrado: {args.entrada}")

    taxonomia_path = args.taxonomia if args.taxonomia.exists() else None
    if taxonomia_path is None:
        print("AVISO: taxonomia_temas.json não encontrado — gerando sem sugestão de temas.", file=sys.stderr)

    converter(args.entrada, args.saida, taxonomia_path, args.amostra)


if __name__ == "__main__":
    main()

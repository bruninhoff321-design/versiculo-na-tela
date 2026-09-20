# assets/verses.json — ATENÇÃO

O `verses.json` incluído aqui é uma AMOSTRA de 34 versículos com
`"translationId": "placeholder-amostra"`, escrita como texto de
desenvolvimento/teste — NÃO é a transcrição literal da Bíblia Livre
(BLIVRE).

Antes de publicar o app nas lojas:

1. Baixe o texto-fonte real (ver LICENCIAMENTO-TRADUCAO.md na raiz do
   projeto).
2. Rode `scripts/converter_blivre_tsv.py` para gerar um `verses.json`
   completo a partir do texto licenciado de verdade.
3. Revise os temas sugeridos automaticamente antes de considerar o banco
   pronto para produção.
4. Substitua este arquivo pelo gerado no passo 2.

O schema (campos e formato) já é o definitivo — só o conteúdo de texto
desta amostra é temporário.

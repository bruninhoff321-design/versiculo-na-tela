# Texto bíblico embarcado

`verses.json` contém os 31.102 versículos dos 66 livros da edição
Textus Receptus 2018.2.0 da Bíblia Livre (BLIVRE), importados sem
reescrever o texto. `curated_tags.json` contém apenas classificações
temáticas de 36 referências para a função de busca por situação; essas
classificações não fazem parte da tradução.

Para reproduzir o arquivo, baixe `bliv-tr_vpl.zip` da [versão
2018.2.0](https://github.com/blivre/BibliaLivre/releases/tag/2018.2.0) e rode:

```text
python scripts/importar_biblia_livre.py caminho/bliv-tr_vpl.zip
```

O importador confere o SHA-256 do arquivo-fonte, 31.102 referências
distintas e 66 livros. Veja `LICENCIAMENTO-TRADUCAO.md` para o crédito
obrigatório.

# Liberar o app para quem comprou na Cakto

O app pede o e-mail da compra na primeira vez que abre. Um servidor
gratuito (Supabase) recebe os avisos de venda da Cakto e confirma se o
e-mail comprou. Cada compra libera até 3 celulares.

Enquanto a variável `ACTIVATION_URL` não estiver configurada no GitHub, o
app abre liberado para todos (bom para testar).

## 1. Criar o servidor (Supabase, grátis)

1. Crie uma conta em supabase.com e um projeto novo (região São Paulo).
2. Vá em **SQL Editor → New query**, cole o conteúdo de
   `supabase/tabela.sql` e clique em **Run**.
3. Vá em **Edge Functions → Deploy a new function → Via Editor**:
   - Nome `cakto`: cole o código de `supabase/functions/cakto/index.ts`.
   - Nome `ativar`: cole o código de `supabase/functions/ativar/index.ts`.
   - Nas duas, desligue **Enforce JWT verification** (a Cakto e o app não
     mandam login do Supabase).
4. Em **Edge Functions → Secrets**, crie o secret `CAKTO_SECRET` com a chave
   secreta do webhook da Cakto (passo 2.3).

Os endereços ficam assim (troque `SEU-PROJETO`):

- `https://SEU-PROJETO.supabase.co/functions/v1/cakto`
- `https://SEU-PROJETO.supabase.co/functions/v1/ativar`

## 2. Configurar a Cakto

1. Crie o produto "Bíblia e Oração" por R$ 9,50, pagamento único.
2. Na entrega do produto, coloque o link de download do APK e a instrução:
   "Instale o app e digite este mesmo e-mail para liberar".
3. Em **Integrações → Webhooks**, crie um webhook com a URL da função
   `cakto` e marque os eventos **Compra aprovada**, **Reembolso** e
   **Chargeback**. Copie a chave secreta (secret) e coloque no Supabase
   (passo 1.4).
4. Use o botão de teste da Cakto para conferir.

## 3. Ligar no app

No GitHub: **Settings → Secrets and variables → Actions → Variables**:

- `ACTIVATION_URL` = endereço da função `ativar`
- `CHECKOUT_URL` = link do checkout da Cakto (aparece na tela de liberação
  para quem ainda não comprou)

Na próxima compilação o APK já sai pedindo o e-mail.

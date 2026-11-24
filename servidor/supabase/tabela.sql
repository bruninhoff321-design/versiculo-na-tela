-- Compras do Bíblia e Oração feitas na Cakto.
-- Rode isto uma vez no Supabase: SQL Editor > New query > colar > Run.
create table if not exists public.compras (
  email       text primary key,
  status      text not null default 'ativo',   -- ativo | cancelado
  pedido      text,
  aparelhos   text[] not null default '{}',     -- celulares que já ativaram
  atualizado  timestamptz not null default now()
);

-- Ninguém de fora lê ou escreve na tabela direto: só as funções do servidor.
alter table public.compras enable row level security;

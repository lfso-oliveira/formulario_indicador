-- =============================================================================
-- Schema completo: indicadores (Supabase / PostgreSQL)
-- Cole no SQL Editor e execute de uma vez (ou por blocos).
-- Alternativa local: `DATABASE_URL=... npm run db:ensure` (ver scripts/ensure-schema.mjs).
--
-- Depois de rodar: formulário e /admin/ usam a mesma chave "anon" (config.js).
-- A política de SELECT abaixo permite listar envios no admin: qualquer um com
-- a anon key consegue ler a tabela — não exponha a chave publicamente.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Limpar políticas antigas nesta tabela (evita nomes duplicados / políticas a
-- mais que bloqueiam INSERT)
-- -----------------------------------------------------------------------------
do $$
declare
  r record;
begin
  for r in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'indicadores_envios'
  loop
    execute format('drop policy if exists %I on public.indicadores_envios', r.policyname);
  end loop;
end$$;

-- -----------------------------------------------------------------------------
-- Tabela principal: um registo por cada envio do formulário
-- -----------------------------------------------------------------------------
create table if not exists public.indicadores_envios (
  id uuid primary key default gen_random_uuid(),
  capitao text not null default '',
  linhas jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

comment on table public.indicadores_envios is
  'Envios do planeamento de turnos (capitão + grelha JSON).';

create index if not exists indicadores_envios_created_at_idx
  on public.indicadores_envios (created_at desc);

-- Dono esperado pelo Supabase (facilita GRANT a partir do SQL Editor)
alter table public.indicadores_envios owner to postgres;

-- -----------------------------------------------------------------------------
-- Modelo antigo (uma linha única), se existir e já não precisar:
-- drop table if exists public.indicadores_planejamento;
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- RLS + políticas
-- O PostgREST usa o papel "anon" com a chave pública anon do Supabase.
-- Incluímos também "authenticated" por si usar sessão / outra chave no futuro.
-- -----------------------------------------------------------------------------
alter table public.indicadores_envios enable row level security;

-- Inserir novos envios (formulário público)
create policy "indicadores_envios_insert_anon"
  on public.indicadores_envios
  for insert
  to anon
  with check (true);

create policy "indicadores_envios_insert_authenticated"
  on public.indicadores_envios
  for insert
  to authenticated
  with check (true);

-- Rede de segurança: qualquer papel que o PostgREST use consegue inserir
create policy "indicadores_envios_insert_public"
  on public.indicadores_envios
  for insert
  TO PUBLIC
  with check (true);

-- Leitura para a página /admin/ com a mesma chave anon do formulário
create policy "indicadores_envios_select_anon"
  on public.indicadores_envios
  for select
  to anon
  using (true);

create policy "indicadores_envios_select_authenticated"
  on public.indicadores_envios
  for select
  to authenticated
  using (true);

create policy "indicadores_envios_select_public"
  on public.indicadores_envios
  for select
  TO PUBLIC
  using (true);

-- Opcional: utilizadores autenticados só veem os próprios envios (descomente
-- se no futuro associar user_id à tabela e quiser SELECT por utilizador)
-- create policy "indicadores_envios_select_own"
--   on public.indicadores_envios for select to authenticated
--   using (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- Permissões na tabela (INSERT formulário; SELECT para listar no /admin/)
-- -----------------------------------------------------------------------------
grant usage on schema public to anon, authenticated, service_role;

grant all privileges on table public.indicadores_envios to postgres;
grant all privileges on table public.indicadores_envios to service_role;

grant insert, select on table public.indicadores_envios to anon, authenticated;

-- =============================================================================
-- Fim. O SQL Editor corre como superuser (ignora RLS); o teste real é no site
-- com Enviar ou: curl + header apikey anon no endpoint REST.
-- =============================================================================

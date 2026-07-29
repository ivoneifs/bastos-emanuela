-- ═══════════════════════════════════════════════════════════════════════
--  CORREÇÃO DE SEGURANÇA — sessão anônima não é a Emanuela
--
--  RODE ESTE ARQUIVO COM PRIORIDADE.
--
--  O problema
--  ──────────
--  No Supabase, quem entra por "login anônimo" recebe o mesmo papel
--  `authenticated` de quem entra com e-mail e senha. As políticas que
--  eu escrevi diziam apenas "to authenticated" — então uma sessão
--  anônima passava por elas e conseguia ler a agenda e escrever no
--  resto do banco.
--
--  A correção
--  ──────────
--  Toda política de escrita, e a leitura da agenda, passam a exigir
--  que a sessão NÃO seja anônima. O visitante do site continua lendo
--  normalmente o que é público — isso não muda nada para ele.
--
--  Pode rodar mais de uma vez sem quebrar nada.
-- ═══════════════════════════════════════════════════════════════════════


-- ─────────────── quem é de verdade a dona do painel ───────────────

create or replace function public.eh_a_dona()
returns boolean
language sql stable
as $$
  select
    auth.role() = 'authenticated'
    and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false;
$$;

comment on function public.eh_a_dona is
  'Verdadeiro só para sessão iniciada com e-mail e senha. Sessão anônima retorna falso.';


-- ─────────────── reaplica as regras nas tabelas públicas ───────────────
--  Leitura continua liberada. Escrita agora exige sessão de verdade.

create or replace function public.aplicar_regras(nome text)
returns void language plpgsql as $$
begin
  execute format('alter table public.%I enable row level security', nome);

  execute format('drop policy if exists "todos leem" on public.%I', nome);
  execute format('create policy "todos leem" on public.%I for select to anon, authenticated using (true)', nome);

  execute format('drop policy if exists "logada insere" on public.%I', nome);
  execute format('create policy "logada insere" on public.%I for insert to authenticated with check (public.eh_a_dona())', nome);

  execute format('drop policy if exists "logada edita" on public.%I', nome);
  execute format('create policy "logada edita" on public.%I for update to authenticated using (public.eh_a_dona()) with check (public.eh_a_dona())', nome);

  execute format('drop policy if exists "logada apaga" on public.%I', nome);
  execute format('create policy "logada apaga" on public.%I for delete to authenticated using (public.eh_a_dona())', nome);
end;
$$;

select public.aplicar_regras('conteudo');
select public.aplicar_regras('areas');
select public.aplicar_regras('faq');


-- ─────────────── postagens ───────────────

drop policy if exists "logada escreve" on public.posts;
create policy "logada escreve" on public.posts
  for insert to authenticated with check (public.eh_a_dona());

drop policy if exists "logada edita" on public.posts;
create policy "logada edita" on public.posts
  for update to authenticated using (public.eh_a_dona()) with check (public.eh_a_dona());

drop policy if exists "logada apaga" on public.posts;
create policy "logada apaga" on public.posts
  for delete to authenticated using (public.eh_a_dona());


-- ─────────────── agenda: o caso mais grave ───────────────
--  Aqui a LEITURA também passa a exigir sessão de verdade.

drop policy if exists "agenda: so logada le"     on public.agenda;
drop policy if exists "agenda: so logada insere" on public.agenda;
drop policy if exists "agenda: so logada edita"  on public.agenda;
drop policy if exists "agenda: so logada apaga"  on public.agenda;

create policy "agenda: so a dona le"
  on public.agenda for select to authenticated using (public.eh_a_dona());

create policy "agenda: so a dona insere"
  on public.agenda for insert to authenticated with check (public.eh_a_dona());

create policy "agenda: so a dona edita"
  on public.agenda for update to authenticated
  using (public.eh_a_dona()) with check (public.eh_a_dona());

create policy "agenda: so a dona apaga"
  on public.agenda for delete to authenticated using (public.eh_a_dona());


-- ─────────────── imagens ───────────────

drop policy if exists "logada envia capa"          on storage.objects;
drop policy if exists "logada troca capa"          on storage.objects;
drop policy if exists "logada remove capa"         on storage.objects;
drop policy if exists "logada envia imagem do site" on storage.objects;
drop policy if exists "logada troca imagem do site" on storage.objects;
drop policy if exists "logada remove imagem do site" on storage.objects;

create policy "a dona envia imagem"
  on storage.objects for insert to authenticated
  with check (bucket_id in ('blog','site') and public.eh_a_dona());

create policy "a dona troca imagem"
  on storage.objects for update to authenticated
  using (bucket_id in ('blog','site') and public.eh_a_dona());

create policy "a dona remove imagem"
  on storage.objects for delete to authenticated
  using (bucket_id in ('blog','site') and public.eh_a_dona());


-- ═══════════════════════════════════════════════════════════════════════
--  DEPOIS DE RODAR, faça os dois ajustes no painel do Supabase:
--
--   1) Authentication → Sign In / Providers
--      • DESLIGUE "Allow new users to sign up"
--      • DESLIGUE "Allow anonymous sign-ins"
--
--      O SQL acima já protege o banco mesmo se ficarem ligados, mas
--      desligar remove o problema pela raiz.
--
--   2) Confira que a conta da Emanuela continua entrando no painel.
--      Ela entra com e-mail e senha, então passa por eh_a_dona() sem
--      problema. Se por acaso não entrar, me avise.
-- ═══════════════════════════════════════════════════════════════════════

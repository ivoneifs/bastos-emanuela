-- ═══════════════════════════════════════════════════════════════
--  Parte 3 — agenda interna
--
--  Rode no SQL Editor, depois das partes 1 e 2.
--  Pode rodar mais de uma vez sem quebrar nada.
--
--  ATENÇÃO — esta tabela guarda dado de paciente, que é dado
--  sensível de saúde pela LGPD. Por isso ela é a única do banco
--  que o visitante do site NÃO consegue ler de jeito nenhum:
--  as regras abaixo liberam apenas quem está logada no painel.
-- ═══════════════════════════════════════════════════════════════


create table if not exists public.agenda (
  id            uuid primary key default gen_random_uuid(),

  paciente      text        not null,
  contato       text,                                   -- telefone ou WhatsApp
  responsavel   text,                                   -- para atendimento infantojuvenil

  data          date        not null,
  hora          time        not null default '08:00',
  duracao       integer     not null default 50,        -- em minutos

  tipo          text        not null default 'Sessão',
  formato       text        not null default 'Presencial',
  situacao      text        not null default 'Marcado',

  valor         numeric(10,2),
  pago          boolean     not null default false,

  observacoes   text,

  criado_em     timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),

  constraint tipo_valido
    check (tipo in ('Pré-consulta','Sessão','Avaliação','Devolutiva','Reabilitação','Outro')),
  constraint formato_valido
    check (formato in ('Presencial','Vídeo')),
  constraint situacao_valida
    check (situacao in ('Marcado','Realizado','Faltou','Cancelado'))
);

comment on table public.agenda is
  'Agenda interna. Contém dado sensível de paciente: leitura só para usuária autenticada.';

create index if not exists agenda_data_idx on public.agenda (data, hora);
create index if not exists agenda_situacao_idx on public.agenda (situacao, data);

drop trigger if exists agenda_atualizado_em on public.agenda;
create trigger agenda_atualizado_em
  before update on public.agenda
  for each row execute function public.marcar_atualizacao();


-- ─────────────── regras de acesso ───────────────
--
--  Diferente das outras tabelas: NÃO existe política para "anon".
--  Sem sessão iniciada, a tabela simplesmente não devolve nada,
--  mesmo com a chave publicável em mãos.

alter table public.agenda enable row level security;

drop policy if exists "agenda: so logada le"     on public.agenda;
drop policy if exists "agenda: so logada insere" on public.agenda;
drop policy if exists "agenda: so logada edita"  on public.agenda;
drop policy if exists "agenda: so logada apaga"  on public.agenda;

create policy "agenda: so logada le"
  on public.agenda for select to authenticated using (true);

create policy "agenda: so logada insere"
  on public.agenda for insert to authenticated with check (true);

create policy "agenda: so logada edita"
  on public.agenda for update to authenticated using (true) with check (true);

create policy "agenda: so logada apaga"
  on public.agenda for delete to authenticated using (true);

-- garante que ninguém anônimo alcance a tabela nem por engano
revoke all on public.agenda from anon;


-- ═══════════════════════════════════════════════════════════════
--  Pronto. A aba "Agenda" do painel passa a funcionar.
--
--  Teste de segurança, se quiser conferir: abra o site sem estar
--  logada e rode no console do navegador —
--
--    fetch('https://yzxoyxzmteqvmayqtdly.supabase.co/rest/v1/agenda?select=paciente',
--      {headers:{apikey:'sb_publishable_...'}}).then(r=>r.json()).then(console.log)
--
--  A resposta tem que ser uma lista vazia ou erro de permissão.
-- ═══════════════════════════════════════════════════════════════

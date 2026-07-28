-- ═══════════════════════════════════════════════════════════════
--  Parte 2 — todo o resto do site editável pelo painel
--
--  Rode depois do schema.sql, no SQL Editor. Pode rodar mais de
--  uma vez sem duplicar nada.
--
--  Cria três tabelas:
--    conteudo  — textos soltos e imagens (hero, sobre, contato…)
--    areas     — os cards de "Áreas de atuação"
--    faq       — as perguntas de "Dúvidas frequentes"
-- ═══════════════════════════════════════════════════════════════


-- ─────────────── regras de acesso, iguais para as três ───────────────
-- Visitante lê. Só quem está logada escreve.

create or replace function public.aplicar_regras(nome text)
returns void language plpgsql as $$
begin
  execute format('alter table public.%I enable row level security', nome);

  execute format('drop policy if exists "todos leem" on public.%I', nome);
  execute format('create policy "todos leem" on public.%I for select to anon, authenticated using (true)', nome);

  execute format('drop policy if exists "logada insere" on public.%I', nome);
  execute format('create policy "logada insere" on public.%I for insert to authenticated with check (true)', nome);

  execute format('drop policy if exists "logada edita" on public.%I', nome);
  execute format('create policy "logada edita" on public.%I for update to authenticated using (true) with check (true)', nome);

  execute format('drop policy if exists "logada apaga" on public.%I', nome);
  execute format('create policy "logada apaga" on public.%I for delete to authenticated using (true)', nome);
end;
$$;


-- ═══════════ 1. textos soltos e imagens ═══════════

create table if not exists public.conteudo (
  chave         text primary key,
  valor         text not null default '',
  tipo          text not null default 'texto',   -- texto | textao | imagem | link
  grupo         text not null default 'Geral',   -- como aparece agrupado no painel
  rotulo        text not null,                   -- nome amigável do campo
  dica          text,
  ordem         integer not null default 0,
  atualizado_em timestamptz not null default now()
);

comment on table public.conteudo is 'Cada linha é um pedaço editável do site, identificado por data-c no HTML';

drop trigger if exists conteudo_atualizado_em on public.conteudo;
create trigger conteudo_atualizado_em
  before update on public.conteudo
  for each row execute function public.marcar_atualizacao();

alter table public.conteudo
  drop constraint if exists conteudo_tipo_valido;
alter table public.conteudo
  add constraint conteudo_tipo_valido check (tipo in ('texto','textao','imagem','link'));

select public.aplicar_regras('conteudo');


-- ═══════════ 2. áreas de atuação ═══════════

create table if not exists public.areas (
  id            uuid primary key default gen_random_uuid(),
  icone         text not null default 'circle',
  titulo        text not null,
  texto         text not null default '',
  ordem         integer not null default 0,
  ativo         boolean not null default true,
  atualizado_em timestamptz not null default now()
);

comment on table public.areas is 'Cards da seção "Áreas de atuação"';

drop trigger if exists areas_atualizado_em on public.areas;
create trigger areas_atualizado_em
  before update on public.areas
  for each row execute function public.marcar_atualizacao();

select public.aplicar_regras('areas');


-- ═══════════ 3. dúvidas frequentes ═══════════

create table if not exists public.faq (
  id            uuid primary key default gen_random_uuid(),
  pergunta      text not null,
  resposta      text not null default '',
  ordem         integer not null default 0,
  ativo         boolean not null default true,
  atualizado_em timestamptz not null default now()
);

comment on table public.faq is 'Perguntas da seção "Dúvidas frequentes"';

drop trigger if exists faq_atualizado_em on public.faq;
create trigger faq_atualizado_em
  before update on public.faq
  for each row execute function public.marcar_atualizacao();

select public.aplicar_regras('faq');


-- ═══════════ 4. o conteúdo que está no ar hoje ═══════════

insert into public.conteudo (chave, valor, tipo, grupo, rotulo, dica, ordem) values

-- Topo
('marca.nome',        'Emanuela Bastos', 'texto', 'Topo', 'Nome', null, 1),
('marca.papel',       'Neuropsicóloga clínica · CRP 03/11614', 'texto', 'Topo', 'Primeira linha abaixo do nome', null, 2),
('marca.papel2',      'Infantojuvenil e adulto', 'texto', 'Topo', 'Segunda linha abaixo do nome', null, 3),
('contato.whatsapp',  '5574981249127', 'texto', 'Topo', 'WhatsApp (só números, com 55)', 'Muda todos os botões do site de uma vez.', 4),
('contato.instagram', 'https://www.instagram.com/emanuelabastos.psi', 'link', 'Topo', 'Instagram', null, 5),

-- Início
('hero.eyebrow',      'Neuropsicologia', 'texto', 'Início', 'Etiqueta acima do título', null, 1),
('hero.titulo1',      'Um espaço para você', 'texto', 'Início', 'Título — primeira linha', null, 2),
('hero.titulo2',      'colocar as coisas no lugar.', 'texto', 'Início', 'Título — segunda linha (em itálico)', null, 3),
('hero.paragrafo',    'A terapia é um encontro reservado, no seu tempo, para olhar com calma para o que vem incomodando. Aqui você fala sem pressa e sem julgamento, e a gente organiza junto o que hoje parece confuso.', 'textao', 'Início', 'Parágrafo de abertura', null, 4),
('hero.atendimento',  'Atendimento on-line e presencial · Irecê e região, BA', 'texto', 'Início', 'Linha de atendimento', null, 5),
('hero.botao',        'Agendar uma sessão', 'texto', 'Início', 'Texto do botão principal', null, 6),
('hero.selo',         '50 min', 'texto', 'Início', 'Destaque do selo sobre a foto', null, 7),
('hero.selo_texto',   'É o tempo de cada sessão, no consultório ou por vídeo.', 'texto', 'Início', 'Texto do selo', null, 8),
('hero.imagem',       'images/emanuela-hero.webp', 'imagem', 'Início', 'Foto principal', 'Formato em pé, 3 por 4. Ideal 1200 × 1600 pixels.', 9),

-- Frase
('citacao.texto',     'Quem olha para fora, sonha. Quem olha para dentro, desperta.', 'textao', 'Frase de impacto', 'Frase', null, 1),
('citacao.autor',     'Carl Gustav Jung', 'texto', 'Frase de impacto', 'Autor', null, 2),

-- Áreas
('areas.eyebrow',     'Áreas de atuação', 'texto', 'Áreas de atuação', 'Etiqueta', null, 1),
('areas.titulo',      'Assuntos que costumam abrir uma conversa.', 'texto', 'Áreas de atuação', 'Título', null, 2),
('areas.intro',       'Você não precisa chegar com o problema já nomeado. Se algo vem pesando, isso já basta para começarmos.', 'textao', 'Áreas de atuação', 'Texto de introdução', null, 3),

-- Sobre
('sobre.eyebrow',     'Sobre mim', 'texto', 'Sobre mim', 'Etiqueta', null, 1),
('sobre.titulo',      'Prazer, eu sou a Emanuela.', 'texto', 'Sobre mim', 'Título', null, 2),
('sobre.p1',          'Sou neuropsicóloga, inscrita no CRP 03/11614, e atendo adolescentes, adultos e idosos em Irecê e região, na Bahia — de forma presencial e também por vídeo.', 'textao', 'Sobre mim', 'Parágrafo 1', null, 3),
('sobre.p2',          'Meu trabalho começa pela escuta. Antes de qualquer proposta, eu preciso entender a sua história, o seu contexto e o que te trouxe até aqui. A partir daí, construímos juntos um caminho de acompanhamento, com objetivos combinados e revisados ao longo do processo.', 'textao', 'Sobre mim', 'Parágrafo 2', null, 4),
('sobre.p3',          'Além do acompanhamento clínico, também realizo avaliação neuropsicológica, com instrumentos aplicados de acordo com a idade e a demanda de cada pessoa.', 'textao', 'Sobre mim', 'Parágrafo 3', null, 5),
('sobre.formacao1',   'Graduação em Psicologia — UNIME, 2012', 'texto', 'Sobre mim', 'Formação 1', null, 6),
('sobre.formacao2',   'Especialização em Neuropsicologia — Realiza', 'texto', 'Sobre mim', 'Formação 2', null, 7),
('sobre.formacao3',   'Especialização em Terapia Cognitivo-Comportamental — Realiza', 'texto', 'Sobre mim', 'Formação 3', null, 8),
('sobre.formacao4',   'Sigilo garantido pelo Código de Ética Profissional', 'texto', 'Sobre mim', 'Formação 4', null, 9),
('sobre.imagem',      'images/emanuela-sobre.webp', 'imagem', 'Sobre mim', 'Foto da seção', 'Formato em pé, 3 por 4. Ideal 900 × 1200 pixels.', 10),

-- Agendamento
('agenda.eyebrow',    'Como funciona', 'texto', 'Como funciona', 'Etiqueta', null, 1),
('agenda.titulo',     'Agendar é simples — em três passos.', 'texto', 'Como funciona', 'Título', null, 2),
('agenda.intro',      'O atendimento acontece presencialmente, no consultório, ou on-line por vídeo — você escolhe o formato que couber melhor na sua rotina.', 'textao', 'Como funciona', 'Texto de introdução', null, 3),
('agenda.p1t',        'Entre em contato pelo WhatsApp', 'texto', 'Como funciona', 'Passo 1 — título', null, 4),
('agenda.p1d',        'Me mande uma mensagem contando, em poucas linhas, o que te levou a procurar terapia. Respondo pessoalmente e tiro as dúvidas iniciais.', 'textao', 'Como funciona', 'Passo 1 — texto', null, 5),
('agenda.p2t',        'Agende a sua sessão', 'texto', 'Como funciona', 'Passo 2 — título', null, 6),
('agenda.p2d',        'Combinamos o dia, o horário e o formato — presencial ou on-line. Você recebe a confirmação com todas as orientações antes do encontro.', 'textao', 'Como funciona', 'Passo 2 — texto', null, 7),
('agenda.p3t',        'Pronto: sessão agendada', 'texto', 'Como funciona', 'Passo 3 — título', null, 8),
('agenda.p3d',        'A sessão dura cerca de 50 minutos e acontece de forma tranquila, no consultório ou on-line. Não é preciso preparar nada — só chegar.', 'textao', 'Como funciona', 'Passo 3 — texto', null, 9),

-- Blog
('blog.eyebrow',      'Blog', 'texto', 'Blog', 'Etiqueta', null, 1),
('blog.titulo',       'Avaliação, reabilitação e neuroeducação.', 'texto', 'Blog', 'Título', null, 2),
('blog.intro',        'Três frentes do meu trabalho, explicadas sem jargão. Conteúdo informativo: não substitui consulta nem serve para autodiagnóstico — é material para você chegar mais informada ou informado à conversa.', 'textao', 'Blog', 'Texto de introdução', null, 3),

-- Dúvidas
('faq.eyebrow',       'Dúvidas frequentes', 'texto', 'Dúvidas', 'Etiqueta', null, 1),
('faq.titulo',        'O que costumam me perguntar antes da primeira sessão.', 'texto', 'Dúvidas', 'Título', null, 2),

-- Chamada final
('final.titulo',      'Dar o primeiro passo já é parte do processo.', 'texto', 'Chamada final', 'Título', null, 1),
('final.texto',       'Se você chegou até aqui, talvez seja um bom momento para conversar. Me mande uma mensagem quando se sentir pronta ou pronto.', 'textao', 'Chamada final', 'Texto', null, 2),
('final.botao',       'Agendar pelo WhatsApp', 'texto', 'Chamada final', 'Texto do botão', null, 3),

-- Rodapé
('rodape.descricao',  'Atendimento psicológico on-line e presencial, com escuta cuidadosa e sigilo garantido pelo Código de Ética Profissional do Psicólogo.', 'textao', 'Rodapé', 'Descrição', null, 1),
('contato.telefone',  '(74) 98124-9127', 'texto', 'Rodapé', 'Telefone como aparece escrito', null, 2),
('contato.email',     'Emanuela.basttos@gmail.com', 'texto', 'Rodapé', 'E-mail', null, 3),
('contato.endereco1', 'Irecê e região — Bahia', 'texto', 'Rodapé', 'Endereço — linha 1', null, 4),
('contato.endereco2', 'Endereço do consultório enviado na confirmação', 'texto', 'Rodapé', 'Endereço — linha 2', null, 5),
('contato.horario',   'Atendimento com hora marcada, presencial e on-line', 'texto', 'Rodapé', 'Horário', null, 6)

on conflict (chave) do nothing;


-- ═══════════ 5. as seis áreas que estão no ar ═══════════

insert into public.areas (icone, titulo, texto, ordem)
select * from (values
 ('wind',        'Ansiedade',              'Preocupação constante, corpo em alerta, dificuldade de desligar. Trabalhamos formas de reconhecer os gatilhos e recuperar o próprio ritmo.', 1),
 ('cloud-rain',  'Depressão',              'Falta de energia, desânimo, perda de interesse pelo que antes fazia sentido. Um espaço para entender esse estado e retomar o contato com a vida.', 2),
 ('users',       'Relacionamentos',        'Conflitos que se repetem, dificuldade de colocar limites, distanciamento na família ou no casal. Olhamos juntos para os padrões que se formaram.', 3),
 ('battery-low', 'Burnout e esgotamento',  'Exaustão que o fim de semana não resolve, irritação fácil, sensação de estar sempre devendo. Um lugar para revisar limites e prioridades.', 4),
 ('compass',     'Autoconhecimento',       'Entender as próprias escolhas, reconhecer o que se repete e ganhar clareza para decidir — mesmo quando não há uma queixa específica.', 5),
 ('moon',        'Insônia',                'Noites em claro, pensamento acelerado na hora de dormir, cansaço que se acumula. Investigamos o que sustenta esse ciclo no dia a dia.', 6)
) as novas(icone, titulo, texto, ordem)
where not exists (select 1 from public.areas);


-- ═══════════ 6. as três dúvidas que estão no ar ═══════════

insert into public.faq (pergunta, resposta, ordem)
select * from (values
 ('Você aceita convênio?',
  'O atendimento é particular. Ao final de cada sessão eu emito recibo, e você pode usá-lo para solicitar reembolso ao seu plano de saúde, quando houver essa previsão no contrato. Se a operadora pedir algum documento adicional, é só me avisar que eu providencio.', 1),
 ('Quanto tempo dura a sessão?',
  'Cada sessão dura cerca de 50 minutos. A frequência mais comum é semanal, mas isso é definido junto com você, considerando a sua demanda e a sua rotina.', 2),
 ('Como é a primeira sessão?',
  'É um encontro de acolhimento. Você conta o que está acontecendo, no seu tempo, e eu escuto. Também explico como conduzo o trabalho, esclareço as combinações sobre sigilo, horários e valores, e respondo às suas dúvidas. Não é preciso preparar nada nem chegar com tudo organizado na cabeça.', 3)
) as novas(pergunta, resposta, ordem)
where not exists (select 1 from public.faq);


-- ═══════════ 7. depósito para as imagens do site ═══════════

insert into storage.buckets (id, name, public)
values ('site', 'site', true)
on conflict (id) do nothing;

drop policy if exists "imagens do site sao publicas" on storage.objects;
create policy "imagens do site sao publicas"
  on storage.objects for select to anon, authenticated
  using (bucket_id in ('blog','site'));

drop policy if exists "logada envia imagem do site" on storage.objects;
create policy "logada envia imagem do site"
  on storage.objects for insert to authenticated
  with check (bucket_id in ('blog','site'));

drop policy if exists "logada troca imagem do site" on storage.objects;
create policy "logada troca imagem do site"
  on storage.objects for update to authenticated
  using (bucket_id in ('blog','site'));

drop policy if exists "logada remove imagem do site" on storage.objects;
create policy "logada remove imagem do site"
  on storage.objects for delete to authenticated
  using (bucket_id in ('blog','site'));


-- ═══════════════════════════════════════════════════════════════
--  Pronto. Confira em Table Editor: conteudo (≈50 linhas),
--  areas (6 linhas) e faq (3 linhas).
-- ═══════════════════════════════════════════════════════════════

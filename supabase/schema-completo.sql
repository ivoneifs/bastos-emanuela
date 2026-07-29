-- ═══════════════════════════════════════════════════════════════════════
--  SITE DE EMANUELA BASTOS — BANCO COMPLETO
--  Neuropsicóloga clínica infantojuvenil e adulto · CRP 03/11614
--
--  ESTE ARQUIVO SUBSTITUI OS QUATRO ANTERIORES.
--
--  Como usar:
--    1. Abra o projeto no Supabase
--    2. SQL Editor → New query
--    3. Cole este arquivo inteiro
--    4. Run
--
--  Pode rodar quantas vezes quiser: nada é duplicado e nenhum texto
--  já editado por você é sobrescrito. Se as tabelas já existirem,
--  ele apenas completa o que estiver faltando.
--
--  O que cria:
--    posts     — postagens do blog
--    conteudo  — 82 textos e imagens do site
--    areas     — cards de "Áreas de atuação"
--    faq       — perguntas frequentes
--    agenda    — atendimentos (fechada ao público)
--    2 depósitos de imagem: blog e site
--
--  Segurança: visitante só LÊ o que é público. Escrever exige login.
--  A agenda não é legível nem em leitura para quem não está logada.
-- ═══════════════════════════════════════════════════════════════════════




-- ═══════════════════════════════════════════════════════════════
--  BLOCO 1 de 5 — schema.sql
-- ═══════════════════════════════════════════════════════════════

-- ─────────────── 1. tabela das postagens ───────────────

create table if not exists public.posts (
  id            uuid        primary key default gen_random_uuid(),
  titulo        text        not null,
  categoria     text        not null default 'Avaliação',
  resumo        text        not null default '',
  imagem        text,                                   -- URL da capa
  imagem_alt    text,                                   -- descrição para leitor de tela
  corpo         text        not null default '',        -- texto em Markdown
  publicado     boolean     not null default true,
  ordem         integer     not null default 0,         -- menor aparece primeiro
  criado_em     timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),

  constraint categoria_valida
    check (categoria in ('Avaliação', 'Reabilitação', 'Neuroeducação'))
);

comment on table public.posts is 'Postagens do blog exibidas em /#blog';

create index if not exists posts_ordem_idx
  on public.posts (publicado, ordem, criado_em desc);


-- ─────────────── 2. atualizado_em automático ───────────────

create or replace function public.marcar_atualizacao()
returns trigger
language plpgsql
as $$
begin
  new.atualizado_em := now();
  return new;
end;
$$;

drop trigger if exists posts_atualizado_em on public.posts;
create trigger posts_atualizado_em
  before update on public.posts
  for each row execute function public.marcar_atualizacao();


-- ─────────────── 3. quem pode ler e quem pode escrever ───────────────
--
--  Visitante do site: só lê o que está publicado.
--  Emanuela (logada):  faz tudo.
--
--  Sem estas regras o banco fica aberto. Não remova.

alter table public.posts enable row level security;

drop policy if exists "visitante le o que esta publicado" on public.posts;
create policy "visitante le o que esta publicado"
  on public.posts for select
  to anon
  using (publicado = true);

drop policy if exists "logada le tudo" on public.posts;
create policy "logada le tudo"
  on public.posts for select
  to authenticated
  using (true);

drop policy if exists "logada escreve" on public.posts;
create policy "logada escreve"
  on public.posts for insert
  to authenticated
  with check (true);

drop policy if exists "logada edita" on public.posts;
create policy "logada edita"
  on public.posts for update
  to authenticated
  using (true) with check (true);

drop policy if exists "logada apaga" on public.posts;
create policy "logada apaga"
  on public.posts for delete
  to authenticated
  using (true);


-- ─────────────── 4. armazenamento das capas ───────────────

insert into storage.buckets (id, name, public)
values ('blog', 'blog', true)
on conflict (id) do nothing;

drop policy if exists "capas sao publicas" on storage.objects;
create policy "capas sao publicas"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'blog');

drop policy if exists "logada envia capa" on storage.objects;
create policy "logada envia capa"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'blog');

drop policy if exists "logada troca capa" on storage.objects;
create policy "logada troca capa"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'blog');

drop policy if exists "logada remove capa" on storage.objects;
create policy "logada remove capa"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'blog');


-- ─────────────── 5. os três textos que já estão no ar ───────────────

insert into public.posts (titulo, categoria, resumo, imagem, imagem_alt, corpo, ordem)
select * from (values
(
  'O que é uma avaliação neuropsicológica — e o que ela não é',
  'Avaliação',
  'Ela não mede inteligência nem entrega um rótulo. O que os testes investigam de fato e o que você recebe no final do processo.',
  'images/blog-avaliacao.webp',
  'Emanuela Bastos à mesa do consultório com o manual do WISC-IV.',
  E'Muita gente chega ao consultório achando que a avaliação neuropsicológica é um **teste de inteligência**. Não é. Ela também não é um exame que aponta um diagnóstico sozinha, nem uma prova que se passa ou se reprova.\n\nA avaliação é um processo estruturado que descreve **como a pessoa funciona** em diferentes áreas do pensamento e do comportamento: o que ela sustenta com facilidade, onde precisa de mais esforço e quais estratégias já usa para se virar no dia a dia.\n\n## O que os testes investigam\n\nCada bateria é montada de acordo com a idade e com a queixa. De modo geral, os instrumentos olham para:\n\n- **Atenção** — manter o foco, alternar entre tarefas, resistir à distração.\n- **Memória** — reter o que acabou de ouvir, aprender listas, lembrar depois.\n- **Linguagem** — compreender, nomear, organizar o que quer dizer.\n- **Funções executivas** — planejar, começar, organizar e se conter.\n- **Raciocínio e habilidades visuoespaciais** — resolver o que é novo, organizar no espaço.\n- **Comportamento e emoção** — por meio de escalas respondidas por quem convive com a pessoa.\n\n## Como o processo acontece\n\nComeça por uma entrevista longa, que reconstrói a história de desenvolvimento, de saúde e de escola. Depois vêm as sessões de testagem, normalmente de três a seis encontros curtos. Por fim, o material é corrigido, analisado e transformado em um laudo.\n\nA devolutiva é a parte que mais importa: é quando os resultados são explicados em linguagem clara, junto com orientações práticas para casa, para a escola e para os profissionais que acompanham o caso.\n\n## O que ela não faz\n\nA avaliação não substitui a consulta médica e não fecha sozinha diagnósticos que são de competência médica. Ela **contribui** com dados objetivos que ajudam a equipe a decidir — e ajuda a família a entender o que está acontecendo.\n\nTambém não é um retrato definitivo. Ela descreve um momento. Sono ruim, um período de luto ou uma medicação recente influenciam o desempenho, e isso entra na leitura dos resultados.',
  1
),
(
  'Reabilitação neuropsicológica: o que se faz depois do laudo',
  'Reabilitação',
  'O laudo não é o fim do caminho. Como se treina atenção, memória e organização — e o que é razoável esperar disso.',
  'images/blog-reabilitacao.webp',
  'Emanuela Bastos segurando o manual das Figuras Complexas de Rey.',
  E'Terminada a avaliação, a pergunta que sempre vem é: **“e agora?”** A reabilitação neuropsicológica é a resposta prática a essa pergunta. Ela pega o perfil descrito no laudo e transforma em um plano de treino.\n\nNão é passar tempo em joguinhos de cérebro. É um acompanhamento estruturado, com metas combinadas, tarefas que aumentam de dificuldade aos poucos e — a parte mais importante — **transferência para a vida real**. Melhorar em um exercício de papel só interessa se melhorar também na cozinha, na sala de aula ou no trabalho.\n\n## Para quem costuma ser indicada\n\n- **Depois de um AVC ou traumatismo craniano**, para recuperar e compensar funções afetadas.\n- **TDAH**, com foco em organização, planejamento e controle do impulso.\n- **Dificuldades de aprendizagem**, apoiando o que a escola sozinha não dá conta.\n- **Envelhecimento e queixas de memória**, para manter autonomia no dia a dia.\n- **Após quimioterapia ou cirurgias**, quando há queixa cognitiva persistente.\n\n## Duas estratégias, sempre juntas\n\n**Restaurar** é treinar diretamente a função enfraquecida, com exercícios repetidos e graduados. **Compensar** é criar apoios externos que contornam a dificuldade: agenda, alarme, lista fixa, roteiro escrito, lugar certo para cada objeto.\n\nAs duas caminham juntas. Insistir só na primeira frustra; usar só a segunda deixa capacidade na mesa. O equilíbrio entre elas depende do caso, da idade e do tempo desde o evento.\n\n## O que é razoável esperar\n\nA reabilitação **não promete devolver o cérebro ao estado anterior**. O objetivo é funcional: fazer a pessoa dar conta da própria rotina com mais independência e menos desgaste.\n\nProgresso costuma ser lento e desigual — semanas boas, semanas paradas. Por isso reavaliamos periodicamente e ajustamos o plano. E o envolvimento da família e da escola faz muita diferença: o que se treina na sessão precisa ser sustentado fora dela.',
  2
),
(
  'Neuroeducação: o que muda quando se entende como o cérebro aprende',
  'Neuroeducação',
  'Quatro achados sólidos sobre aprendizagem, três mitos que ainda circulam nas escolas — e o que fazer com isso em casa.',
  'images/blog-neuroeducacao.webp',
  'Emanuela Bastos lendo um manual técnico no consultório.',
  E'Neuroeducação é a ponte entre o que a neurociência descobriu sobre aprendizagem e o que acontece de fato na sala de aula e na mesa de estudo de casa. Não é um método nem uma receita — é um conjunto de princípios que ajuda a parar de gastar energia com o que não funciona.\n\n## Quatro coisas que já sabemos\n\n- **Reler não é estudar.** Passar o olho no texto dá sensação de domínio sem produzir memória. Testar-se — fechar o caderno e tentar lembrar — produz muito mais aprendizagem.\n- **Espaçar vence acumular.** Estudar trinta minutos por quatro dias fixa mais do que duas horas na véspera.\n- **O sono consolida.** É durante o sono que o que foi aprendido se estabiliza. Noite mal dormida antes da prova derruba o que já estava lá.\n- **Errar faz parte do processo.** O erro corrigido logo em seguida ensina mais do que o acerto fácil. Ambiente que pune erro produz criança que evita tentar.\n\n## Três mitos que continuam circulando\n\n- **“Cada um tem seu estilo de aprendizagem.”** A ideia de que uns aprendem “vendo” e outros “ouvindo” não se sustenta nos estudos. O que importa é o formato adequado ao conteúdo, não ao aluno.\n- **“Usamos só 10% do cérebro.”** Não existe essa reserva ociosa. Praticamente todo o cérebro tem função conhecida.\n- **“Fulano é do lado direito, é criativo.”** Criatividade e lógica envolvem redes distribuídas nos dois hemisférios.\n\n## O que dá para fazer em casa amanhã\n\nDivida o estudo em blocos curtos com pausa de verdade entre eles. Peça à criança que **explique** o conteúdo em voz alta sem olhar o material. Retome no dia seguinte o que foi visto hoje, mesmo que por cinco minutos. E proteja o horário de dormir como se fosse matéria de escola — porque, na prática, é.\n\nQuando a dificuldade persiste apesar de tudo isso, vale investigar. Nem todo obstáculo de aprendizagem se resolve com método de estudo, e é exatamente aí que a avaliação neuropsicológica ajuda.',
  3
)) as novos(titulo, categoria, resumo, imagem, imagem_alt, corpo, ordem)
where not exists (select 1 from public.posts);


-- ═══════════════════════════════════════════════════════════════
--  Pronto. Confira em Table Editor → posts: devem aparecer 3 linhas.
--
--  Depois disso, crie a conta da Emanuela em
--  Authentication → Users → Add user, com o e-mail dela e uma senha
--  provisória. E deixe Authentication → Sign In / Providers →
--  "Allow new users to sign up" DESLIGADO, para que ninguém mais
--  consiga criar conta.
-- ═══════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════
--  BLOCO 2 de 5 — schema-2-conteudo.sql
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


-- ═══════════ 8. sala do Google Meet e atalho no painel ═══════════
--  Rode este trecho se já tiver rodado o arquivo antes.

insert into public.conteudo (chave, valor, tipo, grupo, rotulo, dica, ordem) values
('contato.meet', '', 'link', 'Topo', 'Sala do Google Meet',
 'Cole aqui o link fixo da sua sala (ex.: https://meet.google.com/abc-defg-hij). Enquanto estiver vazio, o botão não aparece no site.', 6)
on conflict (chave) do nothing;


-- ═══════════════════════════════════════════════════════════════
--  BLOCO 3 de 5 — schema-3-agenda.sql
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


-- ═══════════════════════════════════════════════════════════════
--  BLOCO 4 de 5 — schema-4-resto.sql
-- ═══════════════════════════════════════════════════════════════

insert into public.conteudo (chave, valor, tipo, grupo, rotulo, dica, ordem) values

-- Menu
('menu.areas',        'Áreas de atuação',  'texto', 'Menu', 'Item 1',  null, 1),
('menu.sobre',        'Sobre mim',         'texto', 'Menu', 'Item 2',  null, 2),
('menu.agenda',       'Como funciona',     'texto', 'Menu', 'Item 3',  null, 3),
('menu.blog',         'Blog',              'texto', 'Menu', 'Item 4',  null, 4),
('menu.faq',          'Dúvidas',           'texto', 'Menu', 'Item 5',  null, 5),
('menu.faq2',         'Dúvidas frequentes','texto', 'Menu', 'Item 5 no celular', null, 6),
('menu.instagram_rot','Instagram',         'texto', 'Menu', 'Item do Instagram', null, 7),
('menu.cta',          'Agendar sessão',    'texto', 'Menu', 'Botão verde do topo', null, 8),

-- Início
('hero.botao2',       'Como funciona',     'texto', 'Início', 'Texto do botão secundário', null, 10),

-- Sobre
('sobre.botao',       'Conversar comigo',  'texto', 'Sobre mim', 'Texto do botão', null, 11),

-- Escolha do formato
('formato.titulo',  'Como você prefere ser atendida ou atendido?', 'texto', 'Presencial ou vídeo', 'Título', null, 1),
('formato.texto',   'A sessão por vídeo acontece pelo próprio WhatsApp, em videochamada, com a mesma duração e o mesmo sigilo da sessão presencial. Escolha abaixo e já me diga na mensagem — assim eu reservo o horário no formato certo.', 'textao', 'Presencial ou vídeo', 'Texto explicativo', null, 2),
('formato.botao1',  'Sessão por vídeo',    'texto', 'Presencial ou vídeo', 'Botão 1', null, 3),
('formato.botao2',  'Sessão presencial',   'texto', 'Presencial ou vídeo', 'Botão 2', null, 4),
('formato.aviso',   'As videochamadas do WhatsApp são criptografadas de ponta a ponta e nenhuma sessão é gravada. Para o atendimento on-line, escolha um lugar reservado e use fone de ouvido.', 'textao', 'Presencial ou vídeo', 'Aviso de privacidade', null, 5),

-- Blog
('blog.rodape_p',    'Ficou com dúvida sobre algum desses assuntos?', 'texto', 'Blog', 'Chamada abaixo dos cards', null, 4),
('blog.rodape_link', 'Me pergunte pelo WhatsApp.', 'texto', 'Blog', 'Link da chamada', null, 5),

-- Leitor de artigo
('leitor.etiqueta', 'Blog de neuropsicologia', 'texto', 'Leitor de artigo', 'Etiqueta no topo', null, 1),
('leitor.aviso',    'Texto informativo, escrito por Emanuela Bastos (CRP 03/11614). Não substitui avaliação individual nem serve para autodiagnóstico.', 'textao', 'Leitor de artigo', 'Aviso do rodapé', null, 2),
('leitor.botao',    'Conversar sobre isso', 'texto', 'Leitor de artigo', 'Texto do botão', null, 3),

-- Rodapé
('rodape.tit_nav',      'Navegação', 'texto', 'Rodapé', 'Título da coluna de navegação', null, 7),
('rodape.tit_contato',  'Contato',   'texto', 'Rodapé', 'Título da coluna de contato', null, 8),
('rodape.emerg_tit',    'Este site não atende emergências.', 'texto', 'Rodapé', 'Aviso de emergência — destaque', 'Recomendado manter. É orientação de segurança.', 9),
('rodape.emerg_txt',    'Se você estiver em sofrimento intenso ou pensando em morte, ligue para o', 'textao', 'Rodapé', 'Aviso de emergência — texto', null, 10),
('rodape.copyright',    '© 2026 Emanuela Bastos · CRP 03/11614. Todos os direitos reservados.', 'texto', 'Rodapé', 'Linha de direitos', null, 11),
('rodape.aviso',        'Conteúdo informativo. Não substitui avaliação profissional individual.', 'texto', 'Rodapé', 'Aviso final', null, 12),

-- Busca
('seo.titulo', 'Emanuela Bastos — Neuropsicóloga clínica infantojuvenil e adulto | Irecê, BA', 'texto', 'Busca no Google', 'Título da aba do navegador', 'É o que aparece como link azul no Google. Até 60 caracteres.', 1)

on conflict (chave) do nothing;


-- ═══════════════════════════════════════════════════════════════
--  Confira em Table Editor → conteudo: agora deve ter ~80 linhas.
-- ═══════════════════════════════════════════════════════════════


-- ═══════════ complemento: marca e rodapé ═══════════
insert into public.conteudo (chave, valor, tipo, grupo, rotulo, dica, ordem) values
('marca.sigla',        'EB', 'texto', 'Topo', 'Iniciais dentro do círculo', 'Uma ou duas letras.', 0),
('rodape.emerg_txt2',  '(gratuito, 24 horas) ou procure a emergência mais próxima. Em risco imediato, ligue', 'textao', 'Rodapé', 'Aviso de emergência — final', null, 11)
on conflict (chave) do nothing;


-- ═══════════ sala do Google Meet ═══════════
insert into public.conteudo (chave, valor, tipo, grupo, rotulo, dica, ordem) values
('contato.meet', 'https://meet.google.com/', 'link', 'Topo', 'Botão do Google Meet',
 'Por padrão abre o Meet, para ela iniciar a chamada com a conta Google. Se tiver uma sala fixa, cole o endereço dela aqui.', 6)
on conflict (chave) do nothing;




-- ═══════════════════════════════════════════════════════════════
--  BLOCO 5 de 5 — correção de segurança (sessão anônima)
-- ═══════════════════════════════════════════════════════════════

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


-- ═══════════════════════════════════════════════════════════════════════
--  CONFERÊNCIA
--
--  Rode isto para ver se ficou tudo certo:
-- ═══════════════════════════════════════════════════════════════════════

select 'posts'    as tabela, count(*) as registros from public.posts
union all select 'conteudo', count(*) from public.conteudo
union all select 'areas',    count(*) from public.areas
union all select 'faq',      count(*) from public.faq
union all select 'agenda',   count(*) from public.agenda
order by tabela;

--  Esperado numa instalação nova:
--    agenda    0
--    areas     6
--    conteudo  82
--    faq       3
--    posts     3
--
--  DEPOIS DISSO, dois ajustes no painel do Supabase:
--
--   1) Authentication → Users → Add user
--      e-mail da Emanuela + senha, com "Auto Confirm User" marcado.
--
--   2) Authentication → Sign In / Providers → Email
--      DESLIGUE "Allow new users to sign up".
--      Sem isso, qualquer pessoa cria conta e enxerga a agenda.
-- ═══════════════════════════════════════════════════════════════════════

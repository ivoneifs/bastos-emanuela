-- ═══════════════════════════════════════════════════════════════
--  Blog de Emanuela Bastos — estrutura no Supabase
--
--  Como usar: abra o projeto no Supabase, vá em SQL Editor,
--  cole este arquivo inteiro e clique em Run. Pode rodar mais de
--  uma vez sem quebrar nada.
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

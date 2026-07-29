-- ═══════════════════════════════════════════════════════════════
--  Parte 4 — o que ainda faltava ficar editável
--
--  Rode no SQL Editor depois da parte 2.
--  Pode rodar mais de uma vez sem duplicar nada.
--
--  Depois desta parte, TODO texto visível do site sai do banco:
--  menu, botões, avisos do rodapé, leitor de artigo e até o
--  título que aparece na aba do navegador.
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

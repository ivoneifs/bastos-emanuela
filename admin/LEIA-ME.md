# Painel do blog — como ligar

O painel fica em `seusite.com/admin/`. Não existe link para ele em lugar nenhum do
site: quem não souber o endereço não chega lá. Ele também está bloqueado para
buscadores (`robots.txt` e `netlify.toml`).

As postagens ficam no arquivo `content/posts.json`. Cada vez que a Emanuela salva
uma alteração no painel, o Decap grava esse arquivo no repositório do GitHub e o
Netlify republica o site sozinho.

## Passo a passo (feito uma vez só, por você)

1. **Ligue o site ao repositório** `ivoneifs/bastos-emanuela` em
   Site configuration → Build & deploy → Link repository.

2. No painel do Netlify, abra **Site configuration → Identity** e clique em
   **Enable Identity**.

3. Ainda em Identity, vá em **Registration** e escolha **Invite only**.
   Isso é o que garante que só a Emanuela posta — ninguém consegue criar conta
   sozinho, nem tendo o endereço do painel.

4. Em **Identity → Services → Git Gateway**, clique em **Enable Git Gateway**.
   É isso que dá ao painel permissão de gravar no repositório.

5. Em **Identity → Invite users**, convide **emanuela.basttos@gmail.com**.
   Ela recebe um e-mail, clica no link, define a própria senha e cai direto no
   painel. Ninguém além dela precisa ser convidado.

## Como ela usa, no dia a dia

1. Abre `seusite.com/admin/` e entra com o e-mail e a senha dela.
2. Clica em **Blog → Postagens**.
3. Para escrever: **Add Postagem**. Para corrigir: clica na postagem da lista.
   Para apagar: o menu de três pontos ao lado do item.
4. Arrasta os itens para mudar a ordem em que aparecem na página.
5. **Publish** grava a alteração. O site atualiza em cerca de um minuto.

### Campos de cada postagem

| Campo | O que é |
|---|---|
| Título | Aparece no card e no topo do artigo |
| Categoria | Avaliação, Reabilitação ou Neuroeducação — vira o selo sobre a foto |
| Resumo | Duas ou três linhas, é o que se lê no card |
| Imagem de capa | Foto deitada, ideal 800 × 500 pixels |
| Descrição da imagem | Texto para leitor de tela |
| Texto do artigo | O conteúdo. `##` faz subtítulo, `-` faz lista, `**palavra**` deixa em negrito |

## Se o painel não abrir

- **Fica na tela "Carregando o editor"** → o Identity ainda não foi ativado (passo 2).
- **Entra mas dá erro ao salvar** → o Git Gateway não foi ativado (passo 4).
- **O convite não chegou** → confira a caixa de spam; dá para reenviar em
  Identity → Users.

## Detalhe importante

O site continua funcionando mesmo que o `content/posts.json` suma ou dê erro: os
três artigos originais estão escritos direto no `index.html` e aparecem como
reserva. O blog nunca fica vazio.

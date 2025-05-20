# Backlog do Produto

É importante ressaltar que todas as histórias de usuário apresentadas a seguir foram elaboradas com base na lista de requisitos funcionais descritos anteriormente neste documento. Trata-se de uma lista inicial, sujeita a ajustes ao longo do desenvolvimento do produto.

## Backlog Geral

### Processamento de Gabaritos

US01 - Como usuário, quero processar imagens de gabaritos preenchidos por alunos, para automatizar a correção das provas.

US02 - Como usuário, quero enviar o gabarito correto e comparar com as respostas dos alunos, para obter os resultados automaticamente.

US03 - Como usuário, quero validar o processamento dos gabaritos, para garantir a precisão da correção.

US04 - Como usuário, quero identificar automaticamente a matrícula do aluno no gabarito, para associar corretamente as respostas ao aluno.

### Geração de Relatórios

US05 - Como usuário, quero gerar e exportar relatórios individuais dos alunos, para acompanhar o desempenho individual.

US06 - Como usuário, quero comparar desempenho entre alunos e grupos, para identificar padrões e tendências.

US07 - Como usuário, quero visualizar estatísticas detalhadas por questão, para identificar pontos de melhoria no ensino.

US08 - Como usuário, quero acompanhar a evolução do desempenho ao longo do tempo, para avaliar o progresso dos alunos.

US09 - Como usuário, quero salvar os relatórios gerados na minha conta, para acessá-los posteriormente.

US10 - Como usuário, quero exportar relatórios gerais em PDF, para compartilhar com outros stakeholders.

### Gestão de Usuários e Pagamentos

US11 - Como usuário, quero fazer login com minha conta Google e gerenciar meu perfil, para acessar o sistema de forma segura.

US12 - Como usuário, quero gerenciar meus créditos para usar o sistema, para controlar meus gastos.

US13 - Como administrador, quero gerenciar diferentes níveis de acesso, para controlar quem pode acessar quais funcionalidades.

US14 - Como usuário, quero associar minha escola à minha conta, para organizar melhor os dados e relatórios.

US15 - Como usuário, quero realizar pagamentos via Stripe, para adquirir créditos no sistema.

US16 - Como usuário, quero visualizar meu saldo de créditos atual, para controlar meu uso do sistema.

### Templates de Gabaritos

US17 - Como usuário, quero criar e personalizar templates de gabaritos, para adaptar o sistema às minhas necessidades.

US18 - Como usuário, quero gerenciar meus templates de gabaritos, para reutilizá-los e mantê-los atualizados.

US19 - Como usuário, quero personalizar o layout dos gabaritos, para adaptá-los às necessidades específicas da minha instituição.

US20 - Como usuário, quero definir o número de questões e campos no template, para criar gabaritos com diferentes formatos.

### Integração e Exportação

US21 - Como usuário, quero exportar dados em diferentes formatos, para integrar com outros sistemas.

US22 - Como usuário, quero fazer backup dos meus dados, para garantir a segurança das informações.

## Priorização do Backlog Geral

A priorização foi realizada utilizando a técnica MoSCoW, que organiza as funcionalidades em quatro categorias:

- Must have: Funcionalidades essenciais para o funcionamento do produto
- Should have: Funcionalidades importantes, porém que podem ser implementadas após as essenciais
- Could have: Funcionalidades desejáveis, que agregam valor, mas não são prioritárias
- Won't have: Funcionalidades que não serão implementadas inicialmente

| ID   | Descrição                      | Prioridade  |
| ---- | ------------------------------ | ----------- |
| US01 | Processar Imagens de Gabaritos | Must have   |
| US02 | Correção Automática            | Must have   |
| US03 | Validação de Processamento     | Must have   |
| US04 | Identificação de Matrícula     | Must have   |
| US05 | Relatórios Individuais         | Must have   |
| US11 | Autenticação e Perfil          | Must have   |
| US14 | Associação Escola/Conta        | Must have   |
| US17 | Criação de Templates           | Must have   |
| US18 | Gerenciamento de Templates     | Must have   |
| US20 | Definição de Campos            | Must have   |
| US06 | Análise Comparativa            | Should have |
| US12 | Sistema de Créditos            | Should have |
| US15 | Pagamentos Stripe              | Should have |
| US16 | Visualização de Créditos       | Should have |
| US09 | Salvamento de Relatórios       | Should have |
| US19 | Personalização de Layout       | Should have |
| US21 | Exportação de Dados            | Should have |
| US22 | Backup de Dados                | Should have |
| US07 | Estatísticas por Questão       | Could have  |
| US08 | Histórico de Desempenho        | Could have  |
| US10 | Exportação PDF Geral           | Could have  |
| US13 | Gestão de Acesso               | Could have  |

## MVP

O Produto Mínimo Viável (MVP) inclui as seguintes funcionalidades essenciais:

### Funcionalidades
- Processar Imagens de Gabaritos (US01)
- Correção Automática (US02)
- Validação de Processamento (US03)
- Identificação de Matrícula (US04)
- Relatórios Individuais (US05)
- Autenticação e Perfil (US11)
- Associação Escola/Conta (US14)
- Criação de Templates (US17)
- Gerenciamento de Templates (US18)
- Definição de Campos (US20)

### Requisitos Não Funcionais
- Frontend: Flutter (Desktop)
- Backend: TypeScript/Express.js
- Processamento de Imagens: Python/OpenCV
- Banco de Dados: Supabase/PostgreSQL
- Hospedagem: Azure VM Linux
- Processamento mínimo de 100 gabaritos por minuto
- Interface intuitiva e fácil de usar
- Segurança e confidencialidade dos dados
- Custo operacional inferior a R$ 1,00 por aluno processado

As funcionalidades não incluídas no MVP serão implementadas em fases subsequentes, priorizando aquelas classificadas como "Should have" antes das "Could have". 
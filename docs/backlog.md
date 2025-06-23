# Backlog do Produto

É importante ressaltar que todas as histórias de usuário apresentadas a seguir foram elaboradas com base na lista de requisitos funcionais descritos anteriormente neste documento. Trata-se de uma lista inicial, sujeita a ajustes ao longo do desenvolvimento do produto.

## Backlog Geral

### Épicos

1. **Processamento de Gabaritos (EP01)**
   - Foco no processamento e correção automática de gabaritos
   - Inclui identificação de respostas, validação e templates

2. **Geração de Relatórios (EP02)**
   - Foco na análise e geração de relatórios de desempenho
   - Inclui relatórios individuais, comparativos e estatísticas

3. **Gestão de Usuários e Pagamentos (EP03)**
   - Foco na gestão de contas, autenticação e sistema de créditos
   - Inclui integração com Stripe e controle de acesso

4. **Templates de Gabaritos (EP04)**
   - Foco na personalização e gestão de templates
   - Inclui criação, edição e definição de campos

5. **Integração e Exportação (EP05)**
   - Foco na exportação de dados e integração com outros sistemas
   - Inclui backup e diferentes formatos de exportação

### Processamento de Gabaritos (EP01)

US01 - Como usuário, quero processar imagens de gabaritos preenchidos por alunos, para automatizar a correção das provas.

US02 - Como usuário, quero enviar o gabarito correto e comparar com as respostas dos alunos, para obter os resultados automaticamente.

US03 - Como usuário, quero validar o processamento dos gabaritos, para garantir a precisão da correção.

US04 - Como usuário, quero identificar automaticamente a matrícula do aluno no gabarito, para associar corretamente as respostas ao aluno.

### Geração de Relatórios (EP02)

US05 - Como usuário, quero gerar e exportar relatórios individuais dos alunos, para acompanhar o desempenho individual.

US06 - Como usuário, quero comparar desempenho entre alunos e grupos, para identificar padrões e tendências.

US07 - Como usuário, quero visualizar estatísticas detalhadas por questão, para identificar pontos de melhoria no ensino.

US08 - Como usuário, quero acompanhar a evolução do desempenho ao longo do tempo, para avaliar o progresso dos alunos.

US09 - Como usuário, quero salvar os relatórios gerados na minha conta, para acessá-los posteriormente.

US10 - Como usuário, quero exportar relatórios gerais em PDF, para compartilhar com outros stakeholders.

### Gestão de Usuários e Pagamentos (EP03)

US11 - Como usuário, quero fazer login com minha conta Google e gerenciar meu perfil, para acessar o sistema de forma segura.

US12 - Como usuário, quero gerenciar meus créditos para usar o sistema, para controlar meus gastos.

US13 - Como administrador, quero gerenciar diferentes níveis de acesso, para controlar quem pode acessar quais funcionalidades.

US14 - Como usuário, quero associar minha escola à minha conta, para organizar melhor os dados e relatórios.

US15 - Como usuário, quero realizar pagamentos via Stripe, para adquirir créditos no sistema.

US16 - Como usuário, quero visualizar meu saldo de créditos atual, para controlar meu uso do sistema.

### Templates de Gabaritos (EP04)

US17 - Como usuário, quero criar e personalizar templates de gabaritos, para adaptar o sistema às minhas necessidades.

US18 - Como usuário, quero gerenciar meus templates de gabaritos, para reutilizá-los e mantê-los atualizados.

US19 - Como usuário, quero personalizar o layout dos gabaritos, para adaptá-los às necessidades específicas da minha instituição.

US20 - Como usuário, quero definir o número de questões e campos no template, para criar gabaritos com diferentes formatos.

### Integração e Exportação (EP05)

US21 - Como usuário, quero exportar dados em diferentes formatos, para integrar com outros sistemas.

US22 - Como usuário, quero fazer backup dos meus dados, para garantir a segurança das informações.

## Priorização do Backlog Geral

A priorização foi realizada utilizando as técnicas **Weighted Shortest Job First (WSJF)** em conjunto com o método MoSCoW, de modo a definir quais tarefas realizar primeiro dentre as definidas como essenciais no MVP.

A priorização MoSCoW organiza as funcionalidades em quatro categorias:

- Must have: Funcionalidades essenciais para o funcionamento do produto
- Should have: Funcionalidades importantes, porém que podem ser implementadas após as essenciais
- Could have: Funcionalidades desejáveis, que agregam valor, mas não são prioritárias
- Won't have: Funcionalidades que não serão implementadas inicialmente

O objetivo do WSJF é maximizar o valor econômico entregue em um período de tempo. A premissa é simples: se tivermos duas tarefas de valor igual, devemos fazer a mais curta primeiro para obter o retorno do investimento mais cedo.

A fórmula para calcular o WSJF é dada por:

$$
WSJF = \frac{\text{Custo do Atraso (Cost of Delay)}}{\text{Tamanho do Trabalho (Job Size)}}
$$

Detalhando os componentes presentes na fórmula, temos:

1. Custo do Atraso (Cost of Delay):
    - Representa o dinheiro ou valor perdido, semana após semana que não é entregue uma funcionalidade.
    - É definido pela soma de 3 fatores:
        - Valor para o Usuário e Negócio
        - Criticidade do Tempo
        - Redução de Risco ou Habilitação de Oportunidade
2. Tamanho do Trabalho (Job Size)
    - Esse componente representa o esforço necessário para implementar uma funcionalidade, sendo definido pelas horas estimadas.

Para a aplicação no projeto, será considerada a escala de Fibonacci para o sistema de pontuação na fórmula, uma prática padrão na metodologia SAFe.

Para cada cada História de Usuário (US) serão pontuados “Valor”, “Criticidade” e “RR|OE”, e no final a soma dos 3 irá compor o “CoD” (Cost of Delay).

As horas estimadas podem ser mapeadas para a sequência de Fibonacci da seguinte forma:

- 1-4 horas → **3**
- 5-8 horas → **5**
- 9-12 horas → **8**
- 13-16 horas → **13**
- 20 horas+ → **20**

Por fim, dividiremos o CoD pelo Tamanho para obter a pontuação WSJF e ranquear as funcionalidades.

Legenda para a tabela:

- U-BV: Valor de Negócio do Usuário (User-Business Value)
- TC: Criticidade Temporal (Time Criticality)
- RR|OE: Redução de Risco | Habilitação de Oportunidade (Risk Reduction | Opportunity Enablement)
- CoD: Custo do Atraso (Cost of Delay)
- JS: Tamanho do Trabalho (Job Size)

| ID   | Prioridade MoSCoW   | Descrição                                       |   U-BV |   TC |   RR|OE |   CoD |   JS |   Pontuação WSJF |   Rank WSJF | Horas estimadas   | Requisito Relacionado   | Épico   |
|:-----|:--------------------|:------------------------------------------------|-------:|-----:|--------:|------:|-----:|-----------------:|------------:|:------------------|:------------------------|:--------|
| US02 | Must have           | Enviar gabarito correto e comparar              |     20 |   20 |      13 |    53 |    5 |            10.6  |           1 | 8h                | RF02, RF04, RF05        | EP01    |
| US11 | Must have           | Fazer login com conta Google e gerenciar perfil |      8 |   13 |       8 |    29 |    3 |             9.67 |           2 | 4h                | RF16                    | EP03    |
| US14 | Must have           | Associar escola à conta                         |      8 |   13 |       5 |    26 |    3 |             8.67 |           3 | 2h                | RF17                    | EP03    |
| US05 | Must have           | Gerar relatórios individuais dos alunos         |     20 |   13 |       8 |    41 |    5 |             8.2  |           4 | 8h                | RF10                    | EP02    |
| US03 | Must have           | Validar processamento dos gabaritos             |      5 |    8 |       8 |    21 |    3 |             7    |           5 | 4h                | RF02                    | EP01    |
| US04 | Must have           | Identificar matrícula do aluno no gabarito      |     13 |   20 |      13 |    46 |    8 |             5.75 |           6 | 10h               | RF03                    | EP01    |
| US20 | Must have           | Definir número de questões e campos             |      5 |    5 |       3 |    13 |    3 |             4.33 |           7 | 4h                | RF13                    | EP04    |
| US12 | Should have         | Gerenciar sistema de créditos                   |      8 |    5 |       5 |    18 |    5 |             3.6  |           8 | 6h                | RF20                    | EP03    |
| US21 | Should have         | Exportar dados em diferentes formatos           |      5 |    2 |       3 |    10 |    3 |             3.33 |           9 | 4h                | RF14                    | EP05    |
| US06 | Should have         | Comparar desempenho entre alunos e grupos       |     13 |    5 |       8 |    26 |    8 |             3.25 |          10 | 12h               | RF07, RF08              | EP02    |
| US17 | Must have           | Criar e personalizar templates de gabaritos     |     13 |    8 |       5 |    26 |    8 |             3.25 |          11 | 12h               | RF12                    | EP04    |
| US01 | Must have           | Processar Imagens de Gabaritos                  |     20 |   20 |      20 |    60 |   20 |             3    |          12 | 40h               | RF01                    | EP01    |
| US10 | Could have          | Exportar relatórios gerais em PDF               |      5 |    2 |       2 |     9 |    3 |             3    |          13 | 4h                | RF15                    | EP02    |
| US22 | Should have         | Fazer backup dos dados                          |      5 |    2 |       8 |    15 |    5 |             3    |          14 | 8h                | RF14                    | EP05    |
| US18 | Must have           | Gerenciar templates de gabaritos                |      5 |    5 |       3 |    13 |    5 |             2.6  |          15 | 6h                | RF12, RF13              | EP04    |
| US15 | Should have         | Realizar pagamentos via Stripe                  |      8 |    3 |       5 |    16 |    8 |             2    |          16 | 10h               | RF18                    | EP03    |
| US08 | Could have          | Acompanhar evolução do desempenho               |      8 |    2 |       5 |    15 |    8 |             1.88 |          17 | 12h               | RF06                    | EP02    |
| US19 | Should have         | Personalizar layout dos gabaritos               |      8 |    2 |       3 |    13 |    8 |             1.63 |          18 | 12h               | RF13                    | EP04    |
| US07 | Could have          | Visualizar estatísticas por questão             |      8 |    3 |       5 |    16 |   13 |             1.23 |          19 | 16h               | RF06                    | EP02    |
| US13 | Could have          | Gerenciar diferentes níveis de acesso           |      3 |    1 |       3 |     7 |    8 |             0.88 |          20 | 12h               | RF16                    | EP03    |

Com o rankeamento realizado é possível selecionar as funcionalidades com maior valor de negócio para serem implementadas primeiro no MVP.

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

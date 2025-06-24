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

<table style="width:100%; border-collapse: collapse;">
  <thead>
    <tr>
      <th style="text-align: left; padding: 8px; border: 1px solid #ddd;">ID</th>
      <th style="text-align: left; padding: 8px; border: 1px solid #ddd;">Prioridade MoSCoW</th>
      <th style="text-align: left; padding: 8px; border: 1px solid #ddd;">Descrição</th>
      <th style="text-align: right; padding: 8px; border: 1px solid #ddd;">U-BV</th>
      <th style="text-align: right; padding: 8px; border: 1px solid #ddd;">TC</th>
      <th style="text-align: right; padding: 8px; border: 1px solid #ddd;">RR|OE</th>
      <th style="text-align: right; padding: 8px; border: 1px solid #ddd;">CoD</th>
      <th style="text-align: right; padding: 8px; border: 1px solid #ddd;">JS</th>
      <th style="text-align: right; padding: 8px; border: 1px solid #ddd;">Pontuação WSJF</th>
      <th style="text-align: right; padding: 8px; border: 1px solid #ddd;">Rank WSJF</th>
      <th style="text-align: left; padding: 8px; border: 1px solid #ddd;">Horas estimadas</th>
      <th style="text-align: left; padding: 8px; border: 1px solid #ddd;">Requisito Relacionado</th>
      <th style="text-align: left; padding: 8px; border: 1px solid #ddd;">Épico</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US02</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Must have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Enviar gabarito correto e comparar</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">20</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">20</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">53</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">10.6</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">1</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">8h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF02, RF04, RF05</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP01</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US11</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Must have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Fazer login com conta Google e gerenciar perfil</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">29</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">9.67</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">2</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">4h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF16</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP03</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US14</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Must have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Associar escola à conta</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">26</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8.67</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">2h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF17</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP03</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US05</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Must have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Gerar relatórios individuais dos alunos</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">20</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">41</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8.2</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">4</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">8h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF10</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP02</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US03</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Must have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Validar processamento dos gabaritos</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">21</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">7</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">4h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF02</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP01</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US04</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Must have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Identificar matrícula do aluno no gabarito</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">20</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">46</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5.75</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">6</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">10h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF03</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP01</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US20</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Must have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Definir número de questões e campos</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">4.33</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">7</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">4h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF13</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP04</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US12</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Should have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Gerenciar sistema de créditos</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">18</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3.6</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">6h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF20</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP03</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US21</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Should have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Exportar dados em diferentes formatos</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">2</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">10</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3.33</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">9</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">4h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF14</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP05</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US06</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Should have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Comparar desempenho entre alunos e grupos</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">26</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3.25</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">10</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">12h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF07, RF08</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP02</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US17</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Must have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Criar e personalizar templates de gabaritos</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">26</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3.25</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">11</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">12h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF12</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP04</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US01</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Must have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Processar Imagens de Gabaritos</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">20</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">20</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">20</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">60</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">20</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">12</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">40h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF01</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP01</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US10</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Could have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Exportar relatórios gerais em PDF</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">2</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">2</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">9</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">4h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF15</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP02</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US22</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Should have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Fazer backup dos dados</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">2</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">15</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">14</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">8h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF14</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP05</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US18</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Must have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Gerenciar templates de gabaritos</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">2.6</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">15</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">6h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF12, RF13</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP04</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US15</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Should have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Realizar pagamentos via Stripe</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">16</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">2</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">16</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">10h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF18</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP03</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US08</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Could have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Acompanhar evolução do desempenho</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">2</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">15</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">1.88</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">17</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">12h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF06</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP02</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US19</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Should have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Personalizar layout dos gabaritos</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">2</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">1.63</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">18</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">12h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF13</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP04</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US07</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Could have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Visualizar estatísticas por questão</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">5</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">16</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">13</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">1.23</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">19</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">16h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF06</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP02</td>
    </tr>
    <tr>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">US13</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Could have</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">Gerenciar diferentes níveis de acesso</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">1</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">3</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">7</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">8</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">0.88</td>
      <td style="text-align: right; padding: 8px; border: 1px solid #ddd;">20</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">12h</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">RF16</td>
      <td style="text-align: left; padding: 8px; border: 1px solid #ddd;">EP03</td>
    </tr>
  </tbody>
</table>

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

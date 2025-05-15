# Solução Proposta

## Objetivos do Produto

O objetivo principal do produto é otimizar o processo de correção de gabaritos da Guia do PAS, reduzindo o tempo de processamento de 1 mês para menos de 24 horas, diminuindo o custo por correção de R$5,00 para menos de R$1,00, e aumentando a precisão da identificação das respostas para mais de 99%. Além disso, o sistema deve permitir a análise automática do desempenho individual e coletivo dos alunos, gerando relatórios detalhados que incluem estatísticas por questão, comparações entre turmas e identificação de padrões de erro. O produto também visa expandir a base de clientes da empresa, permitindo a oferta do serviço de correção para outras instituições de ensino, com meta de atingir pelo menos 10 novas escolas parceiras no primeiro ano de operação. Por fim, o sistema deve resolver os problemas técnicos encontrados na versão anterior, como instabilidades, necessidade de manutenção constante e limitações operacionais, oferecendo uma solução robusta e multiplataforma que não dependa de servidores dedicados.

### Objetivos Específicos

1. Realizar 100 correções de gabaritos por minuto

- Alcançar uma capacidade de processamento de, no mínimo, 100 gabaritos por minuto. Este objetivo tem como objetivo garantir agilidade na entrega dos resultados mesmo para grandes volumes de provas, como em simulados de larga escala ou para múltiplas instituições.

2. Automatizar a correção de gabaritos

- Eliminar a necessidade de intervenção manual no processo de correção de gabaritos, utilizando tecnologia de Visão Computacional (CV) para identificar as respostas dos alunos diretamente das imagens dos gabaritos preenchidos, associando-as automaticamente aos respectivos alunos (via identificação de matrícula) e comparando-as com o gabarito oficial.

3. Prover informações de desempenho dos alunos

- Gerar relatórios analíticos detalhados sobre o desempenho dos alunos, tanto individualmente (nota, acertos, erros, posição na turma, nota média da turma) quanto coletivamente (estatísticas por questão, comparação entre turmas). Essas informações devem ser acessíveis para gestores/coordenadores e, potencialmente, para os próprios alunos.

## Características da Solução

O produto será um aplicativo desktop multiplataforma (Windows, Linux e MacOS) que deve ser capaz de:
- Processar imagens de gabaritos preenchidos pelos alunos
- Identificar as respostas dadas pelos alunos em cada questão
- Identificar a matrícula do aluno
- Comparar as respostas com o gabarito correto
- Gerar relatórios detalhados com:
  - Desempenho do aluno (notas, acertos e erros)
  - Comparações entre alunos
  - Comparações entre grupos de alunos
  - Dados estatísticos de cada questão
- Gerar templates de gabaritos
- Permitir a personalização dos gabaritos
- Exportar dados e relatórios para arquivos .csv e .pdf

## Tecnologias a Serem Utilizadas

- **Frontend:** Dart + Flutter
- **Processamento de Imagem:** Python + OpenCV
- **Backend:** Typescript + Express.js
- **Banco de Dados:** Supabase (PostgreSQL)
- **Hospedagem:** Azure + VM Linux

## Pesquisa de Mercado e Análise Competitiva

### RemarkOffice
- Preço muito alto ($1,195.00)
- Não oferece personalização dos gabaritos
- Não possui precificação por gabarito analisado

### Gradepen
- Gratuito mas pouco conhecido
- Uso extremamente limitado
- Não oferece estatísticas de desempenho
- Não oferece personalização dos gabaritos

### Prova Fácil
- Custa R$0.84 por correção
- Oferece apenas provas de 20, 50 e 100 questões, sem flexibilidade
- Não oferece estatísticas de desempenho
- Não oferece personalização dos gabaritos
- Apenas questões do tipo C

## Análise de Viabilidade

### Viabilidade Técnica
- Alta viabilidade devido à experiência da equipe
- Familiaridade com as tecnologias propostas
- Prazo de 3 meses é viável

### Viabilidade Financeira
- Custo estimado: R$1.000,00 para serviços de infraestrutura
- Retorno financeiro inicial: R$1.000,00 por mês
- Estimativa baseada em 2000 correções por mês a R$0,50 por correção

### Viabilidade de Mercado
- Crescimento atual da empresa no mercado de Brasília
- Possibilidade de expansão para outras instituições
- Demanda existente por soluções de correção automática

## Impacto da Solução

- Redução do tempo de processamento de 1 mês para algumas horas
- Redução do custo por correção de R$5,00 para menos de R$1,00
- Aumento da receita em pelo menos R$12.000,00 por ano
- Expansão da atuação no mercado educacional
- Expansão para outros processos seletivos além do PAS
- Análise de 100 gabaritos por minuto
- Relatórios detalhados sobre o desempenho dos alunos

## Histórico de Versão

| Data       | Versão | Descrição                       | Autor(es)      | Revisor(es) |
| ---------- | ------ | ------------------------------- | -------------- | ----------- |
| 19/04/2025 | 1.0    | Criação inicial da documentação | Otavio Maya | Marcelo Adrian            |

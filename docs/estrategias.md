# Estratégias de Engenharia de Software

## Estratégia Priorizada 

- **Abordagem de Desenvolvimento de Software**: Ágil com elementos dirigidos por plano.

- **Ciclo de vida**: Híbrido (iterativo e incremental).

- **Processo de Engenharia de Software**: OpenUP.

O OpenUP será utilizado, pois é um processo ágil e leve, adequado para projetos de médio porte com necessidades de validação rápida e evoluções constantes.

As quatro fases do OpenUP serão seguidas:

- **Concepção**: Definição dos objetivos do projeto, levantamento dos requisitos iniciais, entendimento do problema de correção de gabaritos, escolha das tecnologias (Flutter, OpenCV, Typescript, Supabase) e planejamento inicial de prazos e custos.
  
- **Elaboração**: Refinamento dos requisitos (como detalhamento das funcionalidades de correção, exportação e geração de relatórios), desenvolvimento de protótipos iniciais de reconhecimento de gabaritos, e avaliação dos principais riscos (como o reconhecimento de imagens e integração entre as tecnologias).

- **Construção**: Desenvolvimento iterativo da aplicação desktop, integração contínua entre frontend, backend e sistemas de visão computacional, testes de funcionalidades como reconhecimento automático e geração de relatórios, além de ajustes baseados no feedback interno.

- **Transição**: Testes finais de desempenho e robustez (ex: correção de 100 gabaritos por minuto), implantação para o ambiente de produção, produção de documentação de uso para a equipe comercial e suporte inicial aos clientes externos.

O cronograma de execução do projeto será alinhado às entregas previstas em cada uma dessas fases, respeitando o prazo de 3 meses para conclusão do produto mínimo viável (MVP).

---

## Quadro Comparativo 

| **Característica**           | **Unified Process (UP)**                                                                 | **Open Unified Process (OpenUP)**                                                           |
|-----------------------------|-------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| **Objetivo**                | Metodologia robusta com forte foco em documentação e controle                            | Processo leve e ágil com foco em colaboração e entregas contínuas                          |
| **Foco no Processo**        | Estruturado e formal, com controle rigoroso                                               | Flexível e centrado na produtividade da equipe                                              |
| **Complexidade**            | Elevada, ideal para projetos críticos e de grande porte                                   | Reduzida, ideal para projetos de médio porte que exigem agilidade                          |
| **Fases**                   | Concepção, Elaboração, Construção, Transição (com ampla documentação)                     | Concepção, Elaboração, Construção, Transição (com entregas enxutas)                        |
| **Disciplinas**             | Abrange várias disciplinas como Modelagem, Design, Testes, Gerência de Projeto           | Enfoque em Requisitos, Implementação, Testes e Gerência de Projeto                         |
| **Documentação**            | Detalhada e exigida em cada fase                                                          | Essencial apenas para manter a produtividade da equipe                                     |
| **Iteratividade**           | Iterativo e incremental, com processos mais pesados                                       | Iterativo e incremental, com ciclos curtos e adaptáveis                                    |
| **Gestão de Riscos**        | Formal e concentrada na fase de Elaboração                                                | Contínua e integrada de forma leve                                                         |
| **Flexibilidade**           | Menor adaptabilidade a mudanças rápidas                                                   | Alta flexibilidade, facilitando ajustes frequentes                                         |
| **Colaboração**             | Papéis bem definidos e estrutura hierárquica                                              | Equipes multifuncionais, com papéis flexíveis e foco na colaboração                        |
| **Recomendado para**        | Projetos grandes, críticos, com alta demanda por rastreabilidade e validações formais    | Projetos médios ou pequenos, com necessidade de agilidade — como no projeto Corigge        |

---

## Justificativa 

O projeto da nova solução **Corigge** para a Guia do PAS demanda um processo ágil, adaptável e eficiente. O OpenUP se mostra a escolha ideal por:

- Permitir a adaptação rápida a mudanças no escopo, como ajustes em funcionalidades (ex: novos tipos de gabaritos ou estatísticas).
- Exigir menos documentação formal, favorecendo o foco em entregas práticas e ágeis, especialmente importante para uma equipe enxuta.
- Ser mais leve que o UP tradicional, o que reduz a carga de burocracia, otimiza o tempo e diminui o custo do desenvolvimento — aspectos cruciais para um projeto com orçamento de aproximadamente R\$ 1.000,00.
- Permitir iterações rápidas e entregas frequentes, essenciais para testar rapidamente o reconhecimento de imagens, relatórios e exportações, validando a qualidade da solução antes do lançamento comercial.
- Promover a colaboração ativa da equipe de desenvolvimento com os stakeholders (Guia do PAS e instituições parceiras), para garantir que o produto atenda às expectativas tanto para uso interno quanto para venda externa.

Em resumo, o **OpenUP** encaixa-se perfeitamente nas necessidades do projeto Corigge: é leve, iterativo, adaptável, reduz riscos e acelera o retorno sobre o investimento.

---

### 📚 Referências 

<small>SILVA, Luciane. OpenUp: um processo integrado e ágil. Disponível em: <https://medium.com/@LucianeS/openup-um-processo-integrado-e-agil-a4400c17ce62>. Acesso em: 11 nov. 2024.</small>

<small>CATOLICA. Metodologias Ágeis de Desenvolvimento: OpenUP, FDD, DSDM e Lean. Disponível em: <https://conteudo.catolica.edu.br/conteudos/unileste_cursos/disciplinas/nucleo_formacao_geral/Gestao_de_projetos_e_metodos_ageis/tema_03/index.html>. Acesso em: 11 nov. 2024.</small>

<small>EDUCATIVE.IO. What is a unified process model. Disponível em: <https://www.educative.io/answers/what-is-a-unified-process-model>. Acesso em: 11 nov. 2024.</small>

<small>EDEKI, Charles. Agile Unified Process. Disponível em: <https://interhad.nied.unicamp.br/courses/roberto-pereira/ci163-projeto-de-software-ufpr-1/agenda/auppaper.pdf>. Acesso em: 11 nov. 2024.</small>

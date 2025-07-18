# DoR e DoD

## Definition of Ready (DoR)

- Um item de backlog é considerado "Preparado" quando está definido claramente. Isso implica que a User Story está escrita no formato padrão, a descrição do item é clara, concisa e compreendida por toda a equipe, e o objetivo e o valor de negócio do item são claros.

- É fundamental que os critérios de aceitação estejam bem definidos. Eles devem ser testáveis, inequívocos e especificar com precisão como a funcionalidade será validada, abrangendo considerações sobre requisitos funcionais (RFs) e não funcionais (RNFs) relevantes para o item.

- As dependências devem ser identificadas. Quaisquer dependências, sejam outros itens de backlog, informações externas ou decisões pendentes, precisam ser mapeadas e, idealmente, resolvidas ou ter um plano de ação estabelecido para sua resolução antes do início do desenvolvimento.

- O item deve possuir uma estimativa de esforço. Após discussão pela equipe de desenvolvimento, o item deve ter recebido uma estimativa (por exemplo, em story points ou horas ideais), e a equipe deve concordar que o item é suficientemente pequeno para ser concluído dentro de uma única Sprint.

- A equipe deve ter o conhecimento técnico necessário. É preciso que a equipe possua, ou tenha planejado como adquirir, o conhecimento técnico indispensável para implementar o item, incluindo familiaridade com tecnologias como Flutter, OpenCV e Supabase.

- O item precisa estar em **alinhamento com o MVP**. Caso o item faça parte do escopo inicial, ele deve estar alinhado com a Definição do MVP do projeto, estabelecida na fase de Concepção.

- Por fim, a **priorização** do item deve estar definida. O item deve ter sido devidamente priorizado pelo Product Owner (neste contexto, o Gerente de Projeto) em relação aos demais itens presentes no backlog do projeto.

---

## Definition of Done (DoD)

- A funcionalidade deve ter sido verificada. A funcionalidade deve estar operando conforme especificado nos critérios de aceitação em um ambiente de testes ou staging, e os requisitos não funcionais relevantes (RNF01 - Multiplataforma, RNF08 - Robustez, RNF13 - Segurança) devem ter sido atendidos dentro do escopo do item.

- Um item de backlog é considerado "Feito" quando o código está implementado. Isso significa que todo o código necessário para a funcionalidade foi escrito, está em conformidade com os padrões de codificação da equipe e a implementação segue a arquitetura definida, como especificado na "Definição da Arquitetura" na fase de Elaboração (página 8).

- A integração contínua deve ter sido bem-sucedida. O código precisa ter sido integrado à branch principal ou de desenvolvimento do repositório, e o build de integração contínua, caso esteja configurado, deve estar passando sem erros.

- A documentação deve estar atualizada. Qualquer documentação técnica relevante, como comentários no código, diagramas ou documentação de API, deve ter sido criada ou atualizada.

- Considerações específicas do projeto Corigge devem ser atendidas. Para funcionalidades de processamento de imagem (RF01, RF02, RF03), a precisão da identificação deve atender aos níveis esperados (referência: >99% de precisão, Seção 2.1). Para funcionalidades de exportação (RF11, RF14, RF15), os arquivos gerados (.csv, .pdf) devem estar corretos e completos. Para funcionalidades de integração (RF18 - Stripe), a comunicação e o processamento devem estar funcionando corretamente.

---

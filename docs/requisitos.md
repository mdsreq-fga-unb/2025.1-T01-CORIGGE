## Requisitos Funcionais (RF)

| Identificador | Descrição                                                                                                                          |
| ----- | -----------------------------------------------------------------------------------------------------------------------------------------  |
| RF01   | O sistema deve poder processar imagens de gabaritos preenchidos por alunos.                                                               |
| RF02   | O sistema deve identificar automaticamente as respostas marcadas pelos alunos nas imagens dos gabaritos.                                  |
| RF03   | O sistema deve identificar automaticamente a matrícula do aluno presente na imagem do gabarito.                                           |
| RF04   | O USUÁRIO deve poder enviar (upload) um arquivo .csv contendo o gabarito correto para cada questão da prova.                              |
| RF05   | O sistema deve comparar as respostas identificadas no gabarito do aluno com o gabarito correto fornecido.                                 |
| RF06   | O sistema deve gerar relatórios detalhados de desempenho, incluindo notas individuais, acertos, erros e estatísticas por questão.         |
| RF07   | O sistema deve permitir a comparação de desempenho entre alunos individuais.                                                              |
| RF08   | O sistema deve permitir a comparação de desempenho entre grupos de alunos (ex: turmas).                                                   |
| RF09   | O sistema deve salvar os relatórios gerados na conta do USUÁRIO.                                                                          |
| RF10   | O sistema deve gerar um relatório individual por aluno, formatado para impressão.                                                         |
| RF11   | O USUÁRIO deve poder exportar o relatório individual do aluno em formato .pdf.                                                            |
| RF12   | O USUÁRIO deve poder criar templates de gabaritos.                                                                                        |
| RF13   | O USUÁRIO deve poder personalizar os templates de gabaritos (ex: layout, campos, número de questões) conforme suas necessidades.          |
| RF14   | O USUÁRIO deve poder exportar os dados de correção e os relatórios gerados em formato .csv.                                               |
| RF15   | O USUÁRIO deve poder exportar os relatórios gerados (além dos individuais já cobertos) em formato .pdf.                                   |
| RF16   | O sistema deve permitir que o USUÁRIO realize cadastro e login utilizando sua conta Google.                                               |
| RF17   | O sistema deve associar o nome do USUÁRIO e sua escola à conta cadastrada.                                                                |
| RF18   | O sistema deve integrar-se com o Stripe para processar pagamentos via Link de Pagamento.                                                  |
| RF19   | O sistema deve associar um pagamento bem-sucedido (via link Stripe) à conta do USUÁRIO correspondente, utilizando o ID do usuário na URL. |
| RF20   | O sistema deve gerenciar um sistema de créditos por USUÁRIO para utilização dos serviços da plataforma.                                   |
| RF21   | O sistema deve adicionar créditos à conta do USUÁRIO após a confirmação de um pagamento bem-sucedido via Stripe.                          |
| RF22   | O sistema deve deduzir créditos da conta do USUÁRIO conforme a utilização dos serviços (ex: processamento de gabaritos).                  |
| RF23   | O USUÁRIO deve poder visualizar seu saldo de créditos atual na plataforma.                                                                |

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Requisitos Não Funcionais (RNF)

| Identificador | Descrição                                                                                                                                 | Categoria Principal                   |
| :------------ | :-----------------------------------------------------------------------------------------------------------------------------------------| :------------------------------------ |
| RNF01         | O sistema deve funcionar como uma aplicação desktop nas plataformas Windows, Linux e MacOS.                                               | Portabilidade                         |
| RNF02         | A interface do usuário (frontend desktop) deve ser desenvolvida utilizando Flutter.                                                       | Requisitos de Implementação           |
| RNF03         | O processamento de imagens dos gabaritos deve ser implementado utilizando Python e a biblioteca OpenCV.                                   | Requisitos de Implementação           |
| RNF04         | O backend da aplicação deve ser desenvolvido utilizando Typescript e o framework Express.js.                                              | Requisitos de Implementação           |
| RNF05         | O sistema deve utilizar Supabase como plataforma de backend, com PostgreSQL como banco de dados subjacente.                               | Requisitos de Implementação           |
| RNF06         | A infraestrutura de backend do sistema deve ser hospedada em uma Máquina Virtual Linux na plataforma Microsoft Azure.                     | Requisitos de Implementação           |
| RNF07         | O sistema deve ser capaz de processar e analisar, no mínimo, 100 gabaritos por minuto.                                                    | Desempenho                            |
| RNF08         | O sistema deve ser robusto, operando sem necessidade de scripts manuais, sendo tolerante a falhas e com capacidade de auto-recuperação.   | Confiabilidade                        |
| RNF09         | A interface do usuário deve ser intuitiva e fácil de usar para os diferentes perfis de usuário (ex: alunos, coordenadores).               | Usabilidade                           |  
| RNF10         | O custo operacional da solução de correção deve ser inferior a R$ 1,00 por aluno processado.                                              | Restrição Operacional                 |
| RNF11         | A arquitetura do sistema deve permitir o aumento no volume de processamento de gabaritos sem necessidade de reestruturação fundamental.   | Escalabilidade                        |
| RNF12         | O sistema deve ser projetado para permitir a adição ágil de novas funcionalidades no futuro com baixo acoplamento.                        | Manutenibilidade / Extensibilidade    |  
| RNF13         | O sistema deve garantir a segurança e a confidencialidade dos dados dos alunos (matrículas, desempenho) e dos gabaritos/provas.           | Segurança                             |


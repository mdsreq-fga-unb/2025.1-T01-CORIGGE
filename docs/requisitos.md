## Requisitos Funcionais

| Código | Descrição                                                                                                                                 |
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

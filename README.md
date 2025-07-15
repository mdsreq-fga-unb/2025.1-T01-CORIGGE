# Guia do PAS - Correção Automática de Gabaritos

## Sobre o Projeto

A Guia do PAS é uma empresa voltada para a preparação de estudantes para o Programa de Avaliação Seriada (PAS) da UnB. Com a expansão dos seus serviços para instituições de ensino, surgiu a necessidade de uma solução mais rápida, econômica e eficaz para correção de gabaritos.

Este projeto visa desenvolver uma aplicação multiplataforma para realizar correções automáticas de gabaritos utilizando visão computacional. A solução permitirá a digitalização dos gabaritos, identificação das respostas, geração de relatórios e análise de desempenho dos alunos, com grande economia de tempo e custo.

### Principais desafios:
- Uso de visão computacional para identificar marcações em gabaritos.
- Falta de padronização nos gabaritos preenchidos.
- Design intuitivo para uso interno da empresa.
- Integração entre múltiplas tecnologias.

---

## Como executar o projeto

### Pré-requisitos

Antes de começar, você precisará ter instalado em sua máquina:

- [Flutter](https://docs.flutter.dev/get-started/install) - Framework para desenvolvimento multiplataforma
- [Node.js e npm](https://nodejs.org/en/download/) - Para o servidor backend
- [Python](https://www.python.org/downloads/) - Para o processamento OpenCV

### Executando em Modo Debug

1. **Backend Server**
   ```bash
   cd backend/servidor
   npm install
   npm run dev
   ```

2. **OpenCV Server**
   ```bash
   cd backend/opencv
   python -m pip install -r requirements.txt
   # Crie um arquivo .env com o conteúdo:
   # DEBUG_MODE=True
   python main_processing_computer.py
   ```

3. **Frontend**
   - Abra o projeto no VS Code
   - Pressione `Ctrl+Shift+D` (Windows/Linux) ou `Cmd+Shift+D` (macOS)
   - Selecione a configuração de debug para seu sistema operacional (Windows/macOS/Linux)
   - Pressione F5 ou clique no botão de play

### Executando em Modo Release

1. **Backend Server**
   ```bash
   cd backend/servidor
   npm install
   npm run start-release   # Compila e executa em modo release
   ```

2. **OpenCV Build**
   ```bash
   cd backend/opencv
   python -m pip install -r requirements.txt
   python build_local.py
   ```

3. **Frontend**
   - Abra o projeto no VS Code
   - Pressione `Ctrl+Shift+D` (Windows/Linux) ou `Cmd+Shift+D` (macOS)
   - Selecione a configuração de release para seu sistema operacional (Windows/macOS/Linux)
   - Pressione F5 ou clique no botão de play

### Executando com Docker

O servidor backend pode ser executado usando Docker para facilitar o deploy:

1. **Criar arquivo .env**
   ```env
   # Server Configuration
   PORT=4502
   NODE_ENV=development

   # Supabase Configuration
   SUPABASE_URL=your_supabase_url
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

   # CORS Configuration
   CORS_ORIGIN=http://localhost:4502
   ```

2. **Construir a imagem**
   ```bash
   cd backend/servidor
   docker build -t corigge-backend .
   ```

3. **Executar o container**
   ```bash
   docker run -d \
     -p 4502:4502 \
     --name corigge-backend \
     --env-file .env \
     corigge-backend
   ```

4. **Verificar logs do container**
   ```bash
   docker logs corigge-backend
   ```

5. **Parar o container**
   ```bash
   docker stop corigge-backend
   ```

### Observações
- O servidor backend e o servidor OpenCV devem estar rodando antes de iniciar o frontend no modo debug
- No modo release, o servidor OpenCV é compilado, compactado e adicionado aos assets do frontend, sendo descompactado ao rodar o aplicativo
- Ao usar Docker, certifique-se de que o arquivo `.env` está presente no diretório antes de executar o container
- O servidor estará disponível em `http://localhost:4502` após a inicialização

## Documentação

- [Notion](https://www.notion.so/team/1db12b03-3960-81cf-8d13-00422b7d20cb/join)

## Equipe

<center>
<table style="margin-left: auto; margin-right: auto;">
    <tr>
        <td align="center">
            <a href="https://github.com/Marcelo-Adrian">
                <img style="border-radius: 50%;" src="https://github.com/Marcelo-Adrian.png" width="150px;"/>
                <h5 class="text-center">Marcelo<br>Adrian</h5>
            </a>
        </td>
        <td align="center">
            <a href="https://github.com/knz13">
                <img style="border-radius: 50%;" src="https://github.com/knz13.png" width="150px;"/>
                <h5 class="text-center">Otavio<br>Maya</h5>
            </a>
        </td>
        <td align="center">
            <a href="https://github.com/Atyrson">
                <img style="border-radius: 50%;" src="https://github.com/Atyrson.png" width="150px;"/>
                <h5 class="text-center">Atyrson<br> </h5>
            </a>
        </td>
        <td align="center">
            <a href="https://github.com/nateejpg">
                <img style="border-radius: 50%;" src="https://github.com/nateejpg.png" width="150px;"/>
                <h5 class="text-center">Nathan<br>Abreu</h5>
            </a>
        </td>
        <td align="center">
            <a href="https://github.com/pedroslrn">
                <img style="border-radius: 50%;" src="https://github.com/pedroslrn.png" width="150px;"/>
                <h5 class="text-center">Pedro<br>Victor</h5>
            </a>
        </td>
         <td align="center">
            <a href="https://github.com/eduardoferre">
                <img style="border-radius: 50%;" src="https://github.com/eduardoferre.png" width="150px;"/>
                <h5 class="text-center">Eduardo<br>Ferreira</h5>
            </a>
        </td>
	<td align="center">
            <a href="https://github.com/Edzada">
                <img style="border-radius: 50%;" src="https://github.com/Edzada.png" width="150px;"/>
                <h5 class="text-center">Esdras<br>de Sousa</h5>
            </a>
        </td>
</table>
</center>

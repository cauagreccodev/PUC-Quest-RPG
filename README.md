# PUC Quest RPG - Mobile Geolocation RPG 🌍🎮

🎉 **RELEASE 1.0 JÁ ESTÁ DISPONÍVEL!** 🎉
> O jogo chegou à sua aguardada versão 1.0! Todos os sistemas de batalha, gráficos e geolocalização foram finalizados e balanceados para a melhor experiência possível. Jogue agora mesmo baixando o APK!

**PIRPG** é um RPG imersivo desenvolvido em **Flutter** utilizando a engine **Flame** e integração nativa com o **Firebase**. O projeto transforma o espaço físico (com foco no Campus da PUC-Campinas) em um campo de jogo dinâmico, onde a geolocalização do usuário em tempo real dita a exploração do personagem no mundo virtual para enfrentar Bosses em épicas batalhas de Quiz!

---

## 🚀 Funcionalidades Principais (Versão 1.0)

- **Exploração via GPS (Geofencing):** O personagem se move conforme você caminha no mundo real. Áreas específicas do campus real liberam estágios (como CEATEC, CEA, CLC e CCHSA) e batalhas de chefes.
- **Sistema de Batalha de Quiz:** Enfrente Bosses cibernéticos/medievais respondendo perguntas técnicas. Acertar causa dano no chefe, errar faz você receber um contra-ataque letal.
- **Mochila e Consumíveis (Inventário):**
  - 🌿 **Erva Divina:** Restaura 40 HP, porém consome o seu turno na batalha.
  - 🔥 **Erva da Ira:** Dobra o seu próximo golpe se você acertar a questão. Se errar, recebe o dobro de dano por estar vulnerável!
- **Sistema de Contas Flexível (Firebase):** Jogue livremente como **Visitante** sem perder progresso (salvamento em cache local). Quando desejar, vincule sua jornada a uma conta do **Google** ou faça o registro por **E-mail**, e seus itens/status irão automaticamente para a nuvem!
- **UI Imersiva:** Estética Dark Medieval misturada com elementos Cyberpunk, trazendo menus interativos, mini-mapa com carrossel horizontal, sons imersivos e customização de volume.

---

## 🛠️ Tecnologias Utilizadas

- **[Flutter](https://flutter.dev/):** Framework para alta performance multiplataforma (Web e Mobile).
- **[Firebase Auth & Firestore](https://firebase.google.com/):** Sincronização em tempo real de contas de jogadores e saves na nuvem.
- **[Flame Engine](https://flame-engine.org/):** Engine para processar a física do movimento e renders 2D.
- **[Geolocator](https://pub.dev/packages/geolocator):** Gestão de coordenadas GPS e distâncias (Cálculo de Haversine).
- **[Provider](https://pub.dev/packages/provider):** Gerenciamento de estado robusto (áudio, inventário do player, etc).

---

## 🎨 Design do Jogo e Lore

Você assume o papel de um universitário que acabou pegando dependência (DP) em várias matérias cruciais do 1º e 2º ano da faculdade. Para finalmente conseguir o seu tão sonhado diploma, você precisará enfrentar essas disciplinas como verdadeiros desafios!

A jornada é dividida em estágios baseados nas matérias em que o jogador pegou dependência:
- **Estágio 1:** Matemática Discreta
- **Estágio 2:** Algoritmos e Lógica de Programação
- **Estágio 3:** Estruturas de Dados I e II
- **Estágio 4:** Banco de Dados I e II
- **Estágio 5:** Organização e Arquitetura de Computadores

Para progredir e obter a **Chave do Diploma**, você deve explorar o campus andando fisicamente até as áreas e derrotar o Boss de cada estágio com seu conhecimento. Ao vencer todos os desafios, a chave do diploma desbloqueará uma funcionalidade especial no CT (Centro de Tecnologia) da PUC no final do jogo!

### Os Centros Acadêmicos (Domínios)
O campus foi dominado e dividido em núcleos corrompidos onde os Bosses das matérias se encontram:
- **CEATEC (Laranja 🟠):** Engenharias e Tecnologia. Máquinas fora de controle e algoritmos rebeldes.
- **CEA (Vermelho 🔴):** Economia e Administração.
- **CLC (Azul 🔵):** Linguagem e Comunicação.
- **CCHSA (Amarelo 🟡):** Humanas e Sociais.

---

## 📦 Como Executar

### Pré-requisitos
- Flutter SDK instalado.
- Dispositivo Android com GPS ativado (ou emulador com simulação de GPS rodando o Chrome).

### 📱 Instalação Direta (Android)
Para jogar imediatamente sem precisar instalar o Flutter, você pode baixar o arquivo executável APK:
1. Faça o download do arquivo `app-release.apk` (disponível na aba de *Releases* do repositório no GitHub ou ao rodar o comando de build).
2. Transfira para o seu dispositivo Android e instale.

### 💻 Rodando o Código Fonte (Desktop / Web / Emulador)
Caso queira compilar o jogo ou rodar no Desktop/Chrome:
1. Clone o repositório:
```bash
git clone https://github.com/cauagreccodev/PI_RPG.git
```
2. Instale as dependências:
```bash
flutter pub get
```
3. Execute o projeto (no navegador Chrome ou no emulador Android):
```bash
flutter run -d chrome
```
*(Para construir o seu próprio APK atualizado, use `flutter build apk`)*

---

## 👥 Equipe de Desenvolvimento

*   **Cauã Vasconcelos Grecco de Faria (25006367):** Game Design & Assets. Developer & logic.
*   **Leandro Nascimento Lucatelli (25007808):** Game Design & Assets. Developer & logic.
*   **Rodrigo de Faria Perico (22004955):** Developer & logic.
*   **Gustavo Antunes (25013281):** Developer & logic.
*   **Pedro Henrique Vieira Lima (25018202):** Developer & logic.

---

## ⚖️ Licença
Este projeto é de uso acadêmico para a PUC-Campinas Campus 1.

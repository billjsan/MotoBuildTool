Moto Build Tool
===============
Ferramenta de linha de comando em Bash para facilitar o processo de build, download
e instalação de APKs, utilizando SSH para build remoto e ADB para instalação local.

Funcionalidades	
---------------
> v0.2

- Conexão via SSH com servidor remoto de build

- Build de APKs como Settings, TrafficStatsProvider e TrafficStatsTests

- Inclusão opcional de patch (cherry-pick)

- Instalação automática do APK via adb

- Reboot automático do dispositivo

- Armazenamento dos APKs na pasta out/
  Requisitos

> v0.3

- Melhora a interação com o usuário

- Menos verboso

- Armazena os logs

- Mais opções de devices

- Localiza o path do apk automaticamente

- Opção de adicionar o nome do device diretamente

- Melhora legibilidade do código

  
Pre requisitos
----------
- Linux com Bash
- Acesso SSH ao servidor de build (ex: reston, ladybug)
- Ambiente AOSP configurado no servidor remoto
- adb e ssh instalados localmente
- Permissão para compilar no servidor

Instalação
----------
1. Clone este repositório: git clone git@github.com:billjsan/MotoBuildTool.git
2. Dê permissão de execução aos scripts ex: chmod +x setup.sh
3. Execute o scipt de setup: ./setup.sh
 Uso
---
Inicie a ferramenta com o comando: flashMotoApk
Em seguida, siga as instruções interativas:

Desinstalação
-------------
1. Dê permissão de execução aos scripts ex: chmod +x uninstall.sh
2. Execute o comando de uninstall ./uninstal.sh

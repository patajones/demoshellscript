# Demonstração de Shell Script

Baixe o projeto e execute 

```shell
sudo ./prepararjogos
```

Serão criado 30 usuários com nome aleatório no linux com o prefixo `jogador_` e senha `123456`
Esses usuários serão divididos em 3 grupos e cada usuario poderá executar o script ~/joga.sh de outro usuário do mesmo grupo.

Os usuários podem ainda executar os comandos: `grupo` e `jogadores` que vão mostrar o grupo e os outros jogadores.

## Visual Studio Code

Se voce executar esse projeto no Visual Studio Code, ele está configurado para rodar dentro de um container. 

Veja como em https://code.visualstudio.com/docs/devcontainers/containers 
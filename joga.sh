#!/bin/bash

jogadores() {
  echo "# TODOS OS JOGADORES: "  
  grep -oE '^jogador_[0-9]+' /etc/passwd | cut -d: -f1 | sort | pr -3 -t
  local meu_usuario
  local meu_grupo
  meu_usuario=$(whoami)
  if [[ "$meu_usuario" =~ ^jogador_[0-9]+$ ]]; then
    meu_grupo=$(grep -E "\\b[^[:alnum:]]${meu_usuario}[^[:alnum:]]" /etc/group | cut -d: -f1)
    if [ -n "$meu_grupo" ]; then
      echo ""
      echo ""
      echo "# Meu Grupo: ${meu_grupo}"
      echo "# Jogadores do meu Grupo:"
      grep "^$meu_grupo:" /etc/group | cut -d: -f4 | tr ',' '\n' | sort | pr -3 -t
      echo ""
      echo "#-------"
      echo ""
      echo "# Para Jogar execute: "
      echo ""
      echo "           ~jogador_??/joga.sh"
      echo ""
    else
      echo "[ERROR] Não foi possível determinar o grupo para o usuário $meu_usuario."
    fi
  else 
    echo "[WARN] Você não é um jogador. Autentique com um usuário \"jogador\" para verificar qual é o seu grupo e seus adversários"
  fi  
}

grupo() {
  local meu_usuario=$(whoami)
  if [[ ! "$meu_usuario" =~ ^jogador_[0-9]+$ ]]; then
    >&2 echo "Você não é um jogador. Autentique com um usuário \"jogador\" para verificar qual é o seu grupo"
    return 1
  fi
  grep -E "\\b[^[:alnum:]]${meu_usuario}[^[:alnum:]]" /etc/group | cut -d: -f1
}

# Executa o script se for chamado pela linha de comando
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  opcoes=("GANHOU" "PERDEU")
  echo ${opcoes[$(shuf -i 0-$((${#opcoes[@]}-1)) -n 1)]}
fi
#!/bin/bash

set -e

# Função para gerar um nome aleatório para o jogador
generate_player_name() {
  local random_number=$(shuf -i 1-50 -n 1)
  local player_number=$(printf "%02d" $random_number)
  echo jogador_$player_number
}

# Função para gerar um nome aleatório para o jogador que já não exista no LINUX
generate_exclusive_player_name() {
  local player_name
  local max_attempts=100
  local attempt_count=0
  # Gera um nome de jogador, mas verifica se já não existe um usuário com esse nome
  while ((attempt_count < max_attempts)); do
    player_name=$(generate_player_name)
    # Verifica se o nome não existe no /etc/passwd
    if ! grep -q "^$player_name:" /etc/passwd; then
      echo $player_name
      return 0
    fi
    ((attempt_count++))
  done
  # Se atingir o limite máximo de tentativas, envia mensagem de erro para stderr e retorna código de erro
  >&2 echo "[ERROR] Não foi possível gerar um nome de jogador exclusivo após $max_attempts tentativas."
  return 1
}

# Função para criar o Jogador
# Cada Jogador é um usuário no Linux sendo:
#   - devem possuir um diretório dentro do /home;
#   - a estrutura do skel deve ser criada no seu diretório padrão dos usuários;
#   - devem conseguir executar os scripts da sua pasta /home
#   - devem possuir uma senha padrão inicial para se autenticar no sistema (receber por parametro)
create_player() {

  if [ -z "$1" ]; then
    >&2 echo "[ERROR] É necessário fornecer uma senha como parâmetro para criar um jogador."
    return 1
  fi

  local player_name
  player_name=$(generate_exclusive_player_name)
  local password=$1

  # Com o nome de um usuário único, cria um usuário no Linux
  useradd -m -k /etc/skel -s /bin/bash "$player_name"
  
  # Mudar a senha do usuário para a senha fornecida como parâmetro
  echo "$player_name:$password" | chpasswd

  echo "$player_name"
}

# Função para listar todos os jogadores
lista_players() {
  grep -oE '^jogador_[0-9]+' /etc/passwd | cut -d: -f1
}

# Excluir todos os grupos 
delete_all_groups() {
  local groups=("$@")

  # Verificar se a lista de grupos está vazia
  if [ "${#groups[@]}" -eq 0 ]; then
    >&2 echo "[ERROR] Nenhum grupo informado para exclusão."
    return 1
  fi

  # Iterar sobre a lista de grupos e removê-los
  for group in "${groups[@]}"; do
    # Verificar se o grupo existe
    if grep -q "^$group:" /etc/group; then
      groupdel "$group"
      echo "[INFO] Grupo $group removido."
    else
      >&2 echo "[WARN] Grupo $group não encontrado."
    fi
  done
}

# Excluir todos os jogadores
delete_all_players() {
  local players=$(lista_players)

  # Itera sobre a lista de jogadores e remove cada um
  for player in $players; do
    userdel -rf "$player" 2>/dev/null
    echo "Jogador $player removido."
  done
}

# Função para listar todos os jogadores que estão em um grupo especifico
lista_players_group() {
  local group_name=$1
  local group_line=$(grep "^$group_name:" /etc/group)

  if [[ -n "$group_line" ]]; then
    echo "$group_line" | cut -d: -f4 | tr ',' '\n'
  fi
}

# Função para listar todos os jogadores que NÃO estão em um grupo especifico
lista_players_without_group() {
  local players_without_group=()

  # Obter a lista de todos os jogadores do /etc/passwd
  local all_players=$(lista_players)

  # Obter a lista de jogadores em grupos do /etc/group
  local players_in_groups=$(cut -d: -f4 /etc/group | tr ',' '\n')

  # Filtrar os jogadores que não estão em nenhum grupo
  for player in $all_players; do
    if ! echo "$players_in_groups" | grep -q "\<$player\>"; then
      players_without_group+=("$player")
    fi
  done

  echo "${players_without_group[@]}" | tr ' ' '\n'
}

# Função para criar os grupos de jogador e atribuir os jogadores dentro do grupo
create_group() {
  # Verificar número de parâmetros
  if [ "$#" -ne 2 ]; then
    >&2 echo "[ERROR] Parâmetros inválidos. Usar: create_group <group_name> <num_players>"
    return 1
  fi

  local group_name=$1
  local num_players=$2

  # Verificar se os parâmetros são válidos
  if [ -z "$group_name" ] || [ -z "$num_players" ]; then
    >&2 echo "[ERROR] Parâmetros inválidos. Uso: create_group <group_name> <num_players>"
    return 1
  fi

  # Verificar se o grupo já existe no /etc/group
  if grep -q "^$group_name:" /etc/group; then
    >&2 echo "[ERROR] O grupo $group_name já existe."
    return 1
  fi

  # Verificar se num_players é um número válido
  if ! [[ "$num_players" =~ ^[0-9]+$ ]]; then
    >&2 echo "[ERROR] O segundo parâmetro deve ser um número inteiro."
    return 1
  fi

  # Criar um grupo Linux com o nome recebido como parâmetro
  groupadd "$group_name"

  # Atribuir usuários que não estejam em outros grupos para esse grupo
  for ((i=1; i<=$num_players; i++)); do
    local player_name
    local available_players=$(lista_players_without_group "$group_name")
    
    # Verificar se existem jogadores disponíveis
    if [[ -z "$available_players" ]]; then
      echo "[WARN] Não há jogadores disponíveis para o grupo $group_name."
      break
    fi
    
    player_name=$(echo "$available_players" | shuf -n 1)

    # Adicionar o usuário selecionado ao grupo recém-criado
    usermod -aG "$group_name" "$player_name"
    echo "[INFO] Jogador $player_name adicionado ao grupo $group_name."

    # Mudar as permissões no /home do usuários para g+x
    chmod g+x "/home/$player_name"
    chgrp -R $group_name "/home/$player_name"
  done
}

main() {
  # preparar /etc/skel
  echo "Preparando /etc/skel"
  echo "--------------------"

  cp -f ./joga.sh /etc/skel/joga.sh
  cp -f ./joga.sh ~/joga.sh
  echo "source ./joga.sh" >> /etc/skel/.bashrc
  echo "source ./joga.sh" >> ~/.bashrc  

  ls -lar /etc/skel
  cat /etc/skel/.bashrc
  echo "--------------------"
  echo "--------------------"

  echo "Preparando JOGADORES"
  echo "--------------------"
  delete_all_players
  # Criar 30 jogadores
  local default_password="123456"
  for ((i=1; i<=30; i++)); do
    create_player "$default_password"
  done

  echo "--------------------"
  echo "--------------------"
  echo "Preparando GRUPOS"
  echo "--------------------"

  #Criar 3 grupos 
  grupos=("ferrari" "mercedes" "redbull")
  delete_all_groups "${grupos[@]}"
                    
  for grupo in "${grupos[@]}"; do
    create_group "$grupo" 10
  done
}

# Executa o script se for chamado pela linha de comando
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi

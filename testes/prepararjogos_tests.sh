#!/bin/bash

# Carrega as funções do script principal
source ../prepararjogos.sh

test_generate_player_name() {
  echo "Testando test_generate_player_name"  
  local player_name
  player_name=$(generate_player_name)

  # Verifica se o nome gerado possui o formato esperado
  if [[ "$player_name" =~ ^jogador_[0-9]+$ ]]; then
    echo "PASS: generate_player_name"
  else
    echo "FAIL: generate_player_name"
  fi
}

test_generate_exclusive_player_name() {
  echo "Testando test_generate_exclusive_player_name"  
  local player_name
  player_name=$(generate_exclusive_player_name)
  # Verifica se o nome gerado possui o formato esperado e não existe no /etc/passwd
  if [[ "$player_name" =~ ^jogador_[0-9]+$ && ! $(grep -q "^$player_name:" /etc/passwd) ]]; then
    echo "PASS: generate_exclusive_player_name"
  else
    echo "FAIL: generate_exclusive_player_name"
  fi
}

test_create_player() {
  echo "Testando create_player..."  
  local test_password="123456"

  # Chama a função para criar o jogador
  local created_player=$(create_player "$test_password")

  # Verifica se o jogador foi criado corretamente
  if grep -q "^$created_player:" /etc/passwd; then
    echo "PASS: create_player"
    userdel -r "$created_player" > /dev/null 2>&1     
  else
    echo "FAIL: create_player"
  fi
}

test_list_players() {
  echo "Testando lista_players..."
  local test_password="123456"
  # Criar dois jogadores
  local player1=$(create_player "$test_password")
  local player2=$(create_player "$test_password")

  # Obter a lista de jogadores
  local players=$(lista_players)

  # Verificar se os jogadores criados estão na lista
  if echo "$players" | grep -q "^$player1$"; then
    echo "PASS: Player $player1 na lista."
  else
    echo "FAIL: Player $player1 não encontrado na lista."
  fi

  if echo "$players" | grep -q "^$player2$"; then
    echo "PASS: Player $player2 na lista."
  else
    echo "FAIL: Player $player2 não encontrado na lista."
  fi

  # Excluir os jogadores
  userdel -r "$player1" > /dev/null 2>&1
  userdel -r "$player2" > /dev/null 2>&1
}

# Teste para verificar se a função lista_players_without_group retorna jogadores corretamente
teste_lista_players_without_group() {
  echo "Testando lista_players_without_group..."

  # Excluir todos os jogadores
  delete_all_players > /dev/null 2>&1

  # Criar 2 jogadores
  local player1
  local player2
  player1=$(create_player "123456")  
  player2=$(create_player "123456")

  # Obter a lista de jogadores sem grupo
  local players_without_group
  players_without_group=$(lista_players_without_group)

  # Verificar se os jogadores criados estão na lista
  if echo "$players_without_group" | grep -q "^$player1$"; then
    echo "PASS: Player $player1 na lista de jogadores sem grupo."
  else
    echo "FAIL: Player $player1 não encontrado na lista de jogadores sem grupo."
  fi

  if echo "$players_without_group" | grep -q "^$player2$"; then
    echo "PASS: Player $player2 na lista de jogadores sem grupo."
  else
    echo "FAIL: Player $player2 não encontrado na lista de jogadores sem grupo."
  fi

  # Excluir os jogadores
  userdel -r "$player1" > /dev/null 2>&1
  userdel -r "$player2" > /dev/null 2>&1
}

# Teste para verificar se a função create_group adiciona jogadores corretamente aos grupos
test_create_group() {
  echo "Testando create_group..."
  local test_password="123456"

  local group1="ferrari"
  local group2="mercedes"
  local group3="rbr"
  local group4="teste"

  # Excluir os grupos
  groupdel "$group1" > /dev/null 2>&1 || true
  groupdel "$group2" > /dev/null 2>&1 || true
  groupdel "$group3" > /dev/null 2>&1 || true
  groupdel "$group4" > /dev/null 2>&1 || true
 
  # Criar 4 jogadores
  local player1
  local player2
  local player3
  local player4
  player1=$(create_player "$test_password")
  player2=$(create_player "$test_password")
  player3=$(create_player "$test_password")
  player4=$(create_player "$test_password")

  # Criar 2 grupos com 2 usuarios cada
  create_group "$group1" 2
  create_group "$group2" 2
  create_group "$group3" 2
  create_group "$group4" 2

  local player
  local players
  local group_count
  players=("$player1" "$player2" "$player3" "$player4")
  for player in "${players[@]}"; do      
    group_count=$(grep -c ":.*$player" /etc/group) || true
    if [[ $group_count -eq 1 ]]; then
      echo "PASS: $player está em 1 grupo."
    else
      echo "FAIL: $player não está em 1 grupo."
    fi
  done

  # Excluir os jogadores
  userdel -r "$player1" > /dev/null 2>&1
  userdel -r "$player2" > /dev/null 2>&1
  userdel -r "$player3" > /dev/null 2>&1
  userdel -r "$player4" > /dev/null 2>&1

  # Excluir os grupos
  groupdel "$group1" > /dev/null 2>&1
  groupdel "$group2" > /dev/null 2>&1
}

# Adicione este teste à sua suíte de testes
run_tests() {
  test_generate_player_name
  test_generate_exclusive_player_name
  test_create_player
  test_list_players
  teste_lista_players_without_group
  test_create_group
}

# Executa os testes
run_tests

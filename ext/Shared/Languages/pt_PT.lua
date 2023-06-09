local code = 'pt_PT' -- Add/replace the xx_XX here with your language code (like de_DE, en_US, or other)!

-- GENERAL
Language:add(code, "Bot Kit", "Kit de Bot")
Language:add(code, "The Kit of the Bots", "O Kit dos Bots")
Language:add(code, "Bot Color", "Cor do Bot")
Language:add(code, "The Color of the Bots", "A Cor dos Bots")

-- DIFFICULTY
Language:add(code, "Bot Worsening Skill", "Piora da Habilidade do Bot")
Language:add(code, "Variation of the skill of a single bot. The higher, the worse the bots can get compared to the original settings", "Variação da habilidade de um único bot. quanto maior, pior os bots podem ficar em comparação com as configurações originais")
Language:add(code, "Damage Factor Knife", "Fator de Dano da Faca")
Language:add(code, "Original Damage from bots gets multiplied by this", "O Dano Original dos bots é multiplicado por isso")

-- SPAWN
Language:add(code, "Spawn Mode", "Modo de Spawn")
Language:add(code, "Mode the bots spawn with", "Modo com que os bots spawnam")
Language:add(code, "Start Number of Bots", "Número Inicial de Bots")
Language:add(code, "Bots for spawnmode", "Bots para o spawnmode")
Language:add(code, "New Bots per Player", "Novos Bots por Jogador")
Language:add(code, "Number to increase Bots by when new players join", "Número de Bots adicionais quando novos jogadores entrarem")
Language:add(code, "Factor Player Team Count", "Fator de Contagem de Equipe de Jogadores")
Language:add(code, "Reduce player team in balanced_teams or fixed_number mode", "Reduza o time de jogadores no modo balanced_teams ou fixed_number")
Language:add(code, "Team of the Bots", "Equipe dos Bots")
Language:add(code, "Default bot team (0 = neutral / auto, 1 = US, 2 = RU) TeamId.Team2", "Equipe de bot padrão (0 = neutro / automático, 1 = EUA, 2 = RU) TeamId.Team2")
Language:add(code, "New Loadout on Spawn", "Novo Loadout no Spawn")
Language:add(code, "Bots get a new kit and color, if they respawn", "Os bots ganham um novo kit e cor, se respawnarem")
Language:add(code, "Max Assault Bots", "Número Máximo de Bots de Assalto")
Language:add(code, "Maximum number of Bots with Assault Kit. -1 = no limit", "Número máximo de Bots com Kit de Assalto. -1 = sem limite")
Language:add(code, "Max Engineer Bots", "Número Máximo de Bots de Engenheiro")
Language:add(code, "Maximum number of Bots with Engineer Kit. -1 = no limit", "Número máximo de Bots com Kit de Engenheiro. -1 = sem limite")
Language:add(code, "Max Support Bots", "Número Máximo de Bots de Suporte")
Language:add(code, "Maximum number of Bots with Support Kit. -1 = no limit", "Número máximo de Bots com Kit de Suporte. -1 = sem limite")
Language:add(code, "Max Recon Bots", "Número Máximo de Bots de Recon")
Language:add(code, "Maximum number of Bots with Recon Kit. -1 = no limit", "Número máximo de Bots com Kit de Recon. -1 = sem limite")
Language:add(code, "Additional Spawn Delay", "Atraso de Spawn Adicional")
Language:add(code, "Additional time a bot waits to respawn", "Tempo adicional que um bot espera para respawnar")

-- SPAWN LIMITS
Language:add(code, "Max Bots Per Team (default)", "Número Máximo de Bots Por Equipe (padrão)")
Language:add(code, "Max number of bots in one team, if no other mode fits", "Número máximo de bots em uma equipe, se nenhum outro modo se encaixar")

-- BEHAVIOUR
Language:add(code, "FOV of Bots", "Campo de Visão (FOV) dos Bots")
Language:add(code, "Degrees of FOV of Bot", "Graus do Campo de Visão (FOV) do Bot")
Language:add(code, "FOV of Bots Verticle", "Campo de Visão (FOV) Vertical dos Bots")
Language:add(code, "Degrees of FOV of Bot in vertical direction", "Graus do Campo de Visão (FOV) Vertical do Bot")
Language:add(code, "Max Distance a normal soldier shoots back if Hit", "Distância Máxima que um soldado normal atira de volta se for atingido")
Language:add(code, "Meters until bots (not sniper) shoot back if hit", "Metros até que os bots (não sniper) atirem de volta se forem atingidos")
Language:add(code, "Bot Attack Mode", "Modo de Ataque do Bot")
Language:add(code, "Mode the Bots attack with. Random, Crouch or Stand", "Modo com o qual os Bots atacam. Aleatório, Agachado ou De Pé")
Language:add(code, "Shoot Back if Hit", "Atira de Volta Se for Atingido")
Language:add(code, "Bot shoots back if hit", "Bot atira de volta se for atingido")
Language:add(code, "Bots can kill themselves", "Bots podem se matar")
Language:add(code, "Bot takes fall damage or explosion-damage from own frags", "Bot recebe dano de queda ou dano de explosão de suas próprias granadas")
Language:add(code, "Bots teleport them when stuck", "Bots se teletransportam quando estiver presos")
Language:add(code, "Bot teleport to their target if they are stuck", "Bot se teletransporta para o alvo se estiver preso")
Language:add(code, "Move Sidewards", "Mover Para o Lado")
Language:add(code, "Bots move sidewards", "Bots se movem para o lado")
Language:add(code, "Max straight Cycle", "Ciclo Máximo em Linha Reta")
Language:add(code, "Max time bots move straight, before sidewards-movement (in sec)", "Tempo máximo que os bots se movem em linha reta, antes do movimento lateral (em segundos)")
Language:add(code, "Max Side Cycle", "Ciclo Máximo Lateral")
Language:add(code, "Max time bots move sidewards, before straight-movement (in sec)", "Tempo máximo que os bots se movem para o lado, antes do movimento em linha reta (em segundos)")
Language:add(code, "Min Move Cycle", "Ciclo Mínimo de Movimento")
Language:add(code, "Min time bots move sidewards or straight before switching (in sec)", "Tempo mínimo que os bots se movem para o lado ou em linha reta antes de alternar (em segundos)")

-- VEHICLE

-- WEAPONS
Language:add(code, "Random Weapon usage", "Uso Aleatório de Armas")
Language:add(code, "Use a random weapon out of the Weapon Set", "Use uma arma aleatória fora do conjunto de armas")
Language:add(code, "Knife of Bots", "Faca dos bots")
Language:add(code, "Knife of Bots, if random-weapon == false", "Faca dos Bots, se arma aleatória == false")

-- TRACE
Language:add(code, "Debug Trace Paths", "Depurar Trace Paths")
Language:add(code, "Shows the trace line and search area from Commo Rose selection", "Mostra a trace line e a área de pesquisa da seleção do Commo Rose")
Language:add(code, "Waypoint Range", "Faixa de Waypoint")
Language:add(code, "Set how far away waypoints are visible (meters)", "Defina o quão longe os waypoints são visíveis (metros)")
Language:add(code, "Draw Waypoint Lines", "Desenhar Linhas de Waypoint")
Language:add(code, "Draw waypoint connection lines", "Desenhar Linhas de conexão dos waypoints")
Language:add(code, "Line Range", "Alcançe das Linhas")
Language:add(code, "Set how far away waypoint lines are visible (meters)", "Defina a distância que as linhas do waypoint são visíveis (metros)")
Language:add(code, "Draw Waypoint IDs", "Desenhar IDs dos Waypoints")
Language:add(code, "Text Range", "Alcançe dos Textos")
Language:add(code, "Set how far away waypoint text is visible (meters)", "Defina a que distância o texto do waypoint é visível (metros)")
Language:add(code, "Draw Spawn Points", "Desenhe Pontos de Spawn")
Language:add(code, "Range of Spawn Points", "Alcançe dos Pontos de Spawn")
Language:add(code, "Set how far away spawn points are visible (meters)", "Defina a que distância os pontos de spawn são visíveis (metros)")
Language:add(code, "Trace Delta Points", "Traço dos Pontos Delta")
Language:add(code, "Update interval of trace", "Atualizar intervalo dos traços")
Language:add(code, "Nodes that are drawn per cycle", "Nós que são desenhados por ciclo")
Language:add(code, "Set how many nodes get drawn per cycle. Affects performance", "Defina quantos nós são desenhados por ciclo. Afeta o desempenho")

-- ADVANCED
Language:add(code, "Distance for direct attack", "Distância para ataque direto")
Language:add(code, "Distance bots can hear you at", "Distância que os bots podem ouvi-lo")
Language:add(code, "Bot melee attack cool-down", "Tempo de recarga do ataque corpo a corpo do Bot")
Language:add(code, "The time a bot waits before attacking with melee again", "O tempo que um bot espera antes de atacar corpo a corpo novamente")
Language:add(code, "Jump while shooting", "Salto enquanto atira")
Language:add(code, "Bots jump over obstacles while shooting if needed", "Bots saltam sobre obstáculos enquanto atiram, se necessário")
Language:add(code, "Jump while moving", "Salto enquanto se move")
Language:add(code, "Bots jump while moving. If false, only on obstacles!", "Bots saltam enquanto se movem. Se falso, apenas em obstáculos!")
Language:add(code, "Overwrite speed mode", "Substituir o modo de velocidade")
Language:add(code, "0 = no overwrite. 1 = prone, 2 = crouch, 3 = walk, 4 = run", "0 = sem substituição. 1 = deitado, 2 = agachado, 3 = andando, 4 = correndo")
Language:add(code, "Speed factor", "Fator de velocidade")
Language:add(code, "Reduces the movement speed. 1 = normal, 0 = standing", "Reduz a velocidade de movimento. 1 = normal, 0 = em pé")
Language:add(code, "Speed factor attack", "Fator de velocidade do ataque")
Language:add(code, "Use Random Names", "Usar Nomes Aleatórios")
Language:add(code, "Changes names of the bots on every new round. Experimental right now...", "Muda os nomes dos bots a cada nova rodada (configuração experimental)")

-- EXPERT
Language:add(code, "Maximum yaw per sec", "Guinada máxima por segundo")
Language:add(code, "In Degrees. Rotation Movement per second", "Em Graus. Movimento Rotacional por segundo")
Language:add(code, "Target distance waypoint", "Distância alvo até o waypoint")
Language:add(code, "The distance the bots have to reach to continue with the next Waypoint", "Distância que os bots precisam alcançar para continuar com o próximo Waypoint")
Language:add(code, "Keep one slot for players", "Mantenha um slot para jogadores")
Language:add(code, "Always keep one slot for free new Players to join", "Sempre mantenha um slot vazio para que novos jogadores possam entrar")
Language:add(code, "Distance to spawn", "Distância para spawnar")
Language:add(code, "Distance to spawn Bots away from players", "Distância para spawnar Bots longe dos jogadores")
Language:add(code, "Height distance to spawn", "Altura para spawnar")
Language:add(code, "Distance vertically, Bots should spawn away, if closer than distance", "Distância vertical que os Bots devem aparecer longe, se mais próximos que a distância")
Language:add(code, "Distance to spawn reduction", "Redução da distância para spawnar")
Language:add(code, "Reduce distance if not possible", "Reduza a distância se não for possível")
Language:add(code, "Max tries to spawn at distance", "Quantidade máxima de tentativas para spawnar à distância")
Language:add(code, "Try this often to spawn a bot away from players", "Tente isso com frequência para gerar um bot longe dos jogadores")
Language:add(code, "Attack way Bots", "Forma de Ataque dos Bots")
Language:add(code, "Bots on paths attack player", "Bots no caminho atacam o jogador")
Language:add(code, "Respawn way Bots", "Forma de Respawn dos Bots")
Language:add(code, "Bots on paths respawn if killed", "Bots no caminho respawnam se mortos")
Language:add(code, "Spawn Method", "Método de Spawn")
Language:add(code, "Method the bots spawn with. Careful, not supported on most of the maps!!", "Método com o qual os bots spawnam. Cuidado, não é suportado na maioria dos mapas!!")

-- OTHER
Language:add(code, "Disable UI", "Desativar Interface de Usuário (IU)")
Language:add(code, "If true, the complete UI will be disabled (not available in the UI)", "Se verdadeiro, a interface do usuário será completamente desabilitada (não disponível na IU -) )")
Language:add(code, "Allow Comm-UI for all", "Permitir Comm-IU para todos")
Language:add(code, "If true, all Players can access the Comm-Screen", "Se verdadeiro, todos os jogadores podem acessar a Comm-Screen")
Language:add(code, "Disable chat-commands", "Desativar comandos de bate-papo")
Language:add(code, "If true, no chat commands can be used", "Se verdadeiro, nenhum comando de bate-papo pode ser usado")
Language:add(code, "Disable RCON-commands", "Desabilitar comandos RCON")
Language:add(code, "If true, no RCON commands can be used", "Se verdadeiro, nenhum comando RCON pode ser usado")
Language:add(code, "Ignore Permissions", "Ignorar Permissões")
Language:add(code, "If true, all permissions are ignored --> everyone can do everything", "Se verdadeiro, todas as permissões são ignoradas --> todos podem fazer tudo")
Language:add(code, "Language", "Língua")
Language:add(code, "de_DE as sample (default is English, when language file does not exist)", "de_DE como exemplo (o padrão é inglês, quando o arquivo de idioma não existe)")

-- Strings of ./../../ext/Client/ClientNodeEditor.lua

-- Strings of ./../../ext/Server/BotSpawner.lua
Language:add(code, "CANT_JOIN_BOT_TEAM", "CANT_JOIN_BOT_TEAM")

-- Strings of ./../../ext/Server/UIServer.lua
Language:add(code, "A", "A")
Language:add(code, "B", "B")
Language:add(code, "C", "C")
Language:add(code, "D", "D")
Language:add(code, "Attack", "Atacar")
Language:add(code, "E", "E")
Language:add(code, "F", "F")
Language:add(code, "G", "G")
Language:add(code, "H", "H")
Language:add(code, "Back", "Voltar")
Language:add(code, "Defend", "Defender")
Language:add(code, "Bot respawn activated!", "Respawn de bot ativado!")
Language:add(code, "Bot respawn deactivated!", "Respawn de bot desativado!")
Language:add(code, "Bots will attack!", "Bots vão atacar!")
Language:add(code, "Bots will not attack!", "Bots não vão atacar!")
Language:add(code, "%s is currently not implemented", "%s não está implementado no momento")
Language:add(code, "Exit Vehicle", "Sair do veículo")
Language:add(code, "Enter Vehicle", "Entrar no veículo")
Language:add(code, "Drop Ammo", "Dropar Munição")
Language:add(code, "Drop Medkit", "Dropar Kit Médico")
Language:add(code, "Commands", "Comandos")
Language:add(code, "Attack Objective", "Atacar Objetivo")
Language:add(code, "Defend Objective", "Defender Objetivo")
Language:add(code, "Repair Vehicle", "Reparar Veículo")
Language:add(code, "Settings has been saved temporarily", "As configurações foram salvas temporariamente")
Language:add(code, "Settings has been saved", "As configurações foram salvas")

-- Strings of ./../../ext/Server/NodeCollection.lua
Language:add(code, "Loaded %d paths with %d waypoints for map %s", "Carregou-se %d caminhos com %d waypoints para o mapa %s")
Language:add(code, "Save in progress...", "Salvando...")
Language:add(code, "Failed to execute query: %s", "Falha ao executar a consulta: %s")
Language:add(code, "Saved %d paths with %d waypoints for map %s", "Salvou-se %d caminhos com %d waypoints para o mapa %s")
Language:add(code, "Draw the IDs of the waypoints", "Desenhe os IDs dos waypoints")
Language:add(code, "Draw the Points where players can spawn", "Desenhe os pontos onde os jogadores podem spawnar")
Language:add(code, "Snipers attack choppers", "Snipers atacam helicópteros")
Language:add(code, "Bots with sniper-rifels attack choppers", "Bots com rifles de precisão atacam helicópteros")
Language:add(code, "Bots Attack Players", "Bots atacam jogadores")
Language:add(code, "Bots attack Players from other team", "Bots atacam jogadores de outra equipe")
Language:add(code, "Add Mcom-Action", "Adicionar ação do MCOM")
Language:add(code, "Overwrite: Loop-Path", "Sobrescrever: Caminho em loop")
Language:add(code, "Overwrite: Reverse-Path", "Sobrescrever: Caminho reverso")
Language:add(code, "Remove Data", "Remover dados")
Language:add(code, "Add Label / Objective", "Adicionar rótulo/objetivo")
Language:add(code, "Remove Label / Objective", "Remover rótulo/objetivo")
Language:add(code, "Vehicles", "Veículos")
Language:add(code, "Remove all Labels / Objectives", "Remover todos os rótulos/objetivos")
Language:add(code, "Paths", "Caminhos")
Language:add(code, "Exit", "Saída")
Language:add(code, "Land", "Terra")
Language:add(code, "Water", "Água")
Language:add(code, "Air", "Ar")
Language:add(code, "Clear Path-Type", "Limpar tipo de caminho")
Language:add(code, "Path-Type", "Tipo de caminho")
Language:add(code, "Exit Vehicle Passengers", "Sair passageiros do veículo")
Language:add(code, "Exit Vehicle All", "Sair todos do veículos")
Language:add(code, "Remove Vehicle Data", "Remover dados do veículo")
Language:add(code, "Vehicle", "Veículo")
Language:add(code, "Add Vehicle", "Adicionar veículo")
Language:add(code, "Set Vehicle Path-Type", "Definir tipo de caminho do veículo")
Language:add(code, "Remove Vehicle", "Remover veículo")
Language:add(code, "Add Tank", "Adicionar tanque")
Language:add(code, "Add Chopper", "Adicionar helicóptero")
Language:add(code, "Add Plane", "Adicionar avião")
Language:add(code, "Add Other Vehicle", "Adicionar outro veículo")
Language:add(code, "Set Vehicle Spawn-Path", "Definir caminho de spawn do veículo")
Language:add(code, "US", "US")
Language:add(code, "Team", "Equipe")
Language:add(code, "RU", "RU")
Language:add(code, "Vehicle 1", "Veículo 1")
Language:add(code, "Vehicle 2", "Veículo 2")
Language:add(code, "Vehicle 3", "Veículo 3")
Language:add(code, "Vehicle 4", "Veículo 4")
Language:add(code, "Vehicle 5", "Veículo 5")
Language:add(code, "Index", "Índice")
Language:add(code, "Vehicle 6", "Veículo 6")
Language:add(code, "Vehicle 7", "Veículo 7")
Language:add(code, "Vehicle 8", "Veículo 8")
Language:add(code, "Vehicle 9", "Veículo 9")
Language:add(code, "Vehicle 10", "Veículo 10")
Language:add(code, "Add", "Adicionar")
Language:add(code, "Remove", "Remover")
Language:add(code, "Base", "Base")
Language:add(code, "MCOM", "MCOM")
Language:add(code, "MCOM Interact", "MCOM Interagir")
Language:add(code, "Set Spawn-Path", "Definir caminho de spawn")
Language:add(code, "Base US", "Base dos EUA")
Language:add(code, "Base RU", "Base da Rússia")
Language:add(code, "Capture Point", "Ponto de captura")
Language:add(code, "MCOM 1", "MCOM 1")
Language:add(code, "MCOM 2", "MCOM 2")
Language:add(code, "MCOM 3", "MCOM 3")
Language:add(code, "MCOM 4", "MCOM 4")
Language:add(code, "MCOM 5", "MCOM 5")
Language:add(code, "MCOM 6", "MCOM 6")
Language:add(code, "MCOM 7", "MCOM 7")
Language:add(code, "MCOM 8", "MCOM 8")
Language:add(code, "MCOM 9", "MCOM 9")
Language:add(code, "MCOM 10", "MCOM 10")
Language:add(code, "MCOM INTERACT 1", "INTERAÇÃO DO MCOM 1")
Language:add(code, "MCOM INTERACT 2", "INTERAÇÃO DO MCOM 2")
Language:add(code, "MCOM INTERACT 3", "INTERAÇÃO DO MCOM 3")
Language:add(code, "MCOM INTERACT 4", "INTERAÇÃO DO MCOM 4")
Language:add(code, "MCOM INTERACT 5", "INTERAÇÃO DO MCOM 5")
Language:add(code, "MCOM INTERACT 6", "INTERAÇÃO DO MCOM 6")
Language:add(code, "MCOM INTERACT 7", "INTERAÇÃO DO MCOM 7")
Language:add(code, "MCOM INTERACT 8", "INTERAÇÃO DO MCOM 8")
Language:add(code, "MCOM INTERACT 9", "INTERAÇÃO DO MCOM 9")
Language:add(code, "MCOM INTERACT 10", "INTERAÇÃO DO MCOM 10")
Language:add(code, "base ru stage 1", "base ru estágio 1")
Language:add(code, "base ru stage 2", "base ru estágio 2")
Language:add(code, "base ru stage 3", "base ru estágio 3")
Language:add(code, "base ru stage 4", "base ru estágio 4")
Language:add(code, "base ru stage 5", "base ru estágio 5")
Language:add(code, "base us stage 1", "base nos estágio 1")
Language:add(code, "base us stage 2", "base nos estágio 2")
Language:add(code, "base us stage 3", "base nos estágio 3")
Language:add(code, "base us stage 4", "base nos estágio 4")
Language:add(code, "base us stage 5", "base nos estágio 5")
Language:add(code, "Objective", "Objetivo")
Language:add(code, "BOTH", "AMBAS")
Language:add(code, "Zombies Drop Ammo", "Zumbis largam munição")
Language:add(code, "Zombies drop randomly some ammo", "Zumbis jogam munição aleatoriamente")
Language:add(code, "Randomize Helth of Zombies", "Randomize Helth of Zombies")
Language:add(code, "zombie-helth differs from bot to bot", "zombie-helth difere de bot para bot")
Language:add(code, "Randomize Attack-Speed of Zombies", "Randomize a velocidade de ataque dos zumbis")
Language:add(code, "zombie-speed differs from bot to bot", "a velocidade do zumbi difere de bot para bot")
Language:add(code, "Randomize Damage that zombies deal", "Randomize Dano que os zumbis causam")
Language:add(code, "zombie-damage differs from bot to bot", "dano zumbi difere de bot para bot")
Language:add(code, "Randomize Jump-Speeds of zombies", "Randomize as velocidades de salto dos zumbis")
Language:add(code, "zombie-high-jumps differs from bot to bot", "zombie-high-jumps difere de bot para bot")
Language:add(code, "Zombies prone", "propenso a zumbis")
Language:add(code, "Zombies can prone when walking around", "Zumbis podem cair quando andam por aí")
Language:add(code, "Zombies crouch", "zumbis agachados")
Language:add(code, "Zombies can crouch when walking around", "Zumbis podem se agachar ao andar")
Language:add(code, "Zombies walk", "Zumbis andam")
Language:add(code, "Zombies can walk when walking around", "Zumbis podem andar quando andam por aí")
Language:add(code, "Zombies sprint", "corrida de zumbis")
Language:add(code, "Zombies can sprint when walking around", "Zumbis podem correr ao caminhar")
Language:add(code, "Bot Max Health at spawn", "Bot Max Health no spawn")
Language:add(code, "Max health of bot at spawn(default 100.0)", "Saúde máxima do bot no spawn (padrão 100.0)")
Language:add(code, "Min health of bot at spawn (default 100.0)", "Saúde mínima do bot no spawn (padrão 100.0)")
Language:add(code, "Bot Min Health at spawn", "Bot Min Health no spawn")
Language:add(code, "Damage multiplier for shooting bots in the head", "Multiplicador de dano para atirar bots na cabeça")
Language:add(code, "Modifies the speed while attacking. 1 = normal", "Modifica a velocidade ao atacar. 1 = normal")
Language:add(code, "Min Speed factor attack", "Ataque do fator de velocidade mínima")
Language:add(code, "Modifies the minimal speed while attacking. 1 = normal", "Modifica a velocidade mínima ao atacar. 1 = normal")
Language:add(code, "Min High Jump Speed", "Velocidade mínima de salto alto")
Language:add(code, "Min Speed the bots jump with on high-jumps", "Velocidade mínima com que os bots saltam em saltos altos")
Language:add(code, "Max High Jump Speed", "Velocidade máxima de salto alto")
Language:add(code, "Max Speed the bots jump with on high-jumps", "Velocidade máxima com que os bots saltam em saltos altos")
Language:add(code, "Max waves", "Ondas máximas")
Language:add(code, "Total amount of waves needed to win. 0 = infinite", "Quantidade total de ondas necessárias para vencer. 0 = infinito")
Language:add(code, "Player Lives", "Jogadores vivem")
Language:add(code, "Amount of times players can die before losing", "Quantidade de vezes que os jogadores podem morrer antes de perder")
Language:add(code, "Zombies in first Wave", "Zumbis na primeira onda")
Language:add(code, "Zombies that spawn in the first wave", "Zumbis que aparecem na primeira onda")
Language:add(code, "Additional Zombies per wave", "Zumbis adicionais por onda")
Language:add(code, "Zombies that are added in each new wave", "Zumbis que são adicionados a cada nova onda")
Language:add(code, "Additional Max Health per wave", "Vida máxima adicional por onda")
Language:add(code, "Zombies get more health each wave", "Zumbis ganham mais saúde a cada onda")
Language:add(code, "Additional Damage of Zombies per wave", "Dano Adicional de Zumbis por onda")
Language:add(code, "Zombies deal more damage each wave", "Zumbis causam mais dano a cada onda")
Language:add(code, "Additional Speed for Attack", "Velocidade Adicional para Ataque")
Language:add(code, "Zombies get more speed each wave", "Zumbis ganham mais velocidade a cada onda")
Language:add(code, "Additional High-Jump-Speed for Attack", "Velocidade adicional de salto alto para ataque")
Language:add(code, "Zombies get more speed each wave", "Zumbis ganham mais velocidade a cada onda")
Language:add(code, "Decrease spawn distance per wave", "Diminuir a distância de spawn por onda")
Language:add(code, "Decreases the spawn distance each wave. This can help sell the effect of a continuous wave when the server slot limit is reached", "Diminui a distância de spawn a cada onda. Isso pode ajudar a vender o efeito de uma onda contínua quando o limite de slot do servidor é atingido")
Language:add(code, "Zombies alive for next wave", "Zumbis vivos para a próxima onda")
Language:add(code, "New wave is triggered when this number of zombies is reached", "Nova onda é acionada quando esse número de zumbis é atingido")
Language:add(code, "Time between waves", "Tempo entre as ondas")
Language:add(code, "Time in seconds between two waves", "Tempo em segundos entre duas ondas")
Language:add(code, "kill remaining zombies after wave", "matar os zumbis restantes após a onda")
Language:add(code, "Remaining Bots Get Killed before a new wave starts", "Bots restantes são mortos antes do início de uma nova onda")
Language:add(code, "Bot min time Attack one player", "Tempo mínimo de bot Ataque um jogador")
Language:add(code, "The minimum time a bot attacks one player for", "O tempo mínimo que um bot ataca um jogador por")
Language:add(code, "Bot attack mode duration", "Duração do modo de ataque de bot")
Language:add(code, "The minimum time a zombie-bot tries to attack a player - recommended minimum 15,", "O tempo mínimo que um zumbi-bot tenta atacar um jogador - mínimo recomendado 15,")
Language:add(code, "Zombies Drop Nades", "Zumbis Drop Nades")
Language:add(code, "Zombies drop randomly nades", "Zumbis dropam nades aleatoriamente")
Language:add(code, "Use Zombie Classes", "Use classes de zumbis")
Language:add(code, "Zombie classes behave different", "As classes de zumbis se comportam de maneira diferente")
Language:add(code, "Bot Headshot DamageMultiplier", "Multiplicador de dano de tiro na cabeça do bot")
Language:add(code, "Bot Explosion DamageMultiplier", "Multiplicador de dano de explosão de bot")
Language:add(code, "Damage multiplier for explosions ", "Multiplicador de dano para explosões")
Language:add(code, "Max Shoot-Distance", "Distância máxima de tiro")
Language:add(code, "Meters before bots will start shooting at players", "Metros antes dos bots começarem a atirar nos jogadores")
Language:add(code, "Max Shoot-Height", "Altura máxima do tiro")
Language:add(code, "Maximum height when a bot is close. Will scale over distance and will be 0 at the MaxShootDistance", "Altura máxima quando um bot está próximo. Será dimensionado pela distância e será 0 no MaxShootDistance")

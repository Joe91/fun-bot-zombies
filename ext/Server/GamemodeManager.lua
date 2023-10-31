---@class GamemodeManager
---@overload fun():GamemodeManager
GamemodeManager = class('GamemodeManager')
---@type BotSpawner
local m_BotSpawner = require('BotSpawner')

---@type BotManager
local m_BotManager = require('BotManager')

local firstPlayerJoined = false

function GamemodeManager:OnExtensionLoaded()
	--RCON:SendCommand('vars.gameModeCounter', {tostring(1000)})
end

function GamemodeManager:OnLevelLoaded()
	firstPlayerJoined = false
end

function GamemodeManager:TeamChange(p_Player, p_TeamId, p_SquadId)
	if (firstPlayerJoined == false) then
		local maxTickets = RCON:SendCommand('vars.gameModeCounter')
		maxTickets = maxTickets[2]
		TicketManager:SetTicketCount(2, tonumber(maxTickets) - Config.PlayerLives)
		print("Team 1 tickets have been set to: " .. TicketManager:GetTicketCount(2))
		firstPlayerJoined = true
	end

	local waveData = {
		current = m_BotSpawner._CurrentSpawnWave,
		max = Config.Waves
	}
	NetEvents:Broadcast('FunBots:WaveCount', waveData)
end

function GamemodeManager:OnPlayedKilled(p_Player)
	--Should be a better way of doing this but I'm lazy :)
	--Prevents the human team from getting too many tickets
	if (p_Player.teamId == 2) then
		TicketManager:SetTicketCount(1, 0)
		--g_BotSpawner._BotsLeftInCurrentWave = g_BotSpawner._BotsLeftInCurrentWave - 1


		if ((g_BotSpawner._BotsToSpawnInWave - Globals.MaxPlayers) - 1) - g_BotSpawner._SpawnedBotsInCurrentWave > 0 then
			g_BotSpawner._SpawnedBotsInCurrentWave = g_BotSpawner._SpawnedBotsInCurrentWave + 1
			--print(tostring(g_BotSpawner._BotsToSpawnInWave - g_BotSpawner._SpawnedBotsInCurrentWave))
			if Globals.RespawnWayBots == false then
				Globals.RespawnWayBots = true
				for index, bot in ipairs(m_BotManager._Bots) do
					bot._Respawning = Globals.RespawnWayBots
				end
			end
		elseif Globals.RespawnWayBots == true and ((g_BotSpawner._BotsToSpawnInWave - Globals.MaxPlayers) - 1) - g_BotSpawner._SpawnedBotsInCurrentWave < 1 then
			Globals.RespawnWayBots = false
			for index, bot in ipairs(m_BotManager._Bots) do
				bot._Respawning = Globals.RespawnWayBots
			end
		end
	end
end

function GamemodeManager:HumanTeamWin()
	TicketManager:SetTicketCount(1, 1000)
end

if g_GamemodeManager == nil then
	---@type GamemodeManager
	g_GamemodeManager = GamemodeManager()
end

return g_GamemodeManager

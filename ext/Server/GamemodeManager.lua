---@class GamemodeManager
---@overload fun():GamemodeManager
GamemodeManager = class('GamemodeManager')

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
    
end

function GamemodeManager:OnPlayedKilled(p_Player)
    --Should be a better way of doing this but I'm lazy :)
    --Prevents the human team from getting too many tickets
    if(p_Player.teamId == Config.BotTeam) then
        TicketManager:SetTicketCount(1, 0)
        if ((g_BotSpawner._BotsToSpawnInWave - Globals.MaxPlayers) - 1) - g_BotSpawner._SpawnedBotsInCurrentWave > 0 then
            g_BotSpawner._SpawnedBotsInCurrentWave = g_BotSpawner._SpawnedBotsInCurrentWave + 1
            if Globals.RespawnWayBots == false then
                Globals.RespawnWayBots = true
                for index, bot in ipairs(m_BotManager._Bots) do
                    bot._Respawning = Globals.RespawnWayBots
                end
                print("Enabled respawning!")
            end
        elseif Globals.RespawnWayBots == true and ((g_BotSpawner._BotsToSpawnInWave - Globals.MaxPlayers) - 1) - g_BotSpawner._SpawnedBotsInCurrentWave < 1 then
            Globals.RespawnWayBots = false
            for index, bot in ipairs(m_BotManager._Bots) do
                bot._Respawning = Globals.RespawnWayBots
            end
            print("Disabled respawning!")
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
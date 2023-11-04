---@class BotManager
---@overload fun():BotManager
BotManager = class('BotManager')

require('Bot')

---@type Utilities
local m_Utilities = require('__shared/Utilities')
local m_Vehicles = require("Vehicles")
---@type Logger
local m_Logger = Logger("BotManager", Debug.Server.BOT)

local bp = nil
local killedPlayers = {}

function BotManager:__init()
	---@type Bot[]
	self._Bots = {}
	---@type table<string, Bot>
	---`[Player.name] -> Bot`
	self._BotsByName = {}
	---@type table<integer, Bot[]>
	self._BotsByTeam = { {}, {}, {}, {}, {} } -- neutral, team1, team2, team3, team4
	---@type table<integer, EntryInput>
	---`[Player.id] -> EntryInput`
	self._BotInputs = {}
	---@type string[]
	---`playerName:string[]`
	self._ActivePlayers = {}
	self._BotAttackBotTimer = 0.0
	self._DestroyBotsTimer = 0.0
	---@type string[]
	---`BotName[]`
	self._BotsToDestroy = {}

	---@type string[]
	---`BotName[]`
	self._BotBotAttackList = {}
	self._RaycastsPerActivePlayer = 0
	---@type table<string, boolean>
	---`[BotName] -> boolean`
	self._BotCheckState = {}

	---@type table<string, boolean>
	---`[botPlayer.id .. "-" .. enemyBotPlayer.id] -> boolean`
	self._ConnectionCheckState = {}

	self._LastBotCheckIndex = 1
	self._LastPlayerCheckIndex = 1
	self._InitDone = false
	self._shooterBots = {}

	Events:Subscribe('ServerDamagePlayer', self, self._onServerDamagePlayer)
	Hooks:Install('Soldier:Damage', 100, self, self._onSoldierDamage)
end

-- =============================================
-- Events
-- =============================================

---VEXT Shared Level:Destroy Event
function BotManager:OnLevelDestroy()
	m_Logger:Write("destroyLevel")

	self:ResetAllBots()
	self._ActivePlayers = {}
	self._InitDone = false
	bp = nil
end

---VEXT Shared UpdateManager:Update Event
---@param p_DeltaTime number
---@param p_UpdatePass UpdatePass|integer
function BotManager:OnUpdateManagerUpdate(p_DeltaTime, p_UpdatePass)
	if p_UpdatePass ~= UpdatePass.UpdatePass_PostFrame then
		return
	end

	for _, l_Bot in pairs(self._Bots) do
		l_Bot:OnUpdatePassPostFrame(p_DeltaTime)
	end

	if #self._BotsToDestroy > 0 then
		if self._DestroyBotsTimer >= 0.005 then
			self._DestroyBotsTimer = 0.0
			self:DestroyBot(table.remove(self._BotsToDestroy))
		end

		self._DestroyBotsTimer = self._DestroyBotsTimer + p_DeltaTime
	end
end

function BotManager:_onServerDamagePlayer(playerName, shooterName, damage)
	-- melee attack
	local player = PlayerManager:GetPlayerByName(playerName)
	local bot = self:GetBotByName(shooterName)
	if player == nil or not player.alive or bot == nil or player.soldier == nil or bot.m_Player.soldier == ni then return end
	if player.teamId == bot.m_Player.teamId then return end
	if player.soldier.worldTransform.trans:Distance(bot.m_Player.soldier.worldTransform.trans) > 2 then return end

	self._shooterBots[player.name] = shooterName
	player.soldier.health = player.soldier.health - damage
end

function BotManager:_onSoldierDamage(hook, soldier, info, giverInfo)
	-- soldier -> soldier damage only
	if soldier.player == nil then
		return
	end

	local soldierIsBot = Utilities:isBot(soldier.player.name);

	if not soldierIsBot then
		if giverInfo.giver == nil then
			local bot = self:GetBotByName(self._shooterBots[soldier.player.name])
			if bot ~= nil and bot.m_Player.soldier ~= nil then
				info.damage = Config.DamageFactorKnife * 100
				info.boneIndex = 0;
				info.isBulletDamage = true;
				info.position = Vec3(soldier.worldTransform.trans.x, soldier.worldTransform.trans.y + 1, soldier.worldTransform.trans.z)
				info.direction = soldier.worldTransform.trans - bot.m_Player.soldier.worldTransform.trans
				info.origin = bot.m_Player.soldier.worldTransform.trans
				if (soldier.health - info.damage) <= 0 and killedPlayers[soldier.player.name] ~= true then
					TicketManager:SetTicketCount(bot.m_Player.teamId, TicketManager:GetTicketCount(bot.m_Player.teamId) + 1)
					killedPlayers[soldier.player.name] = true
				end
			end
		else
			--valid bot-damage?
			local bot = self:GetBotByName(giverInfo.giver.name)
			if bot ~= nil and bot.m_Player.soldier ~= nil then
				-- giver was a bot (with explosives)
				info.damage = self:_GetDamageValue(info.damage, bot, soldier);
			end
		end
	end

	hook:Pass(soldier, info, giverInfo)
end

Events:Subscribe('Player:ReviveAccepted', function(player, reviver)
	if killedPlayers[player.name] == true then
		TicketManager:SetTicketCount(2, TicketManager:GetTicketCount(2) - 1)
		killedPlayers[player.name] = false
	end
end)

Events:Subscribe('Player:Respawn', function(player)
	killedPlayers[player.name] = false
end)

Events:Subscribe('Level:Loaded', function(levelName, gameMode, round, roundsPerMap)
	bp = ResourceManager:SearchForDataContainer('Weapons/Gadgets/Ammobag/Ammobag_Projectile')
end)

---VEXT Server Player:Killed Event
--  + (Config.IncrementAmmoDropChancePerWave * m_BotSpawner._CurrentSpawnWave)
function BotManager:OnPlayerKilled(p_Player)
	if not m_Utilities:isBot(p_Player) then
		return
	end


	local s_Bot = self:GetBotByName(p_Player.name)
	local bp = nil

	if Config.UseZombieClasses then
		local s_RandomValue = MathUtils:GetRandomInt(1, 100)
		-- supports drop nades, other bots drop ammo
		if s_Bot and s_Bot.m_Kit == Config.ClassExploder then
			if not Config.ZombiesDropNades or s_RandomValue > Globals.NadeDropChance then
				return
			end
			bp = ResourceManager:SearchForDataContainer('Weapons/M67/M67_Projectile')
		else
			if not Config.ZombiesDropAmmo or s_RandomValue > Globals.AmmoDropChance then
				return
			end
			bp = ResourceManager:SearchForDataContainer('Weapons/Gadgets/Ammobag/Ammobag_Projectile')
		end
	else
		-- every bot can drop a nade or ammo
		if Config.ZombiesDropAmmo and (MathUtils:GetRandomInt(1, 100) < Globals.AmmoDropChance) then
			bp = ResourceManager:SearchForDataContainer('Weapons/Gadgets/Ammobag/Ammobag_Projectile')
		elseif Config.ZombiesDropNades and (MathUtils:GetRandomInt(1, 100) < Globals.NadeDropChance) then
			bp = ResourceManager:SearchForDataContainer('Weapons/M67/M67_Projectile')
		else
			return
		end
	end

	if bp == nil then
		return
	end

	local creationParams = EntityCreationParams()
	creationParams.transform = LinearTransform()
	creationParams.networked = true
	creationParams.transform.trans = p_Player.soldier.transform.trans:Clone()

	local createdBus = EntityManager:CreateEntitiesFromBlueprint(bp, creationParams)
	if createdBus == nil then
		return
	end

	for _, entity in pairs(createdBus.entities) do
		entity:Init(Realm.Realm_ClientAndServer, true)
	end
end

---@param p_Player Player
function BotManager:OnPlayerLeft(p_Player)
	-- Remove all references of player.
	for _, l_Bot in pairs(self._Bots) do
		l_Bot:ClearPlayer(p_Player)
	end

	for l_Index, l_PlayerName in pairs(self._ActivePlayers) do
		if l_PlayerName == p_Player.name then
			table.remove(self._ActivePlayers, l_Index)
			break
		end
	end

	-- Check if player used a Bot-Name.
	if Registry.COMMON.ALLOW_PLAYER_BOT_NAMES then
		for l_Index, l_BotNameToIgnore in pairs(Globals.IgnoreBotNames) do
			if l_BotNameToIgnore == p_Player.name then
				table.remove(Globals.IgnoreBotNames, l_Index)
				m_Logger:Write("Bot-Name " .. l_BotNameToIgnore .. " usable again")
			end
		end
	end
end

-- =============================================
-- Hooks
-- =============================================

---VEXT Server Soldier:Damage Hook
---@param p_HookCtx HookContext
---@param p_Soldier SoldierEntity
---@param p_Info DamageInfo
---@param p_GiverInfo DamageGiverInfo|nil
function BotManager:OnSoldierDamage(p_HookCtx, p_Soldier, p_Info, p_GiverInfo)
	-- Soldier → soldier damage only.

	-- Ignore if there is no player for this soldier.
	if not p_Soldier.player then
		return
	end

	-- Ignore healing.
	if p_Info.damage <= 0.0 then
		return
	end

	if p_Soldier.player.teamId == 2 then
		if p_Info.isExplosionDamage then
			p_Info.damage = p_Info.damage * Config.BotExplosionDamageMultiplier
		else
			if p_Info.boneIndex == 1 then -- headshot
				p_Info.damage = p_Info.damage * Config.BotHeadshotDamageMultiplier -- headshot multiplier is 2x by default
			else
				p_Info.damage = p_Info.damage * Config.BotBodyshotDamageMultiplier
			end
		end

		local s_Bot = self:GetBotByName(p_Soldier.player.name)
		if s_Bot then
			local s_NewSpeed = MathUtils:Clamp(s_Bot._SpeedValue * (p_Soldier.health / p_Soldier.maxHealth), Registry.ZOMBIES.MIN_MOVE_SPEED * 3, s_Bot._SpeedValue)
			s_Bot._SpeedFactorAttack = s_NewSpeed
			s_Bot._SpeedValue = s_NewSpeed
		end
	elseif (p_Soldier.player.teamId == 1) then
		if (p_Info.isExplosionDamage) then
			p_Info.damage = p_Info.damage * 0.5
		end
	end


	-- This is a bot.
	if m_Utilities:isBot(p_Soldier.player) then
		if p_GiverInfo and p_GiverInfo.giver then
			-- Detect if we need to shoot back.
			if Config.ShootBackIfHit then
				self:OnShootAt(p_GiverInfo.giver, p_Soldier.player.name, false)
			end

			-- Prevent bots from killing themselves. Bad bot, no suicide.
			if not Config.BotCanKillHimself and p_Soldier.player == p_GiverInfo.giver then
				p_Info.damage = 0.0
			end
		end
		-- This is a real player; check if the damage was dealt by a bot.
	else
		-- We have a giver.
		if p_GiverInfo and p_GiverInfo.giver then
			local s_Bot = self:GetBotByName(p_GiverInfo.giver.name)

			-- This damage was dealt by a bot.
			if s_Bot and s_Bot.m_Player.soldier then
				-- Update the bot damage with the multipliers from the config.
				p_Info.damage = (Config.DamageFactorKnife * 100) - 1
			end
		end
	end

	-- Pass everything, modified or not.
	p_HookCtx:Pass(p_Soldier, p_Info, p_GiverInfo)
end

-- =============================================
-- Custom (Net-)Events
-- =============================================

---@param p_Player Player
---@param p_BotName string
---@param p_IgnoreYaw boolean
function BotManager:OnShootAt(p_Player, p_BotName, p_IgnoreYaw)
	local s_Bot = self:GetBotByName(p_BotName)

	if not s_Bot then
		return
	end

	s_Bot:ShootAt(p_Player, p_IgnoreYaw)
end

---@param p_Player Player
---@param p_BotName string
function BotManager:OnRevivePlayer(p_Player, p_BotName)
	local s_Bot = self:GetBotByName(p_BotName)

	if not s_Bot then
		return
	end

	s_Bot:Revive(p_Player)
end

---@param p_Player Player
---@param p_BotName1 string
---@param p_BotName2 string
function BotManager:OnBotShootAtBot(p_Player, p_BotName1, p_BotName2)
	local s_Bot1 = self:GetBotByName(p_BotName1)

	if not s_Bot1 then
		return
	end

	local s_Bot2 = self:GetBotByName(p_BotName2)

	if not s_Bot2 then
		return
	end

	if s_Bot1:ShootAt(s_Bot2.m_Player, false) then
		self._BotCheckState[s_Bot1.m_Player.name] = true
	end

	if s_Bot2:ShootAt(s_Bot1.m_Player, false) then
		self._BotCheckState[s_Bot2.m_Player.name] = true
	end
end

---@param p_MissileEntity Entity
function BotManager:CheckForFlareOrSmoke(p_MissileEntity)
	p_MissileEntity = SpatialEntity(p_MissileEntity)

	local s_MissileTransform = p_MissileEntity.transform
	local s_MissilePosition = s_MissileTransform.trans

	local s_SmallestAngle = 1.0
	local s_DriverOfVehicle = nil

	local s_Iterator = EntityManager:GetIterator("ServerVehicleEntity")
	local s_Entity = s_Iterator:Next()
	while s_Entity ~= nil do
		s_Entity = ControllableEntity(s_Entity)
		local s_DriverPlayer = s_Entity:GetPlayerInEntry(0)
		if s_DriverPlayer then
			local s_PositionVehicle = s_Entity.transform.trans
			local s_VecMissile = (s_PositionVehicle - s_MissilePosition):Normalize()

			local s_Angle = math.acos(s_VecMissile:Dot(s_MissileTransform.forward))
			local s_Distance = s_PositionVehicle:Distance(s_MissilePosition)

			if s_Angle < s_SmallestAngle and s_Distance < 350 then
				s_SmallestAngle = s_Angle
				s_DriverOfVehicle = s_DriverPlayer
			end
		end

		s_Entity = s_Iterator:Next()
	end

	if not s_DriverOfVehicle then
		return
	end

	local s_TargetBot = self:GetBotByName(s_DriverOfVehicle.name)
	if s_TargetBot then
		s_TargetBot:FireFlareSmoke()
	end
end

function BotManager:OnClientRaycastResults(p_Player, p_RaycastResults)
	if p_RaycastResults == nil then
		return
	end

	for _, l_RaycastResult in ipairs(p_RaycastResults) do
		if l_RaycastResult.Mode == "ShootAtBot" then
			self:OnBotShootAtBot(p_Player, l_RaycastResult.Bot1, l_RaycastResult.Bot2)
		elseif l_RaycastResult.Mode == "ShootAtPlayer" then
			self:OnShootAt(p_Player, l_RaycastResult.Bot1, true)
		elseif l_RaycastResult.Mode == "RevivePlayer" then
			self:OnRevivePlayer(p_Player, l_RaycastResult.Bot1)
		end
	end
end

---@param p_Player Player
---@param p_BotName string
function BotManager:OnRequestEnterVehicle(p_Player, p_BotName)
	local s_Bot = self:GetBotByName(p_BotName)

	if s_Bot and s_Bot.m_Player.soldier then
		s_Bot:EnterVehicleOfPlayer(p_Player)
	end
end

---@param p_Player Player
---@param p_SeatNumber integer
function BotManager:OnRequestChangeSeatVehicle(p_Player, p_SeatNumber)
	local s_TargetEntryId = p_SeatNumber - 1
	local s_VehicleEntity = p_Player.controlledControllable

	if s_VehicleEntity and s_VehicleEntity.typeInfo.name == "ServerSoldierEntity" then
		s_VehicleEntity = p_Player.attachedControllable
	end

	-- No vehicle found.
	if not s_VehicleEntity then
		return
	end

	-- Player in target seat.
	local s_TargetPlayer = s_VehicleEntity:GetPlayerInEntry(s_TargetEntryId)

	-- No player in target seat.
	if not s_TargetPlayer then
		return
	end

	local s_Bot = self:GetBotByName(s_TargetPlayer.name)

	-- Real player in target seat.
	if not s_Bot then
		return
	end

	-- Exit vehicle with bot, so the real player can get this seat.
	s_Bot:AbortAttack()
	s_Bot.m_Player:ExitVehicle(false, false)
	p_Player:EnterVehicle(s_VehicleEntity, s_TargetEntryId)

	-- Find next free seat and re-enter with the bot if possible.
	for i = 0, s_VehicleEntity.entryCount - 1 do
		if s_VehicleEntity:GetPlayerInEntry(i) == nil then
			s_Bot.m_Player:EnterVehicle(s_VehicleEntity, i)
			s_Bot:UpdateVehicleMovableId()
			break
		end
	end
end

-- =============================================
-- Functions
-- =============================================

-- =============================================
-- Public Functions
-- =============================================

---@param p_Player Player
function BotManager:RegisterActivePlayer(p_Player)
	-- Check if the player is already listed
	for _, l_PlayerName in ipairs(self._ActivePlayers) do
		if l_PlayerName == p_Player.name then
			return
		end
	end

	-- Not listed, add to the list.
	table.insert(self._ActivePlayers, p_Player.name)
end

---Returns the teamId for the team that has the most real players
---@return TeamId
function BotManager:GetPlayerTeam()
	--- Count real players for each team
	---@type table<TeamId, integer>
	local s_CountPlayers = {}

	for l_TeamId = TeamId.Team1, Globals.NrOfTeams do
		---@cast l_TeamId TeamId

		s_CountPlayers[l_TeamId] = 0
		local s_Players = PlayerManager:GetPlayersByTeam(l_TeamId)

		for l_Index = 1, #s_Players do
			if not m_Utilities:isBot(s_Players[l_Index]) then
				s_CountPlayers[l_TeamId] = s_CountPlayers[l_TeamId] + 1
			end
		end
	end

	-- Get the team with the highest real-player count.
	---@type TeamId
	local s_PlayerTeam = TeamId.Team1

	for l_TeamId = TeamId.Team2, Globals.NrOfTeams do
		---@cast l_TeamId TeamId
		if s_CountPlayers[l_TeamId] > s_CountPlayers[s_PlayerTeam] then
			s_PlayerTeam = l_TeamId
		end
	end

	return s_PlayerTeam
end

---@return TeamId
function BotManager:GetBotTeam()
	if Config.BotTeam ~= TeamId.TeamNeutral then
		return Config.BotTeam
	end

	--- Count bot players for each team.
	---@type table<TeamId, integer>
	local s_CountPlayers = {}

	for l_TeamId = TeamId.Team1, Globals.NrOfTeams do
		---@cast l_TeamId TeamId
		s_CountPlayers[l_TeamId] = 0
		local s_Players = PlayerManager:GetPlayersByTeam(l_TeamId)

		for l_Index = 1, #s_Players do
			if not m_Utilities:isBot(s_Players[l_Index]) then
				s_CountPlayers[l_TeamId] = s_CountPlayers[l_TeamId] + 1
			end
		end
	end

	-- Get the team with the lowest bot-player count.
	---@type TeamId
	local s_BotTeam = TeamId.Team1

	for l_TeamId = TeamId.Team2, Globals.NrOfTeams do
		---@cast l_TeamId TeamId
		if s_CountPlayers[l_TeamId] < s_CountPlayers[s_BotTeam] then
			s_BotTeam = l_TeamId
		end
	end

	return s_BotTeam
end

function BotManager:ConfigGlobals()
	Globals.RespawnWayBots = Config.RespawnWayBots
	Globals.AttackWayBots = Config.AttackWayBots
	Globals.SpawnMode = Config.SpawnMode
	Globals.YawPerFrame = self:CalcYawPerFrame()

	local s_MaxPlayersRCON = RCON:SendCommand('vars.maxPlayers')
	local s_MaxPlayers = tonumber(s_MaxPlayersRCON[2])

	if s_MaxPlayers and s_MaxPlayers > 0 then
		Globals.MaxPlayers = s_MaxPlayers
		m_Logger:Write("there are " .. s_MaxPlayers .. " slots on this server")
	else
		-- Only fallback. Should not happen.
		Globals.MaxPlayers = 127
		m_Logger:Error("No Playercount found")
	end

	-- Calculate Raycast per Player.
	local s_FactorTicksUpdate = Registry.GAME_RAYCASTING.BOT_BOT_CHECK_INTERVAL * SharedUtils:GetTickrate()
	local s_RaycastsMax = s_FactorTicksUpdate * (Registry.GAME_RAYCASTING.MAX_RAYCASTS_PER_PLAYER_BOT_BOT)
	-- Always round down one.
	self._RaycastsPerActivePlayer = math.floor(s_RaycastsMax - 0.1)

	self._InitDone = true
end

---@return number
function BotManager:CalcYawPerFrame()
	local s_DegreePerDeltaTime = Config.MaximunYawPerSec / SharedUtils:GetTickrate()
	return (s_DegreePerDeltaTime / 360.0) * 2 * math.pi
end

---@return string|nil
function BotManager:FindNextBotName()
	for _, l_Name in ipairs(BotNames) do
		local s_Name = Registry.COMMON.BOT_TOKEN .. l_Name
		local s_SkipName = false

		for _, l_IgnoreName in ipairs(Globals.IgnoreBotNames) do
			if s_Name == l_IgnoreName then
				s_SkipName = true
				break
			end
		end

		if not s_SkipName then
			local s_Bot = self:GetBotByName(s_Name)

			if not s_Bot and not PlayerManager:GetPlayerByName(s_Name) then
				return s_Name
			elseif s_Bot and not s_Bot.m_Player.soldier and s_Bot:GetSpawnMode() ~= BotSpawnModes.RespawnRandomPath then
				return s_Name
			end
		end
	end

	return nil
end

---@param p_TeamId? TeamId
---@return Bot[]
function BotManager:GetBots(p_TeamId)
	if p_TeamId ~= nil then
		return self._BotsByTeam[p_TeamId + 1]
	else
		return self._Bots
	end
end

function BotManager:GetAliveBots(p_TeamId)
	local s_Bots = {}

	for _, l_Bot in ipairs(self._Bots) do
		if l_Bot.m_Player.soldier then
			if p_TeamId == nil or l_Bot.m_Player.teamId == p_TeamId then
				table.insert(s_Bots, l_Bot)
			end
		end
	end

	return s_Bots
end

---@return integer
function BotManager:GetBotCount()
	return #self._Bots
end

---@param p_TeamId? TeamId
---@return integer
function BotManager:GetActiveBotCount(p_TeamId)
	local s_Count = 0

	for _, l_Bot in ipairs(self._Bots) do
		if not l_Bot:IsInactive() then
			if p_TeamId == nil or l_Bot.m_Player.teamId == p_TeamId then
				s_Count = s_Count + 1
			end
		end
	end

	return s_Count
end

function BotManager:GetAliveBotCount(p_TeamId)
	local s_Count = 0

	for _, l_Bot in ipairs(self._Bots) do
		if l_Bot.m_Player.soldier then
			if p_TeamId == nil or l_Bot.m_Player.teamId == p_TeamId then
				s_Count = s_Count + 1
			end
		end
	end

	return s_Count
end

-- Returns all real players.
---@return Player[]
function BotManager:GetPlayers()
	local s_AllPlayers = PlayerManager:GetPlayers()
	local s_Players = {}

	for i = 1, #s_AllPlayers do
		if not m_Utilities:isBot(s_AllPlayers[i]) then
			table.insert(s_Players, s_AllPlayers[i])
		end
	end

	return s_Players
end

---Returns real player count
---@return integer
function BotManager:GetPlayerCount()
	return PlayerManager:GetPlayerCount() - #self._Bots
end

---Get the amount of bots using this kit
---@param p_Kit BotKits
---@return integer
function BotManager:GetKitCount(p_Kit)
	local s_Count = 0

	for _, l_Bot in ipairs(self._Bots) do
		if l_Bot.m_Kit == p_Kit then
			s_Count = s_Count + 1
		end
	end

	return s_Count
end

---@param p_Player Player
---@param p_Option string|'"mode"'|'"speed"'
---@param p_Value BotMoveModes|BotMoveSpeeds
function BotManager:SetStaticOption(p_Player, p_Option, p_Value)
	for _, l_Bot in ipairs(self._Bots) do
		if l_Bot:GetTargetPlayer() == p_Player then
			if l_Bot:IsStaticMovement() then
				if p_Option == "mode" then
					---@cast p_Value BotMoveModes
					l_Bot:SetMoveMode(p_Value)
				end
			end
		end
	end
end

---@param p_Option string|'"shoot"'|'"respawn"'|'"moveMode"'
---@param p_Value boolean|BotMoveModes
function BotManager:SetOptionForAll(p_Option, p_Value)
	for _, l_Bot in pairs(self._Bots) do
		if p_Option == "shoot" then
			---@cast p_Value boolean
			l_Bot:SetShoot(p_Value)
		elseif p_Option == "respawn" then
			---@cast p_Value boolean
			l_Bot:SetRespawn(p_Value)
		elseif p_Option == "moveMode" then
			---@cast p_Value BotMoveModes
			l_Bot:SetMoveMode(p_Value)
		end
	end
end

---@param p_Player Player
---@param p_Option string|'"shoot"'|'"respawn"'|'"moveMode"'
---@param p_Value boolean|BotMoveModes
function BotManager:SetOptionForPlayer(p_Player, p_Option, p_Value)
	for _, l_Bot in pairs(self._Bots) do
		if l_Bot:GetTargetPlayer() == p_Player then
			if p_Option == "shoot" then
				---@cast p_Value boolean
				l_Bot:SetShoot(p_Value)
			elseif p_Option == "respawn" then
				---@cast p_Value boolean
				l_Bot:SetRespawn(p_Value)
			elseif p_Option == "moveMode" then
				---@cast p_Value BotMoveModes
				l_Bot:SetMoveMode(p_Value)
			end
		end
	end
end

---@param p_Name string
---@return Bot|nil
function BotManager:GetBotByName(p_Name)
	return self._BotsByName[p_Name]
end

---@param p_Name string
---@param p_TeamId TeamId
---@param p_SquadId SquadId
---@return Bot|nil
function BotManager:CreateBot(p_Name, p_TeamId, p_SquadId)
	-- m_Logger:Write('botsByTeam['..#self._BotsByTeam[2]..'|'..#self._BotsByTeam[3]..']')

	local s_Bot = self:GetBotByName(p_Name)

	-- Bot exists, so just reset him.
	if s_Bot ~= nil then
		s_Bot.m_Player.teamId = p_TeamId
		s_Bot.m_Player.squadId = p_SquadId
		s_Bot:ResetVars()
		return s_Bot
	end

	-- Check for max-players.
	local s_PlayerLimit = Globals.MaxPlayers

	if Config.KeepOneSlotForPlayers then
		s_PlayerLimit = s_PlayerLimit - 1
	end

	if s_PlayerLimit <= PlayerManager:GetPlayerCount() then
		m_Logger:Write("playerlimit reached")
		return nil
	end

	-- Create a player for this bot.
	local s_BotPlayer = PlayerManager:CreatePlayer(p_Name, p_TeamId, p_SquadId)

	if s_BotPlayer == nil then
		m_Logger:Write("can't create more players on this team")
		return nil
	end

	-- Create input for this bot.
	local s_BotInput = EntryInput()
	s_BotInput.deltaTime = 1.0 / SharedUtils:GetTickrate()
	s_BotInput.flags = EntryInputFlags.AuthoritativeAiming
	s_BotPlayer.input = s_BotInput

	---@type Bot
	s_Bot = Bot(s_BotPlayer)

	table.insert(self._Bots, s_Bot)
	self._BotsByName[p_Name] = s_Bot

	-- Teamid's in self._BotsByTeam are offset by 1.
	local s_TeamLookup = s_Bot.m_Player.teamId + 1
	self._BotsByTeam[s_TeamLookup] = self._BotsByTeam[s_TeamLookup] or {}
	table.insert(self._BotsByTeam[s_TeamLookup], s_Bot)

	-- Bot inputs are stored to prevent garbage collection.
	self._BotInputs[s_BotPlayer.id] = s_BotInput
	return s_Bot
end

---@param p_Bot Bot
---@param p_Transform LinearTransform
---@param p_Pose CharacterPoseType
function BotManager:SpawnBot(p_Bot, p_Transform, p_Pose)
	local s_BotPlayer = p_Bot.m_Player

	-- if s_BotPlayer.soldier ~= nil then
	-- 	s_BotPlayer.soldier:Destroy()
	-- end

	-- if s_BotPlayer.corpse ~= nil then
	-- 	s_BotPlayer.corpse:Destroy()
	-- end

	-- Returns SoldierEntity.
	local s_BotSoldier = s_BotPlayer:CreateSoldier(s_BotPlayer.selectedKit, p_Transform)

	if not s_BotSoldier then
		m_Logger:Error("CreateSoldier failed")
		return nil
	end

	local maxHealthValue = Config.BotMaxHealth
	local minHealthValue = Config.BotMinHealth

	if Globals.SpawnMode == SpawnModes.wave_spawn then
		maxHealthValue = Globals.MaxHealthValue
		minHealthValue = Globals.MinHealthValue
	end

	-- Customization of health of bot.
	local s_RandomValueOfBot = MathUtils:GetRandom(0.0, 1.0)
	p_Bot._RandomValueOfBot = s_RandomValueOfBot

	if Config.UseZombieClasses then
		-- only assault-bots use the max health
		if p_Bot.m_Kit == Config.ClassTank then
			s_BotSoldier.maxHealth = maxHealthValue
		elseif p_Bot.m_Kit == Config.ClassSprinter then
			s_BotSoldier.maxHealth = minHealthValue
		else
			s_BotSoldier.maxHealth = (maxHealthValue + minHealthValue) / 2 --Set to the average
		end
	else
		-- randmod values of all bots or the same for all
		if Config.RandomHealthOfZombies then
			s_BotSoldier.maxHealth = minHealthValue + (s_RandomValueOfBot * (maxHealthValue - minHealthValue))
		else
			s_BotSoldier.maxHealth = maxHealthValue
		end
	end

	if s_BotSoldier.health < s_BotSoldier.maxHealth then
		table.insert(g_BotSpawner._SoldiersToApplyHealthTo, s_BotSoldier)
	end


	s_BotPlayer:SpawnSoldierAt(s_BotSoldier, p_Transform, p_Pose)
	s_BotPlayer:AttachSoldier(s_BotSoldier)

	-- Set Bot-Vars
	p_Bot._GoForDirectAttackIfClose = (MathUtils:GetRandomInt(1, 100) <= Registry.ZOMBIES.PROBABILITY_GO_FOR_DIRECT_ATTACK)

	p_Bot._FollowTargetPose = MathUtils:GetRandom(0, 100) < 20

	-- Walk-Speed
	local s_MinSpeedWalk = Registry.ZOMBIES.MIN_MOVE_SPEED
	local s_MaxSpeedWalk = Registry.ZOMBIES.MAX_MOVE_SPEED
	p_Bot._SpeedFactorMovement = s_MinSpeedWalk + (s_RandomValueOfBot * (s_MaxSpeedWalk - s_MinSpeedWalk))

	-- Zombie-Move-Mode: evaluate all possible options
	local s_MoveModes = {}
	if Config.ZombiesProne then
		for l_WeightNumber = 1, Registry.ZOMBIES.WEIGHT_PRONE do
			table.insert(s_MoveModes, BotMoveSpeeds.VerySlowProne)
		end
	end
	if Config.ZombiesCrouch then
		for l_WeightNumber = 1, Registry.ZOMBIES.WEIGHT_CROUCH do
			table.insert(s_MoveModes, BotMoveSpeeds.SlowCrouch)
		end
	end
	if Config.ZombiesWalk then
		for l_WeightNumber = 1, Registry.ZOMBIES.WEIGHT_WALK do
			table.insert(s_MoveModes, BotMoveSpeeds.Normal)
		end
	end
	if Config.ZombiesSprint then
		for l_WeightNumber = 1, Registry.ZOMBIES.WEIGHT_SPRINT do
			table.insert(s_MoveModes, BotMoveSpeeds.Sprint)
		end
	end

	if #s_MoveModes > 0 then
		local s_TargetValue = math.floor((s_RandomValueOfBot * #s_MoveModes) + 1.0)
		if s_TargetValue > #s_MoveModes then
			s_TargetValue = #s_MoveModes
		end
		p_Bot._ZombieSpeedValue = s_MoveModes[s_TargetValue]
	else
		p_Bot._ZombieSpeedValue = BotMoveSpeeds.Normal
	end

	local s_MaxJumpValue = Config.MaxHighJumpSpeed
	local s_MinJumpValue = Config.MinHighJumpSpeed
	if Globals.SpawnMode == SpawnModes.wave_spawn then
		s_MaxJumpValue = Globals.MaxJumpSpeedValue
		s_MinJumpValue = Globals.MinJumpSpeedValue
	end

	if Config.UseZombieClasses then
		-- Sprinters can jump high
		if p_Bot.m_Kit == Config.ClassSprinter then
			p_Bot._HighJumpSpeed = s_MaxJumpValue
		elseif p_Bot.m_Kit == Config.ClassTank then
			p_Bot._HighJumpSpeed = s_MinJumpValue
		else
			p_Bot._HighJumpSpeed = (s_MaxJumpValue + s_MinJumpValue) / 2 --Set to the average
		end
	else
		-- every bot same values or random-values
		if Config.RandomJumpSpeedOfZombies then
			p_Bot._HighJumpSpeed = s_MinJumpValue + (s_RandomValueOfBot * (s_MaxJumpValue - s_MinJumpValue))
		else
			p_Bot._HighJumpSpeed = s_MaxJumpValue
		end
	end

	local s_SpeedValue = 0.0
	local s_MaxSpeedValue = Config.SpeedFactorAttack
	local s_MinSpeedValue = Config.MinSpeedFactorAttack
	if Globals.SpawnMode == SpawnModes.wave_spawn then
		s_MaxSpeedValue = Globals.MaxSpeedAttackValue
		s_MinSpeedValue = Globals.MinSpeedAttackValue
	end

	if Config.UseZombieClasses then
		-- Recons can sprint faster
		if p_Bot.m_Kit == Config.ClassSprinter then
			p_Bot._SpeedFactorAttack = s_MaxSpeedValue
			p_Bot._SpeedValue = s_MaxSpeedValue
		elseif p_Bot.m_Kit == Config.ClassTank then
			p_Bot._SpeedFactorAttack = s_MinSpeedValue
			p_Bot._SpeedValue = s_MinSpeedValue
		else
			p_Bot._SpeedFactorAttack = (s_MaxSpeedValue + s_MinSpeedValue) / 2 --Set to the average
			p_Bot._SpeedValue = (s_MaxSpeedValue + s_MinSpeedValue) / 2 --Set to the average
		end
	else
		if Config.RandomAttackSpeedOfZombies then
			s_SpeedValue = s_MinSpeedValue + (s_RandomValueOfBot * (s_MaxSpeedValue - s_MinSpeedValue))
		else
			s_SpeedValue = s_MaxSpeedValue
		end
		p_Bot._SpeedFactorAttack = s_SpeedValue
		p_Bot._SpeedValue = s_SpeedValue
	end

	if s_SpeedValue < 1.0 then
		s_SpeedValue = 1.0 -- default sprint behaviour, don't sptint later
	end

	local s_EntityIterator = EntityManager:GetIterator('PropertyCastEntity')
	local s_Entity = s_EntityIterator:Next()
	while s_Entity do
		if s_Entity.data and s_Entity.data.instanceGuid == Guid("51A231A1-CCBA-3DEF-1E3B-A28F5AE67188") and s_Entity.bus == s_BotPlayer.soldier.bus then
			s_Entity:PropertyChanged("FloatValue", s_SpeedValue)
			return
		end
		s_Entity = s_EntityIterator:Next()
	end
end

---@param p_Player Player
function BotManager:KillPlayerBots(p_Player)
	for _, l_Bot in ipairs(self._Bots) do
		if l_Bot:GetTargetPlayer() == p_Player then
			l_Bot:ResetVars()

			if l_Bot.m_Player.soldier then
				l_Bot.m_Player.soldier:Kill()
			end
		end
	end
end

function BotManager:ResetAllBots()
	for _, l_Bot in ipairs(self._Bots) do
		l_Bot:ResetVars()
	end
end

---@param p_Amount? integer
---@param p_TeamId? TeamId
function BotManager:KillAll(p_Amount, p_TeamId)
	local s_BotTable = self._Bots

	if p_TeamId then
		s_BotTable = self._BotsByTeam[p_TeamId + 1]
	end

	p_Amount = p_Amount or #s_BotTable

	for _, l_Bot in ipairs(s_BotTable) do
		l_Bot:Kill()

		p_Amount = p_Amount - 1

		if p_Amount <= 0 then
			return
		end
	end
end

---@param p_Amount? integer
---@param p_TeamId? TeamId
---@param p_Force? boolean
function BotManager:DestroyAll(p_Amount, p_TeamId, p_Force)
	local s_BotTable = self._Bots

	if p_TeamId then
		s_BotTable = self._BotsByTeam[p_TeamId + 1]
	end

	p_Amount = p_Amount or #s_BotTable

	for _, l_Bot in ipairs(s_BotTable) do
		if p_Force then
			self:DestroyBot(l_Bot)
		else
			table.insert(self._BotsToDestroy, l_Bot.m_Name)
		end

		p_Amount = p_Amount - 1

		if p_Amount <= 0 then
			return
		end
	end
end

function BotManager:DestroyDisabledBots()
	for _, l_Bot in ipairs(self._Bots) do
		if l_Bot:IsInactive() then
			table.insert(self._BotsToDestroy, l_Bot.m_Name)
		end
	end
end

---@param p_Player Player
function BotManager:DestroyPlayerBots(p_Player)
	for _, l_Bot in ipairs(self._Bots) do
		if l_Bot:GetTargetPlayer() == p_Player then
			table.insert(self._BotsToDestroy, l_Bot.m_Name)
		end
	end
end

function BotManager:RefreshTables()
	local s_NewTeamsTable = { {}, {}, {}, {}, {} }
	local s_NewBotTable = {}
	local s_NewBotbyNameTable = {}

	for _, l_Bot in ipairs(self._Bots) do
		if l_Bot.m_Player ~= nil then
			table.insert(s_NewBotTable, l_Bot)
			table.insert(s_NewTeamsTable[l_Bot.m_Player.teamId + 1], l_Bot)
			s_NewBotbyNameTable[l_Bot.m_Player.name] = l_Bot
		end
	end

	self._Bots = s_NewBotTable
	self._BotsByTeam = s_NewTeamsTable
	self._BotsByName = s_NewBotbyNameTable
end

---@param p_Bot Bot @might be a string as well
function BotManager:DestroyBot(p_Bot)
	if type(p_Bot) == 'string' then
		p_Bot = self._BotsByName[p_Bot]
	end

	-- Bot was not found.
	if p_Bot == nil then
		return
	end

	for l_Index = #self._Bots, 1, -1 do
		local s_Bot = self._Bots[l_Index]

		if p_Bot.m_Name == s_Bot.m_Name then
			table.remove(self._Bots, l_Index)
		end

		-- This will clear all references of the bot that gets destroyed.
		s_Bot:ClearPlayer(p_Bot.m_Player)
	end

	local s_BotTeam = self._BotsByTeam[p_Bot.m_Player.teamId + 1]

	for l_Index = #s_BotTeam, 1, -1 do
		local s_Bot = s_BotTeam[l_Index]

		if p_Bot.m_Name == s_Bot.m_Name then
			table.remove(s_BotTeam, l_Index)
		end
	end

	self._BotsByName[p_Bot.m_Name] = nil
	self._BotInputs[p_Bot.m_Id] = nil

	p_Bot:Destroy()
	---@diagnostic disable-next-line: cast-local-type
	p_Bot = nil
end

-- Comm-Actions.
-- All bots that are close to this player (and in the same team) leave the vehicles.
---@param p_Player Player
function BotManager:ExitVehicle(p_Player)
	if not p_Player.soldier then
		return
	end

	-- Find the closest bots in vehicle.
	local s_ClosestDistance = nil
	---@type Bot|nil
	local s_ClosestBot = nil

	local s_SoldierPosition = p_Player.soldier.worldTransform.trans

	for _, l_Bot in ipairs(self._BotsByTeam[p_Player.teamId + 1]) do
		if l_Bot.m_InVehicle and l_Bot.m_Player.soldier then
			local s_BotSoldierPosition = nil
			if l_Bot.m_Player.controlledControllable then
				s_BotSoldierPosition = l_Bot.m_Player.controlledControllable.transform.trans
			else
				s_BotSoldierPosition = l_Bot.m_Player.soldier.worldTransform.trans
			end

			if s_BotSoldierPosition then
				if s_ClosestBot == nil then
					s_ClosestBot = l_Bot
					s_ClosestDistance = s_BotSoldierPosition:Distance(s_SoldierPosition)
				else
					local s_Distance = s_BotSoldierPosition:Distance(s_SoldierPosition)

					if s_Distance < s_ClosestDistance then
						s_ClosestDistance = s_Distance
						s_ClosestBot = l_Bot
					end
				end
			end
		end
	end

	--- if there is a bot, then there is a number as well
	---@cast s_ClosestDistance number

	if s_ClosestBot and s_ClosestDistance < Registry.COMMON.COMMAND_DISTANCE then
		local s_VehicleEntity = s_ClosestBot.m_Player.controlledControllable

		if s_VehicleEntity then
			for l_EntryId = 0, s_VehicleEntity.entryCount - 1 do
				local s_Player = s_VehicleEntity:GetPlayerInEntry(l_EntryId)

				if s_Player then
					self:OnBotExitVehicle(s_Player.name)
				end
			end
		end
	end
end

---@param p_Player Player
---@param p_Type string|'"ammo"'|'"medkit"'
function BotManager:Deploy(p_Player, p_Type)
	if not p_Player or not p_Player.soldier then
		return
	end

	local s_SoldierPosition = p_Player.soldier.worldTransform.trans

	for _, l_Bot in ipairs(self._BotsByTeam[p_Player.teamId + 1]) do
		if not l_Bot.m_InVehicle then
			local s_BotPosition = l_Bot.m_Player.soldier and l_Bot.m_Player.soldier.worldTransform.trans

			if s_BotPosition then
				if p_Type == "ammo" and l_Bot.m_Kit == BotKits.Support then
					local s_Distance = s_BotPosition:Distance(s_SoldierPosition)

					if s_Distance < Registry.COMMON.COMMAND_DISTANCE then
						l_Bot:DeployIfPossible()
					end
				elseif p_Type == "medkit" and l_Bot.m_Kit == BotKits.Assault then
					local s_Distance = s_BotPosition:Distance(s_SoldierPosition)

					if s_Distance < Registry.COMMON.COMMAND_DISTANCE then
						l_Bot:DeployIfPossible()
					end
				end
			end
		end
	end
end

---@param p_Player Player
function BotManager:RepairVehicle(p_Player)
	if not p_Player or not p_Player.soldier or not p_Player.controlledControllable or
		p_Player.controlledControllable.typeInfo.name == "ServerSoldierEntity" then
		return
	end

	local s_SoldierPosition = p_Player.soldier.worldTransform.trans

	for _, l_Bot in ipairs(self._BotsByTeam[p_Player.teamId + 1]) do
		if not l_Bot.m_InVehicle and l_Bot.m_Kit == BotKits.Engineer then
			local s_BotSoldier = l_Bot.m_Player.soldier

			if s_BotSoldier then
				local s_Distance = s_BotSoldier.worldTransform.trans:Distance(s_SoldierPosition)

				if s_Distance < Registry.COMMON.COMMAND_DISTANCE then
					l_Bot:Repair(p_Player)
					break
				end
			end
		end
	end
end

---@param p_Player Player
function BotManager:EnterVehicle(p_Player)
	local s_VehicleType = m_Vehicles:FindOutVehicleType(p_Player)
	if s_VehicleType == VehicleTypes.NoVehicle or s_VehicleType == VehicleTypes.MobileArtillery then
		return
	end

	-- Check for vehicle of player and seats.
	local s_MaxFreeSeats = p_Player.controlledControllable.entryCount - 1

	if s_MaxFreeSeats <= 0 then
		return
	end

	local s_SoldierPosition = p_Player.soldier.worldTransform.trans

	for _, l_Bot in ipairs(self._BotsByTeam[p_Player.teamId + 1]) do
		if not l_Bot.m_InVehicle then
			local s_BotSoldier = l_Bot.m_Player.soldier

			if s_BotSoldier then
				local s_Distance = s_BotSoldier.worldTransform.trans:Distance(s_SoldierPosition)

				if s_Distance < Registry.COMMON.COMMAND_DISTANCE then
					l_Bot:EnterVehicleOfPlayer(p_Player)
					s_MaxFreeSeats = s_MaxFreeSeats - 1

					if s_MaxFreeSeats == 0 then
						break
					end
				end
			end
		end
	end
end

---@param p_Player Player
---@param p_Objective any To-do: add emmylua type
function BotManager:Attack(p_Player, p_Objective)
end

-- =============================================
-- Private Functions
-- =============================================

---@param p_Damage integer
---@param p_Bot Bot
---@param p_Soldier SoldierEntity
---@return number
function BotManager:_GetDamageValue(p_Damage, p_Bot, p_Soldier)
	local s_ResultDamage = 0.0
	local s_DamageFactor = 1.0

	local s_ActiveWeapon = p_Bot.m_ActiveWeapon

	if not s_ActiveWeapon then
		m_Logger:Error("Bot without active weapon in Soldier:Damage")
		return s_ResultDamage
	end

	local s_ActiveWeaponType = p_Bot.m_ActiveWeapon.type

	if s_ActiveWeaponType == WeaponTypes.Knife then
		if Globals.SpawnMode == SpawnModes.wave_spawn then
			s_DamageFactor = Globals.DamageFactorZombies
		else
			s_DamageFactor = Config.DamageFactorKnife
		end
		if Config.RandomDamgeOfZombies then
			s_DamageFactor = s_DamageFactor * MathUtils:GetRandom(0.5, 1.0) -- Zombies deal something between full and half damage
		end
	end

	return p_Damage * s_DamageFactor
end

if g_BotManager == nil then
	---@type BotManager
	g_BotManager = BotManager()
end

return g_BotManager

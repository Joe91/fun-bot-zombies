---@class ClientBotManager
---@overload fun():ClientBotManager
ClientBotManager = class('ClientBotManager')

---@type WeaponList
local m_WeaponList = require('__shared/WeaponList')
---@type Utilities
local m_Utilities = require('__shared/Utilities')
---@type Logger
local m_Logger = Logger("ClientBotManager", Debug.Client.INFO)

function ClientBotManager:__init()
	self:RegisterVars()
end

function ClientBotManager:RegisterVars()
	self.m_RaycastTimer = 0
	self.m_AliveTimer = 0
	self.m_LastIndex = 0
	self.m_Player = nil
	self.m_ReadyToUpdate = false

	-- Inputs for change of seats (1-8).
	self.m_LastInputLevelsPos = { 0, 0, 0, 0, 0, 0, 0, 0 }
end

-- =============================================
-- Events
-- =============================================

---VEXT Client Client:UpdateInput Event
---@param p_DeltaTime number
function ClientBotManager:OnClientUpdateInput(p_DeltaTime)
	-- -- To-do: find a better solution for that!!!
	-- if InputManager:WentKeyDown(InputDeviceKeys.IDK_Q) then
	-- 	-- Execute Vehicle Enter Detection here.
	-- 	if self.m_Player ~= nil and self.m_Player.inVehicle then
	-- 		local s_Transform = ClientUtils:GetCameraTransform()

	-- 		if s_Transform == nil then return end

	-- 		-- The free cam transform is inverted. Invert it back.
	-- 		local s_CameraForward = Vec3(s_Transform.forward.x * -1, s_Transform.forward.y * -1, s_Transform.forward.z * -1)

	-- 		local s_MaxEnterDistance = 50
	-- 		local s_CastPosition = Vec3(s_Transform.trans.x + (s_CameraForward.x * s_MaxEnterDistance),
	-- 			s_Transform.trans.y + (s_CameraForward.y * s_MaxEnterDistance),
	-- 			s_Transform.trans.z + (s_CameraForward.z * s_MaxEnterDistance))

	-- 		local s_StartPosition = s_Transform.trans:Clone() + s_CameraForward * 4

	-- 		local s_RaycastFlags = RayCastFlags.DontCheckWater | RayCastFlags.IsAsyncRaycast
	-- 		---@cast s_RaycastFlags RayCastFlags
	-- 		local s_Raycast = RaycastManager:Raycast(s_StartPosition, s_CastPosition, s_RaycastFlags)

	-- 		if s_Raycast ~= nil and s_Raycast.rigidBody:Is("CharacterPhysicsEntity") then
	-- 			-- Find a teammate at this position.
	-- 			for _, l_Player in pairs(PlayerManager:GetPlayersByTeam(self.m_Player.teamId)) do
	-- 				if l_Player.soldier ~= nil and m_Utilities:isBot(l_Player) and
	-- 					l_Player.soldier.worldTransform.trans:Distance(s_Raycast.position) < 2 then
	-- 					NetEvents:SendLocal('Client:RequestEnterVehicle', l_Player.name)
	-- 					break
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
end

---VEXT Client Input:PreUpdate Hook
---@param p_HookCtx HookContext
---@param p_Cache ConceptCache
---@param p_DeltaTime number
function ClientBotManager:OnInputPreUpdate(p_HookCtx, p_Cache, p_DeltaTime)
	-- if self.m_Player ~= nil and self.m_Player.inVehicle then
	-- 	for i = 1, 8 do
	-- 		local s_Varname = "ConceptSelectPosition" .. tostring(i)
	-- 		local s_LevelId = InputConceptIdentifiers[s_Varname]
	-- 		local s_CurrentLevel = p_Cache:GetLevel(s_LevelId)

	-- 		if self.m_LastInputLevelsPos[i] == 0 and s_CurrentLevel > 0 then
	-- 			NetEvents:SendLocal('Client:RequestChangeVehicleSeat', i)
	-- 		end

	-- 		self.m_LastInputLevelsPos[i] = s_CurrentLevel
	-- 	end
	-- end
end

---VEXT Shared Engine:Message Event
---@param p_Message Message
function ClientBotManager:OnEngineMessage(p_Message)
	if p_Message.type == MessageType.ClientLevelFinalizedMessage then
		NetEvents:SendLocal('Client:RequestSettings')
		self.m_ReadyToUpdate = true
		m_Logger:Write("level loaded on Client")
	end

	if p_Message.type == MessageType.ClientConnectionUnloadLevelMessage or
		p_Message.type == MessageType.ClientCharacterLocalPlayerDeletedMessage then
		self:RegisterVars()
	end
end

function ClientBotManager:DoRaycast(p_Pos1, p_Pos2, p_InObjectPos1, p_InObjectPos2)
	if Registry.COMMON.USE_COLLISION_RAYCASTS then
		local s_MaxHits = 1

		if p_InObjectPos1 then
			s_MaxHits = s_MaxHits + 1
		end

		if p_InObjectPos2 then
			s_MaxHits = s_MaxHits + 1
		end

		local s_MaterialFlags = 0 -- MaterialFlags.MfPenetrable | MaterialFlags.MfClientDestructible | MaterialFlags.MfBashable | MaterialFlags.MfSeeThrough | MaterialFlags.MfNoCollisionResponse | MaterialFlags.MfNoCollisionResponseCombined
		---@cast s_MaterialFlags MaterialFlags
		local s_RaycastFlags = RayCastFlags.DontCheckWater | RayCastFlags.DontCheckCharacter
		---@cast s_RaycastFlags RayCastFlags

		local s_RayHits = RaycastManager:CollisionRaycast(p_Pos1, p_Pos2, s_MaxHits, s_MaterialFlags, s_RaycastFlags)

		if s_RayHits ~= nil and #s_RayHits < s_MaxHits then
			return true
		else
			return false
		end
	else
		if p_InObjectPos1 or p_InObjectPos2 then
			local s_DeltaPos = p_Pos2 - p_Pos1
			s_DeltaPos = s_DeltaPos:Normalize()

			if p_InObjectPos1 then -- Start Raycast outside of vehicle?
				p_Pos1 = p_Pos1 + (s_DeltaPos * 3.2)
			end

			if p_InObjectPos2 then
				p_Pos2 = p_Pos2 - (s_DeltaPos * 3.2)
			end
		end

		local s_RaycastFlags = RayCastFlags.DontCheckWater | RayCastFlags.DontCheckCharacter | RayCastFlags.IsAsyncRaycast
		---@cast s_RaycastFlags RayCastFlags
		local s_Raycast = RaycastManager:Raycast(p_Pos1, p_Pos2, s_RaycastFlags)

		if s_Raycast == nil or s_Raycast.rigidBody == nil then
			return true
		else
			return false
		end
	end
end

function ClientBotManager:SendRaycastResults(p_RaycastResultsToSend)
	NetEvents:SendLocal("Botmanager:RaycastResults", p_RaycastResultsToSend)
end

---VEXT Shared UpdateManager:Update Event
---@param p_DeltaTime number
---@param p_UpdatePass UpdatePass|integer
function ClientBotManager:OnUpdateManagerUpdate(p_DeltaTime, p_UpdatePass)
	if p_UpdatePass ~= UpdatePass.UpdatePass_PreSim or not self.m_ReadyToUpdate then -- UpdatePass_PreSim UpdatePass_PreFrame
		return
	end

	local s_RaycastResultsToSend = {}

	self.m_RaycastTimer = self.m_RaycastTimer + p_DeltaTime
	local s_SkipEnemyCheck = not Config.BotsAttackPlayers or
		(self.m_RaycastTimer < Registry.GAME_RAYCASTING.RAYCAST_INTERVAL_ENEMY_CHECK)

	if self.m_Player == nil then
		self.m_Player = PlayerManager:GetLocalPlayer()

		if self.m_Player == nil then
			self:SendRaycastResults(s_RaycastResultsToSend)
			return
		end
	end

	if s_SkipEnemyCheck then
		self:SendRaycastResults(s_RaycastResultsToSend)
		return
	end

	self.m_RaycastTimer = 0
	local s_CheckCount = 0

	if self.m_Player.soldier ~= nil then -- Alive. Check for enemy bots.
		-- if self.m_AliveTimer < Registry.CLIENT.SPAWN_PROTECTION then -- Wait 2s (spawn-protection).
		-- 	self.m_AliveTimer = self.m_AliveTimer + p_DeltaTime
		-- 	self:SendRaycastResults(s_RaycastResultsToSend)
		-- 	return
		-- end

		---@type Player[]
		local s_EnemyPlayers = {}

		for _, l_Player in pairs(PlayerManager:GetPlayers()) do
			if l_Player.teamId ~= self.m_Player.teamId and self.m_Player.teamId ~= 0 and l_Player.soldier ~= nil then -- Don't let bots attack spectators.
				table.insert(s_EnemyPlayers, l_Player)
			end
		end

		if self.m_LastIndex >= #s_EnemyPlayers then
			self.m_LastIndex = 0
		end

		-- Check for clear view.
		local s_PlayerPosition = Vec3()
		if self.m_Player.inVehicle then
			s_PlayerPosition = self.m_Player.controlledControllable.transform.trans:Clone()
			s_PlayerPosition.y = s_PlayerPosition.y + 1.4
		else
			s_PlayerPosition = ClientUtils:GetCameraTransform().trans:Clone() -- player.soldier.worldTransform.trans:Clone() + m_Utilities:getCameraPos(player, false)
		end

		for i = 0, #s_EnemyPlayers - 1 do
			local s_Index = (self.m_LastIndex + i) % #s_EnemyPlayers + 1
			local s_Bot = s_EnemyPlayers[s_Index]

			if s_Bot == nil or s_Bot.onlineId ~= 0 or s_Bot.soldier == nil then
				goto continue_enemy_loop
			end

			-- Find direction of Bot.
			local s_TargetPos = Vec3()

			s_TargetPos = s_Bot.soldier.worldTransform.trans:Clone() + m_Utilities:getCameraPos(s_Bot, false, false)

			local s_Distance = s_PlayerPosition:Distance(s_TargetPos)
			local s_VertDistance = Vec3(0, s_PlayerPosition.y, 0):Distance(Vec3(0, s_TargetPos.y, 0))
			s_CheckCount = s_CheckCount + 1

			if (s_Distance < Config.MaxShootDistance) and (s_PlayerPosition.y < s_TargetPos.y or s_VertDistance < (1 - (s_Distance / Config.MaxShootDistance)) * 12) then
				if self:DoRaycast(s_PlayerPosition, s_TargetPos, self.m_Player.inVehicle, s_Bot.inVehicle) then
					-- We found a valid bot in Sight (either no hit, or player-hit). Signal Server with players.
					local s_IgnoreYaw = false

					if s_Distance < Config.DistanceForDirectAttack then
						s_IgnoreYaw = true -- Shoot, because you are near.
					end

					table.insert(s_RaycastResultsToSend, {
						Mode = "ShootAtPlayer",
						Bot1 = s_Bot.name,
						Bot2 = "",
						IgnoreYaw = s_IgnoreYaw,
					})
				end

				self.m_LastIndex = s_Index
				self:SendRaycastResults(s_RaycastResultsToSend)
				return -- Only one raycast per cycle.
			end

			if s_CheckCount >= Registry.CLIENT.MAX_CHECKS_PER_CYCLE then
				self.m_LastIndex = s_Index
				self:SendRaycastResults(s_RaycastResultsToSend)
				return
			end

			::continue_enemy_loop::
		end
	else
		self.m_AliveTimer = 0 -- Add a little delay after spawn.
	end

	self:SendRaycastResults(s_RaycastResultsToSend)
end

---VEXT Shared Extension:Unloading Event
function ClientBotManager:OnExtensionUnloading()
	self:RegisterVars()
end

---VEXT Shared Level:Destroy Event
function ClientBotManager:OnLevelDestroy()
	self:RegisterVars()
end

--function ClientBotManager:SortPlayersByDistance(playerArray, position)

--end

-- =============================================
-- NetEvents
-- =============================================

function ClientBotManager:OnWriteClientSettings(p_NewConfig, p_UpdateWeaponSets)
	for l_Key, l_Value in pairs(p_NewConfig) do
		Config[l_Key] = l_Value
	end

	m_Logger:Write("write settings")

	if p_UpdateWeaponSets then
		m_WeaponList:UpdateWeaponList()
	end

	self.m_Player = PlayerManager:GetLocalPlayer()
end

-- =============================================
-- Hooks
-- =============================================

if g_ClientBotManager == nil then
	---@type ClientBotManager
	g_ClientBotManager = ClientBotManager()
end

return g_ClientBotManager

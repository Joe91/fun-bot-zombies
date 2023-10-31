---@class GameDirector
---@overload fun():GameDirector
GameDirector = class('GameDirector')

---@type NodeCollection
local m_NodeCollection = require('NodeCollection')
---@type Utilities
local m_Utilities = require('__shared/Utilities')
---@type Vehicles
local m_Vehicles = require("Vehicles")
---@type Logger
local m_Logger = Logger("GameDirector", Debug.Server.GAMEDIRECTOR)

function GameDirector:__init()
	self:RegisterVars()
end

function GameDirector:RegisterVars()
	self.m_UpdateTimer = -1

	self.m_BotsByTeam = {}

	self.m_AllObjectives = {}
	self.m_Translations = {}
	self.m_ArmedMcoms = {}

	self.m_RushStageCounter = 0
	self.m_RushAttackingBase = ''

	self.m_SpawnableStationaryAas = {}
	self.m_SpawnableVehicles = {}
	self.m_AvailableVehicles = {}
end

-- =============================================
-- Events.
-- =============================================

-- =============================================
-- Level Events.
-- =============================================

function GameDirector:OnLevelLoaded()
	self.m_AllObjectives = {}
	self.m_Translations = {}
	self:_RegisterRushEventCallbacks()
	-- To-do: assign weights to each objective.
	self.m_UpdateTimer = 0
	self:_InitObjectives()

	for i = 0, Globals.NrOfTeams do
		self.m_SpawnableVehicles[i] = {}
		self.m_SpawnableStationaryAas[i] = {}
		self.m_AvailableVehicles[i] = {}
	end
end

---VEXT Server Server:RoundOver Event
---@param p_RoundTime number
---@param p_WinningTeam TeamId|integer
function GameDirector:OnRoundOver(p_RoundTime, p_WinningTeam)
	self.m_UpdateTimer = -1
end

---VEXT Server Server:RoundReset Event
function GameDirector:OnRoundReset()
	self.m_AllObjectives = {}
	self.m_UpdateTimer = 0
end

-- =============================================
-- CapturePoint Events.
-- =============================================

---VEXT Server Player:EnteredCapturePoint Event
---@param p_Player Player
---@param p_CapturePoint CapturePointEntity|Entity
function GameDirector:OnPlayerEnteredCapturePoint(p_Player, p_CapturePoint)
	p_CapturePoint = CapturePointEntity(p_CapturePoint)
	local s_ObjectiveName = self:_TranslateObjective(p_CapturePoint.transform.trans, p_CapturePoint.name)
	self:_UpdateObjective(s_ObjectiveName, {
		-- team = p_CapturePoint.team,
		isAttacked = p_CapturePoint.isAttacked
	})
end

---VEXT Server CapturePoint:Captured Event
---@param p_CapturePoint CapturePointEntity|Entity
function GameDirector:OnCapturePointCaptured(p_CapturePoint)
	-- p_CapturePoint = CapturePointEntity(p_CapturePoint)
	-- local s_ObjectiveName = self:_TranslateObjective(p_CapturePoint.transform.trans, p_CapturePoint.name)
	-- self:_UpdateObjective(s_ObjectiveName, {
	-- 	team = p_CapturePoint.team,
	-- 	isAttacked = p_CapturePoint.isAttacked
	-- })

	-- local s_Objective = self:_GetObjectiveObject(s_ObjectiveName)

	-- if s_Objective == nil then
	-- 	return
	-- end

	-- m_Logger:Write('GameDirector:_onCapture: ' .. s_ObjectiveName)
	-- m_Logger:Write('self.CurrentAssignedCount: ' .. m_Utilities:dump(s_Objective.assigned, true))

	-- for l_BotTeam, l_Bots in pairs(self.m_BotsByTeam) do
	-- 	for i = 1, #l_Bots do
	-- 		if l_Bots[i]:GetObjective() == s_Objective.name and s_Objective.team == l_BotTeam then
	-- 			m_Logger:Write('Bot completed objective: ' ..
	-- 				l_Bots[i].m_Name .. ' (team: ' .. l_BotTeam .. ') -> ' .. s_Objective.name)

	-- 			l_Bots[i]:SetObjective()
	-- 			s_Objective.assigned[l_BotTeam] = math.max(s_Objective.assigned[l_BotTeam] - 1, 0)
	-- 		end
	-- 	end
	-- end
end

---VEXT Server CapturePoint:Lost Event
---@param p_CapturePoint CapturePointEntity|Entity
function GameDirector:OnCapturePointLost(p_CapturePoint)
	p_CapturePoint = CapturePointEntity(p_CapturePoint)
	local s_ObjectiveName = self:_TranslateObjective(p_CapturePoint.transform.trans, p_CapturePoint.name)
	local s_IsAttacked = p_CapturePoint.flagLocation < 100.0 and p_CapturePoint.isControlled
	self:_UpdateObjective(s_ObjectiveName, {
		team = TeamId.TeamNeutral, -- p_CapturePoint.team
		isAttacked = s_IsAttacked
	})

	m_Logger:Write('GameDirector:_onLost: ' .. s_ObjectiveName)
end

---VEXT Shared Engine:Update Event
---@param p_DeltaTime number
function GameDirector:OnEngineUpdate(p_DeltaTime)
	if self.m_UpdateTimer >= 0 then
		self.m_UpdateTimer = self.m_UpdateTimer + p_DeltaTime
	end

	if self.m_UpdateTimer < Registry.GAME_DIRECTOR.UPDATE_OBJECTIVES_CYCLE then
		return
	end

	if Globals.IsRush then
		self:_UpdateTimersOfMcoms(self.m_UpdateTimer)
	end

	self.m_UpdateTimer = 0

	-- Update bot → team list.
	local s_BotList = g_BotManager:GetBots()
	self.m_BotsByTeam = {}

	for i = 1, #s_BotList do
		if not s_BotList[i]:IsInactive() and s_BotList[i].m_Player ~= nil then
			if self.m_BotsByTeam[s_BotList[i].m_Player.teamId] == nil then
				self.m_BotsByTeam[s_BotList[i].m_Player.teamId] = {}
			end

			table.insert(self.m_BotsByTeam[s_BotList[i].m_Player.teamId], s_BotList[i])
		end
	end

	local s_MaxAssigns = {}
	-- Evaluate how many bots are max- and min-assigned per objective.

	local s_AvailableObjectives = {}

	for _, l_Objective in pairs(self.m_AllObjectives) do
		if not l_Objective.subObjective and not l_Objective.isBase and l_Objective.active and not l_Objective.destroyed and
			not l_Objective.isEnterVehiclePath then
			for i = 1, Globals.NrOfTeams do
				if s_AvailableObjectives[i] == nil then
					s_AvailableObjectives[i] = 0
				end

				if l_Objective.team ~= i then
					s_AvailableObjectives[i] = s_AvailableObjectives[i] + 1
				end
			end
		end
	end

	for i = 1, Globals.NrOfTeams do
		s_MaxAssigns[i] = 0

		if s_AvailableObjectives[i] == nil then
			s_AvailableObjectives[i] = 1
		end

		if self.m_BotsByTeam[i] ~= nil then
			s_MaxAssigns[i] = math.floor((#self.m_BotsByTeam[i] / s_AvailableObjectives[i]) + 1)

			if (#self.m_BotsByTeam[i] % 2) == 1 then
				s_MaxAssigns[i] = s_MaxAssigns[i] + 1
			end
		end

		if s_MaxAssigns[i] > Registry.GAME_DIRECTOR.MAX_ASSIGNED_LIMIT then
			s_MaxAssigns[i] = Registry.GAME_DIRECTOR.MAX_ASSIGNED_LIMIT
		end
	end
end

-- =============================================
-- RUSH Events.
-- =============================================

function GameDirector:ToggleDirectionCombatZone(p_Entity, p_Player)
	if m_Utilities:isBot(p_Player) and p_Player.teamId == TeamId.Team1 then -- Attacking team.
		local s_Bot = g_BotManager:GetBotByName(p_Player.name)
		if s_Bot then
			s_Bot._InvertPathDirection = not s_Bot._InvertPathDirection
		end
	end
end

function GameDirector:OnMcomArmed(p_Player)
	local s_PlayerPos = nil
	if p_Player and p_Player.soldier then
		s_PlayerPos = p_Player.soldier.worldTransform.trans:Clone()
	elseif p_Player and p_Player.corpse then
		s_PlayerPos = p_Player.corpse.worldTransform.trans:Clone()
	end

	if s_PlayerPos then
		local s_Objective = self:_TranslateObjective(s_PlayerPos)
		m_Logger:Write(s_Objective .. " armed")

		self:_UpdateObjective(s_Objective, {
			team = TeamId.Team1,
			isAttacked = true
		})
		self.m_ArmedMcoms[s_Objective] = -self.m_UpdateTimer
	end
end

function GameDirector:OnMcomDisarmed(p_Player)
	local s_PlayerPos = nil
	if p_Player and p_Player.soldier then
		s_PlayerPos = p_Player.soldier.worldTransform.trans:Clone()
	elseif p_Player and p_Player.corpse then
		s_PlayerPos = p_Player.corpse.worldTransform.trans:Clone()
	end

	if s_PlayerPos then
		local s_Objective = self:_TranslateObjective(s_PlayerPos)
		m_Logger:Write(s_Objective .. " disarmed")

		self:_UpdateObjective(s_Objective, {
			team = TeamId.TeamNeutral,
			isAttacked = false
		})
		self.m_ArmedMcoms[s_Objective] = nil
	end
end

function GameDirector:OnLifeCounterBaseDestoyed(p_LifeCounterEntity, p_FinalBase)
	self:_UpdateValidObjectives()
end

function GameDirector:OnMcomDestroyed(p_Objective)
	m_Logger:Write(p_Objective .. " destroyed after " .. tostring(self.m_ArmedMcoms[p_Objective]) .. " s")
	self.m_ArmedMcoms[p_Objective] = nil

	local s_SubObjective = nil
	local s_TopObjective = nil

	if p_Objective ~= '' then
		self:_UpdateObjective(p_Objective, {
			team = TeamId.TeamNeutral, -- p_Player.teamId,
			isAttacked = false,
			destroyed = true
		})
		s_SubObjective = self:_GetSubObjectiveFromObj(p_Objective)
		s_TopObjective = self:_GetObjectiveFromSubObj(p_Objective)
	end

	if s_TopObjective ~= nil then
		self:_UpdateObjective(s_TopObjective, {
			destroyed = true
		})
	end

	if s_SubObjective ~= nil then
		self:_UpdateObjective(s_SubObjective, {
			destroyed = true
		})
	end
end

---@param p_EntityId integer
function GameDirector:OnRushZoneDisabled(p_EntityId)
	m_Logger:Write("Zone " .. tostring(p_EntityId) .. " disabled")
end

-- =============================================
-- Vehicle Events.
-- =============================================

function GameDirector:GetSpawnableVehicle(p_TeamId)
	return self.m_SpawnableVehicles[p_TeamId]
end

function GameDirector:GetStationaryAas(p_TeamId)
	return self.m_SpawnableStationaryAas[p_TeamId]
end

---VEXT Server Vehicle:SpawnDone Event
---@param p_Entity ControllableEntity|Entity
function GameDirector:OnVehicleSpawnDone(p_Entity)
	p_Entity = ControllableEntity(p_Entity)
	local s_VehicleData = m_Vehicles:GetVehicleByEntity(p_Entity)

	if s_VehicleData == nil then
		return -- No vehicle found.
	end

	if not Config.UseAirVehicles and
		(s_VehicleData.Type == VehicleTypes.Plane or s_VehicleData.Type == VehicleTypes.Chopper) then
		return -- Not allowed to use.
	end

	local s_Objective = self:_SetVehicleObjectiveState(p_Entity.transform.trans, true)

	if s_Objective ~= nil then
		local s_Node = self:FindClosestPath(p_Entity.transform.trans, true, false, s_VehicleData.Terrain)

		if s_Node ~= nil and s_Node.Position:Distance(p_Entity.transform.trans) < Registry.VEHICLES.MIN_DISTANCE_VEHICLE_ENTER then
			if s_Objective.isSpawnPath then
				table.insert(self.m_SpawnableVehicles[s_Objective.team], p_Entity)
			else
				table.insert(self.m_AvailableVehicles[s_Objective.team], p_Entity)
			end
		end
	end

	if m_Vehicles:IsVehicleType(s_VehicleData, VehicleTypes.StationaryAA) then
		table.insert(self.m_SpawnableStationaryAas[s_VehicleData.Team], p_Entity)
	end
end

---VEXT Server Vehicle:Enter Event
---@param p_Entity ControllableEntity|Entity
---@param p_Player Player
function GameDirector:OnVehicleEnter(p_Entity, p_Player)
	p_Entity = ControllableEntity(p_Entity)
	local s_VehicleData = m_Vehicles:GetVehicleByEntity(p_Entity)

	if s_VehicleData ~= nil then
		if m_Vehicles:IsVehicleType(s_VehicleData, VehicleTypes.StationaryAA) then
			for l_Index, l_Entity in pairs(self.m_SpawnableStationaryAas[p_Player.teamId]) do
				if (l_Entity.uniqueId == p_Entity.uniqueId) and (l_Entity.instanceId == p_Entity.instanceId) then
					table.remove(self.m_SpawnableStationaryAas[p_Player.teamId], l_Index)
				end
			end
		else
			for l_Index, l_Entity in pairs(self.m_SpawnableVehicles[p_Player.teamId]) do
				if (l_Entity.uniqueId == p_Entity.uniqueId) and (l_Entity.instanceId == p_Entity.instanceId) then
					table.remove(self.m_SpawnableVehicles[p_Player.teamId], l_Index)
				end
			end
			for l_Index, l_Entity in pairs(self.m_AvailableVehicles[p_Player.teamId]) do
				if (l_Entity.uniqueId == p_Entity.uniqueId) and (l_Entity.instanceId == p_Entity.instanceId) then
					table.remove(self.m_AvailableVehicles[p_Player.teamId], l_Index)
				end
			end
		end
	end

	if not m_Utilities:isBot(p_Player) then
		p_Entity = ControllableEntity(p_Entity)
		self:_SetVehicleObjectiveState(p_Entity.transform.trans, false)

		if p_Player.controlledEntryId ~= 0 then
			local s_Entity = p_Player.controlledControllable
			local s_Driver = s_Entity:GetPlayerInEntry(0)

			if s_Driver ~= nil then
				Events:Dispatch("Bot:AbortWait", s_Driver.name)
			end
		end

		self:_SetVehicleObjectiveState(p_Entity.transform.trans, false)
	end
end

-- =============================================
-- Functions.
-- =============================================

-- =============================================
-- Public Functions.
-- =============================================


function GameDirector:CheckForExecution(p_Point, p_TeamId, p_InVehicle)
	if p_Point.Data.Action == nil then
		return false
	end

	local s_Action = p_Point.Data.Action

	if s_Action.type == "mcom" then
		local s_Mcom = self:_TranslateObjective(p_Point.Position)

		if s_Mcom == nil then
			return false
		end

		local s_Objective = self:_GetObjectiveObject(s_Mcom)

		if s_Objective == nil then
			return false
		end

		if s_Objective.active and not s_Objective.destroyed then
			if p_TeamId == TeamId.Team1 and s_Objective.team == TeamId.TeamNeutral then
				return true -- Attacking Team.
			elseif p_TeamId == TeamId.Team2 and s_Objective.isAttacked then
				return true -- Defending Team.
			end
		end

		return false
	elseif s_Action.type == "vehicle" then
		if p_InVehicle then
			return false
		end

		local s_CurrentPathFirst = m_NodeCollection:GetFirst(p_Point.PathIndex)

		if s_CurrentPathFirst.Data.Objectives ~= nil and #s_CurrentPathFirst.Data.Objectives == 1 then
			local s_TempObjective = self:_GetObjectiveObject(s_CurrentPathFirst.Data.Objectives[1])

			if s_TempObjective ~= nil and s_TempObjective.active and s_TempObjective.isEnterVehiclePath then
				return true
			end
		end
		return false
	elseif s_Action.type == "exit" then
		if p_InVehicle then
			return true
		else
			return false
		end
	else -- Execute ACTION.
		return true
	end
end

function GameDirector:FindClosestPath(p_Trans, p_VehiclePath, p_DetailedSearch, p_VehicleTerrain)
	local s_ClosestPathNode = nil
	local s_Paths = m_NodeCollection:GetPaths()

	if s_Paths ~= nil then
		local s_ClosestDistance = nil

		for _, l_Waypoints in pairs(s_Paths) do
			if l_Waypoints[1] ~= nil then
				local s_isVehiclePath = false
				local s_isAirPath = false
				local s_isWaterPath = false

				if l_Waypoints[1].Data ~= nil and l_Waypoints[1].Data.Vehicles ~= nil then
					s_isVehiclePath = true

					for _, l_PathType in pairs(l_Waypoints[1].Data.Vehicles) do
						if l_PathType:lower() == "air" then
							s_isAirPath = true
						end

						if l_PathType:lower() == "water" then
							s_isWaterPath = true
						end
					end
				end

				if p_VehiclePath then
					if s_isVehiclePath then
						if (p_VehicleTerrain == VehicleTerrains.Air and s_isAirPath) or
							(p_VehicleTerrain == VehicleTerrains.Water and s_isWaterPath) or
							(p_VehicleTerrain == VehicleTerrains.Land and not s_isWaterPath and not s_isAirPath) or
							(p_VehicleTerrain == VehicleTerrains.Amphibious and not s_isAirPath) then
							if p_DetailedSearch then
								for i = 1, #l_Waypoints, Registry.GAME_DIRECTOR.NODE_SEARCH_INCREMENTS do
									local s_NewDistance = Utilities:DistanceFast(l_Waypoints[i].Position, p_Trans)

									if s_ClosestDistance == nil then
										s_ClosestDistance = s_NewDistance
										s_ClosestPathNode = l_Waypoints[i]
									else
										if s_NewDistance < s_ClosestDistance then
											s_ClosestDistance = s_NewDistance
											s_ClosestPathNode = l_Waypoints[i]
										end
									end
								end
							else
								local s_NewDistance = Utilities:DistanceFast(l_Waypoints[1].Position, p_Trans)

								if s_ClosestDistance == nil then
									s_ClosestDistance = s_NewDistance
									s_ClosestPathNode = l_Waypoints[1]
								else
									if s_NewDistance < s_ClosestDistance then
										s_ClosestDistance = s_NewDistance
										s_ClosestPathNode = l_Waypoints[1]
									end
								end
							end
						end
					end
				else -- Not in vehicle.
					if not s_isAirPath and not s_isWaterPath then
						if p_DetailedSearch then
							for i = 1, #l_Waypoints, Registry.GAME_DIRECTOR.NODE_SEARCH_INCREMENTS do
								local s_NewDistance = Utilities:DistanceFast(l_Waypoints[i].Position, p_Trans)

								if s_ClosestDistance == nil then
									s_ClosestDistance = s_NewDistance
									s_ClosestPathNode = l_Waypoints[i]
								else
									if s_NewDistance < s_ClosestDistance then
										s_ClosestDistance = s_NewDistance
										s_ClosestPathNode = l_Waypoints[i]
									end
								end
							end
						else
							local s_NewDistance = Utilities:DistanceFast(l_Waypoints[1].Position, p_Trans)

							if s_ClosestDistance == nil then
								s_ClosestDistance = s_NewDistance
								s_ClosestPathNode = l_Waypoints[1]
							else
								if s_NewDistance < s_ClosestDistance then
									s_ClosestDistance = s_NewDistance
									s_ClosestPathNode = l_Waypoints[1]
								end
							end
						end
					end
				end
			end
		end
	end

	return s_ClosestPathNode
end

function GameDirector:GetSpawnPath(p_TeamId, p_SquadId, p_OnlyBase)
	-- Check for spawn at squad-mate.
	local s_SquadMates = PlayerManager:GetPlayersBySquad(p_TeamId, p_SquadId)

	for _, l_Player in pairs(s_SquadMates) do
		if l_Player.soldier and l_Player.isAllowedToSpawnOn then
			if m_Utilities:isBot(l_Player) then
				local s_SquadBot = g_BotManager:GetBotByName(l_Player.name)
				if not s_SquadBot.m_InVehicle then
					local s_WayIndex = s_SquadBot:GetWayIndex()
					local s_PointIndex = s_SquadBot:GetPointIndex()

					if MathUtils:GetRandomInt(1, 100) <= Registry.BOT_SPAWN.PROBABILITY_SQUADMATE_SPAWN then
						m_Logger:Write("spawn at squad-mate")
						return s_WayIndex, s_PointIndex, s_SquadBot._InvertPathDirection, nil -- Use same direction.
					else
						break
					end
				else -- Squad-bot in vehicle.
					local s_EntryId = s_SquadBot.m_Player.controlledEntryId

					if s_EntryId == 0 then
						local s_Vehicle = s_SquadBot.m_Player.controlledControllable

						-- Check for free seats.
						if m_Vehicles:GetNrOfFreeSeats(s_Vehicle, false) > 0 then
							local s_WayIndex = s_SquadBot:GetWayIndex()
							local s_PointIndex = s_SquadBot:GetPointIndex()

							if MathUtils:GetRandomInt(1, 100) <= Registry.BOT_SPAWN.PROBABILITY_SQUADMATE_VEHICLE_SPAWN then
								m_Logger:Write("spawn at squad-mate's vehicle")
								return s_WayIndex, s_PointIndex, s_SquadBot._InvertPathDirection, s_Vehicle -- Use same direction.
							else
								break
							end
						else
							break
						end
					end
				end
			else
				-- Check for vehicle of real player.
				if l_Player.controlledControllable ~= nil and not l_Player.controlledControllable:Is("ServerSoldierEntity") then
					if l_Player.controlledEntryId == 0 then
						local s_Vehicle = l_Player.controlledControllable

						-- Check for free seats.
						if m_Vehicles:GetNrOfFreeSeats(s_Vehicle, true) > 0 then
							if MathUtils:GetRandomInt(1, 100) <= Registry.BOT_SPAWN.PROBABILITY_SQUADMATE_PLAYER_VEHICLE_SPAWN then
								m_Logger:Write("spawn at squad-mate's vehicle")
								return 1, 1, false, s_Vehicle
							else
								break
							end
						else
							break
						end
					end
				else
					if MathUtils:GetRandomInt(1, 100) <= Registry.BOT_SPAWN.PROBABILITY_SQUADMATE_SPAWN then
						local s_Node = self:FindClosestPath(l_Player.soldier.worldTransform.trans, false, true, nil)
						if s_Node and s_Node.Position:Distance(l_Player.soldier.worldTransform.trans) < 6.0 then
							return s_Node.PathIndex, s_Node.PointIndex, false, nil -- Use same direction.
						end
					end
				end
			end
		end
	end

	-- Find reference-objective.
	local s_ReferenceObjectivesNeutral = {}
	local s_ReferenceObjectivesEnemy = {}

	for _, l_ReferenceObjective in pairs(self.m_AllObjectives) do
		if not l_ReferenceObjective.isEnterVehiclePath and not l_ReferenceObjective.isBase and
			not l_ReferenceObjective.isSpawnPath then
			if l_ReferenceObjective.team == TeamId.TeamNeutral then
				table.insert(s_ReferenceObjectivesNeutral, l_ReferenceObjective)
				break
			elseif l_ReferenceObjective.team ~= p_TeamId then
				table.insert(s_ReferenceObjectivesEnemy, l_ReferenceObjective)
			end
		end
	end

	local s_ReferenceObjective = nil

	if #s_ReferenceObjectivesNeutral > 0 then
		s_ReferenceObjective = s_ReferenceObjectivesNeutral[MathUtils:GetRandomInt(1, #s_ReferenceObjectivesNeutral)]
	elseif #s_ReferenceObjectivesEnemy > 0 then
		s_ReferenceObjective = s_ReferenceObjectivesEnemy[MathUtils:GetRandomInt(1, #s_ReferenceObjectivesEnemy)]
	end

	local s_PossibleObjectives = {}
	local s_AttackedObjectives = {}
	local s_ClosestObjective = nil
	local s_ClosestDistance = nil
	local s_PossibleBases = {}
	local s_RushConvertedBases = {}
	local s_PathsDone = {}

	for _, l_Objective in pairs(self.m_AllObjectives) do
		local s_AllObjectives = m_NodeCollection:GetKnownObjectives()
		local s_PathsWithObjective = s_AllObjectives[l_Objective.name]

		if s_PathsWithObjective == nil then
			-- Can only happen if the collection was cleared. So don't spawn in this case.
			return 0, 0
		end

		for _, l_Path in pairs(s_PathsWithObjective) do
			if s_PathsDone[l_Path] then
				goto continue_paths_loop
			end

			local s_Node = m_NodeCollection:Get(1, l_Path)

			if s_Node == nil or s_Node.Data.Objectives == nil or #s_Node.Data.Objectives ~= 1 then
				goto continue_paths_loop
			end

			-- Possible path.
			if l_Objective.team == p_TeamId and l_Objective.active and not l_Objective.isEnterVehiclePath then
				if l_Objective.isBase then
					table.insert(s_PossibleBases, l_Path)
				elseif not p_OnlyBase then
					if l_Objective.isAttacked then
						table.insert(s_AttackedObjectives, { name = l_Objective.name, path = l_Path })
					end

					table.insert(s_PossibleObjectives, { name = l_Objective.name, path = l_Path })

					if s_ReferenceObjective ~= nil and s_ReferenceObjective.position ~= nil and l_Objective.position ~= nil then
						local s_DistanceToRef = s_ReferenceObjective.position:Distance(l_Objective.position)

						if s_ClosestDistance == nil or s_DistanceToRef < s_ClosestDistance then
							s_ClosestDistance = s_DistanceToRef
							s_ClosestObjective = { name = l_Objective.name, path = l_Path }
						end
					end
				end
			elseif l_Objective.team ~= p_TeamId and l_Objective.isBase and not l_Objective.active and
				l_Objective.name == self.m_RushAttackingBase then -- Rush attacking team.
				table.insert(s_RushConvertedBases, l_Path)
			end

			s_PathsDone[l_Path] = true
			::continue_paths_loop::
		end
	end

	-- Spawn in base from time to time to get a vehicle.
	-- To-do: do this dependant of vehicle available.
	if not p_OnlyBase and #s_PossibleBases > 0 then
		local s_SpawnAtBase = false
		if #self.m_AvailableVehicles[p_TeamId] > 0 then
			s_SpawnAtBase = MathUtils:GetRandomInt(1, 100) <= Registry.BOT_SPAWN.PROBABILITY_BASE_VEHICLE_SPAWN
		else
			s_SpawnAtBase = MathUtils:GetRandomInt(1, 100) <= Registry.BOT_SPAWN.PROBABILITY_BASE_SPAWN
		end

		if s_SpawnAtBase then
			m_Logger:Write("spwawn at base because of randomness or vehicles")
			local s_PathIndex = s_PossibleBases[MathUtils:GetRandomInt(1, #s_PossibleBases)]
			return s_PathIndex, MathUtils:GetRandomInt(1, #m_NodeCollection:Get(nil, s_PathIndex))
		end
	end

	-- Spawn in order of priority.
	if #s_AttackedObjectives > 0 and (MathUtils:GetRandomInt(1, 100) < Registry.BOT_SPAWN.PROBABILITY_ATTACKED_SPAWN) then
		m_Logger:Write("spawn at attaced objective")
		return self:GetSpawnPathOfObjectives(s_AttackedObjectives)
	elseif s_ClosestObjective ~= nil and (MathUtils:GetRandomInt(1, 100) < Registry.BOT_SPAWN.PROBABILITY_CLOSEST_SPAWN) then
		m_Logger:Write("spwawn at closest objective")
		return self:GetSpawnPathOfObjectives({ s_ClosestObjective })
	elseif #s_PossibleObjectives > 0 then
		m_Logger:Write("spwawn at random objective")
		return self:GetSpawnPathOfObjectives(s_PossibleObjectives)
	elseif #s_PossibleBases > 0 then
		m_Logger:Write("spwawn at base")
		local s_PathIndex = s_PossibleBases[MathUtils:GetRandomInt(1, #s_PossibleBases)]
		return s_PathIndex, MathUtils:GetRandomInt(1, #m_NodeCollection:Get(nil, s_PathIndex))
	elseif #s_RushConvertedBases > 0 then
		local s_PathIndex = s_RushConvertedBases[MathUtils:GetRandomInt(1, #s_RushConvertedBases)]
		return s_PathIndex, MathUtils:GetRandomInt(1, #m_NodeCollection:Get(nil, s_PathIndex))
	else
		return 0, 0
	end
end

function GameDirector:GetSpawnPathOfObjectives(p_PossibleObjectives)
	local s_TempObject = p_PossibleObjectives[MathUtils:GetRandomInt(1, #p_PossibleObjectives)]
	local s_AvailableSpawnPaths = nil

	for _, l_Objective in pairs(self.m_AllObjectives) do
		if l_Objective.isSpawnPath and not l_Objective.isEnterVehiclePath then
			for _, name in pairs(l_Objective.name:split(" ")) do
				if name == s_TempObject.name then
					s_AvailableSpawnPaths = l_Objective.name
					break
				end
			end
			if s_AvailableSpawnPaths ~= nil then
				break
			end
		end
	end
	-- Check for spawn objectives.
	if s_AvailableSpawnPaths ~= nil then
		local s_AllObjectives = m_NodeCollection:GetKnownObjectives()
		local s_PathsWithObjective = s_AllObjectives[s_AvailableSpawnPaths]
		return s_PathsWithObjective[MathUtils:GetRandomInt(1, #s_PathsWithObjective)], 1
	else
		return s_TempObject.path, MathUtils:GetRandomInt(1, #m_NodeCollection:Get(nil, s_TempObject.path))
	end
end

function GameDirector:IsOnObjectivePath(p_Path)
	local s_CurrentPathFirst = m_NodeCollection:GetFirst(p_Path)

	if s_CurrentPathFirst.Data ~= nil and s_CurrentPathFirst.Data.Objectives ~= nil then
		if #s_CurrentPathFirst.Data.Objectives == 1 then
			return true
		end
	end

	return false
end

function GameDirector:IsBasePath(p_ObjectiveNames)
	for _, l_ObjectiveName in pairs(p_ObjectiveNames) do
		local s_Objective = self:_GetObjectiveObject(l_ObjectiveName)

		if s_Objective ~= nil and s_Objective.isBase then
			return true
		end
	end

	return false
end

-- -1 = destroyed objective.
-- 0 = all inactive.
-- 1 = partly inactive.
-- 2 = all active.
function GameDirector:GetEnableStateOfPath(p_ObjectiveNamesOfPath)
	local s_ActiveCount = 0

	for _, l_ObjectiveName in pairs(p_ObjectiveNamesOfPath) do
		local s_Objective = self:_GetObjectiveObject(l_ObjectiveName)

		if s_Objective ~= nil then
			if s_Objective.destroyed and #p_ObjectiveNamesOfPath == 1 and s_Objective.subObjective then
				return -1 -- Path of a destroyed MCOM
			elseif s_Objective.active then
				s_ActiveCount = s_ActiveCount + 1
			end
		end
	end

	if s_ActiveCount == 0 then
		return 0
	elseif s_ActiveCount < #p_ObjectiveNamesOfPath then
		return 1
	else
		return 2
	end
end

function GameDirector:UseVehicle(p_BotTeam, p_Objective)
	local s_TempObjective = self:_GetObjectiveObject(p_Objective)

	if s_TempObjective ~= nil and s_TempObjective.active and s_TempObjective.isEnterVehiclePath then
		-- s_TempObjective.active = false
		return true
	end

	return false
end

function GameDirector:IsVehicleEnterPath(p_Objective)
	local s_TempObjective = self:_GetObjectiveObject(p_Objective)

	if s_TempObjective ~= nil and s_TempObjective.isEnterVehiclePath then
		return true
	end

	return false
end

-- =============================================
-- Private Functions.
-- =============================================

function GameDirector:_RegisterRushEventCallbacks()
	if not Globals.IsRush then
		return
	end

	self.m_RushStageCounter = 0

	-- Register Event for Zone.
	local s_Iterator = EntityManager:GetIterator("ServerSyncedBoolEntity")
	local s_Entity = s_Iterator:Next()

	while s_Entity do
		s_Entity = Entity(s_Entity)

		if s_Entity.data.instanceGuid == Guid("F8D564AC-9235-4141-B320-297BEA370FD8") then
			s_Entity:RegisterEventCallback(function(p_Entity, p_EntityEvent)
				if p_EntityEvent.eventId == MathUtils:FNVHash("SetTrue") then
					self:OnRushZoneDisabled(p_Entity.instanceId)
				end
			end)
		end

		s_Entity = s_Iterator:Next()
	end
end

function GameDirector:_UpdateTimersOfMcoms(p_DeltaTime)
	for l_Objective, l_Timer in pairs(self.m_ArmedMcoms) do
		self.m_ArmedMcoms[l_Objective] = l_Timer + p_DeltaTime

		if self.m_ArmedMcoms[l_Objective] >= Registry.GAME_DIRECTOR.MCOMS_CHECK_CYCLE then
			self:OnMcomDestroyed(l_Objective)
		end
	end
end

function GameDirector:_InitObjectives()
	self.m_AllObjectives = {}

	for l_ObjectiveName, _ in pairs(m_NodeCollection:GetKnownObjectives()) do
		local s_Objective = {
			name = l_ObjectiveName,
			team = TeamId.TeamNeutral,
			position = nil,
			isAttacked = false,
			isBase = false,
			isSpawnPath = false,
			isEnterVehiclePath = false,
			destroyed = false,
			active = true,
			subObjective = false,
			assigned = {}
		}

		if string.find(l_ObjectiveName:lower(), "base") ~= nil then
			s_Objective.isBase = true

			if string.find(l_ObjectiveName:lower(), "us") ~= nil then
				s_Objective.team = TeamId.Team1
			else
				s_Objective.team = TeamId.Team2
			end
		end

		if string.find(l_ObjectiveName:lower(), "spawn") ~= nil then
			s_Objective.isSpawnPath = true
			s_Objective.active = false
		end

		if string.find(l_ObjectiveName:lower(), "vehicle") ~= nil then
			s_Objective.isEnterVehiclePath = true
			s_Objective.active = false

			if string.find(l_ObjectiveName:lower(), "us") ~= nil then
				s_Objective.team = TeamId.Team1
			elseif string.find(l_ObjectiveName:lower(), "ru") ~= nil then
				s_Objective.team = TeamId.Team2
			end
		end

		table.insert(self.m_AllObjectives, s_Objective)
	end

	self:_InitFlagTeams()
	self:_UpdateValidObjectives()
end

function GameDirector:_InitFlagTeams()
	if not Globals.IsConquest then -- Valid for all Conquest-types.
		return
	end

	local s_Iterator = EntityManager:GetIterator('ServerCapturePointEntity')
	---@type CapturePointEntity
	local s_Entity = s_Iterator:Next()

	while s_Entity ~= nil do
		s_Entity = CapturePointEntity(s_Entity)
		local s_ObjectiveName = self:_TranslateObjective(s_Entity.transform.trans, s_Entity.name)

		if s_ObjectiveName ~= "" then
			local s_Objective = self:_GetObjectiveObject(s_ObjectiveName)

			if not s_Objective.isBase then
				self:_UpdateObjective(s_ObjectiveName, {
					team = s_Entity.team,
					isAttacked = s_Entity.isAttacked
				})
			end
		end

		s_Entity = s_Iterator:Next()
	end
end

function GameDirector:_UpdateValidObjectives()
	if Globals.IsConquest then -- Nothing to do in conquest.
		return
	end

	self.m_RushStageCounter = self.m_RushStageCounter + 1

	if Globals.IsRush then
		local s_McomIndexA = -1
		local s_McomIndexB = -1
		if Globals.IsSquadRush then
			s_McomIndexA = self.m_RushStageCounter
		else -- Rush-Large.
			s_McomIndexA = (self.m_RushStageCounter * 2) - 1
			s_McomIndexB = self.m_RushStageCounter * 2
		end

		for _, l_Objective in pairs(self.m_AllObjectives) do
			local s_Fields = l_Objective.name:split(" ")
			local s_Active = false
			local s_SubObjective = false

			if l_Objective.isSpawnPath or l_Objective.isEnterVehiclePath then
				goto continue_objective_loop
			end

			if not l_Objective.isBase then
				if #s_Fields > 1 then
					local s_Index = tonumber(s_Fields[2])
					if s_Index == s_McomIndexA or s_Index == s_McomIndexB then
						s_Active = true
					end

					if #s_Fields > 2 then -- "MCOM N interact".
						s_SubObjective = true
					end
				end
			else
				if #s_Fields > 2 then
					local s_Index = tonumber(s_Fields[3])

					if s_Index == self.m_RushStageCounter then
						s_Active = true
					end

					if s_Index == self.m_RushStageCounter - 1 then
						self.m_RushAttackingBase = l_Objective.name
					end
				end
			end

			l_Objective.active = s_Active
			l_Objective.subObjective = s_SubObjective
			::continue_objective_loop::
		end
	end
end

function GameDirector:_SetVehicleObjectiveState(p_Position, p_Value)
	local s_Paths = m_NodeCollection:GetPaths()

	if s_Paths == nil then
		return
	end

	local s_ClosestDistance = 10
	local s_ClosestVehicleEnterObjective = nil

	for _, l_Waypoints in pairs(s_Paths) do
		if l_Waypoints[1] ~= nil and l_Waypoints[1].Data ~= nil and l_Waypoints[1].Data.Objectives ~= nil and
			#l_Waypoints[1].Data.Objectives == 1 then
			local s_ObjectiveObject = self:_GetObjectiveObject(l_Waypoints[1].Data.Objectives[1])

			if s_ObjectiveObject ~= nil and s_ObjectiveObject.active ~= p_Value and s_ObjectiveObject.isEnterVehiclePath then -- Only check disabled objectives.
				-- Check position of first and last node.
				local s_FirstNode = l_Waypoints[1]
				local s_LastNode = l_Waypoints[#l_Waypoints]
				local s_TempDistanceFirst = s_FirstNode.Position:Distance(p_Position)
				local s_TempDistanceLast = s_LastNode.Position:Distance(p_Position)
				local s_CloserDistance = s_TempDistanceFirst

				if s_TempDistanceLast < s_TempDistanceFirst then
					s_CloserDistance = s_TempDistanceLast
				end

				if s_CloserDistance < s_ClosestDistance then
					s_ClosestDistance = s_CloserDistance
					s_ClosestVehicleEnterObjective = s_ObjectiveObject
				end
			end
		end
	end

	if s_ClosestVehicleEnterObjective ~= nil then
		s_ClosestVehicleEnterObjective.active = p_Value
	end

	return s_ClosestVehicleEnterObjective
end

function GameDirector:_UpdateObjective(p_Name, p_Data)
	for _, l_Objective in pairs(self.m_AllObjectives) do
		if l_Objective.name == p_Name then
			for l_Key, l_Value in pairs(p_Data) do
				l_Objective[l_Key] = l_Value
			end

			break
		end
	end
end

function GameDirector:_GetDistanceFromObjective(p_Objective, p_Position)
	local s_Distance = math.huge

	if p_Objective == '' then
		return s_Distance
	end

	local s_AllObjectives = m_NodeCollection:GetKnownObjectives()
	local s_Paths = s_AllObjectives[p_Objective]

	for _, l_Path in pairs(s_Paths) do
		local s_Node = m_NodeCollection:Get(1, l_Path)

		if s_Node ~= nil and s_Node.Data.Objectives ~= nil then
			if #s_Node.Data.Objectives == 1 then
				s_Distance = p_Position:Distance(s_Node.Position)
				break
			end
		end
	end

	return s_Distance
end

function GameDirector:_TranslateObjective(p_Position, p_Name)
	if p_Name ~= nil and self.m_Translations[p_Name] ~= nil then
		return self.m_Translations[p_Name]
	end

	local s_AllObjectives = m_NodeCollection:GetKnownObjectives()
	local s_PathsDone = {}
	local s_ClosestObjective = nil
	local s_ClosestDistance = nil

	for l_Objective, l_Paths in pairs(s_AllObjectives) do
		for _, l_Path in pairs(l_Paths) do
			if s_PathsDone[l_Path] then
				goto continue_paths_loop
			end

			local s_Node = m_NodeCollection:Get(1, l_Path)

			if s_Node == nil or s_Node.Data.Objectives == nil or #s_Node.Data.Objectives ~= 1 then
				goto continue_paths_loop
			end

			-- Possible objective.
			local s_TempObject = self:_GetObjectiveObject(l_Objective)

			if s_TempObject == nil or (not s_TempObject.isSpawnPath and not s_TempObject.isEnterVehiclePath) then -- Or not s_TempObject.isBase.
				local s_Distance = p_Position:Distance(s_Node.Position)

				if s_ClosestDistance == nil or s_ClosestDistance > s_Distance then
					s_ClosestObjective = s_TempObject
					s_ClosestDistance = s_Distance
				end
			end

			s_PathsDone[l_Path] = true
			::continue_paths_loop::
		end
	end

	if p_Name ~= nil and s_ClosestObjective ~= nil then
		self.m_Translations[p_Name] = s_ClosestObjective.name
		s_ClosestObjective.position = p_Position
	end

	if s_ClosestObjective ~= nil then
		return s_ClosestObjective.name
	else
		return ""
	end
end

function GameDirector:_GetObjectiveObject(p_Name)
	for _, l_Objective in pairs(self.m_AllObjectives) do
		if l_Objective.name == p_Name then
			return l_Objective
		end
	end
end

function GameDirector:_GetSubObjectiveFromObj(p_Objective)
	for _, l_TempObjective in pairs(self.m_AllObjectives) do
		if l_TempObjective.subObjective then
			local s_Name = l_TempObjective.name:lower()

			if string.find(s_Name, p_Objective:lower()) ~= nil then
				return l_TempObjective.name
			end
		end
	end
end

function GameDirector:_GetObjectiveFromSubObj(p_SubObjective)
	for _, l_TempObjective in pairs(self.m_AllObjectives) do
		if not l_TempObjective.subObjective then
			local s_Name = l_TempObjective.name:lower()

			if string.find(p_SubObjective:lower(), s_Name) ~= nil then
				return l_TempObjective.name
			end
		end
	end
end

if g_GameDirector == nil then
	---@type GameDirector
	g_GameDirector = GameDirector()
end

return g_GameDirector

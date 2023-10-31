---@class Bot
---@overload fun(p_Player: Player):Bot
Bot = class('Bot')

require('__shared/Config')
require('PidController')

---@type NodeCollection
local m_NodeCollection = require('NodeCollection')
---@type PathSwitcher
local m_PathSwitcher = require('PathSwitcher')
---@type Vehicles
local m_Vehicles = require('Vehicles')
---@type Logger
local m_Logger = Logger('Bot', Debug.Server.BOT)

local m_BotAiming = require('Bot/BotAiming')
local m_BotAttacking = require('Bot/BotAttacking')
local m_BotMovement = require('Bot/BotMovement')
local m_BotWeaponHandling = require('Bot/BotWeaponHandling')

---@param p_Player Player
function Bot:__init(p_Player)
	-- Player Object.
	---@type Player
	self.m_Player = p_Player
	---@type string
	self.m_Name = p_Player.name
	---@type integer
	self.m_Id = p_Player.id

	-- Common settings.
	---@type BotSpawnModes
	self._SpawnMode = BotSpawnModes.NoRespawn
	---@type BotMoveModes
	self._MoveMode = BotMoveModes.Standstill
	self._ForcedMovement = false
	---@type BotKits|nil
	self.m_Kit = nil
	-- Only used in BotSpawner.
	---@type BotColors|integer|nil
	self.m_Color = nil
	---@type Weapon|nil
	self.m_ActiveWeapon = nil
	self.m_ActiveVehicle = nil
	---@type Weapon|nil
	self.m_Primary = nil
	---@type Weapon|nil
	self.m_Pistol = nil
	---@type Weapon|nil
	self.m_PrimaryGadget = nil
	---@type Weapon|nil
	self.m_SecondaryGadget = nil
	---@type Weapon|nil
	self.m_Grenade = nil
	---@type Weapon|nil
	self.m_Knife = nil
	self._Respawning = false

	-- Timers.
	self._UpdateTimer = 0.0
	self._UpdateFastTimer = 0.0
	self._SpawnDelayTimer = 0.0
	self._WayWaitTimer = 0.0
	self._VehicleWaitTimer = 0.0
	self._VehicleHealthTimer = 0.0
	self._VehicleSeatTimer = 0.0
	self._VehicleTakeoffTimer = 0.0
	self._WayWaitYawTimer = 0.0
	self._ObstacleSequenceTimer = 0.0
	self._StuckTimer = 0.0
	self._ShotTimer = 0.0
	self._ShootModeTimer = 0.0
	self._ReloadTimer = 0.0
	self._AttackModeMoveTimer = 0.0
	self._AttackTimer = 0.0
	self._MeleeCooldownTimer = 0.0
	self._ShootTraceTimer = 0.0
	self._ActionTimer = 0.0
	self._BrakeTimer = 0.0
	self._SpawnProtectionTimer = 0.0
	self._SidewardsTimer = 0.0
	self._KnifeWayPointTimer = 0.0

	-- Zombie Stuff
	self._SpeedFactorMovement = 1.0
	self._SpeedFactorAttack = 1.0
<<<<<<< Updated upstream
=======
	self._SpeedValue = 0.0
>>>>>>> Stashed changes
	self._HighJumpSpeed = 1.0
	self._RandomValueOfBot = 1.0
	self._GoForDirectAttackIfClose = true
	self._LastAttackPointDistance = 0.0
	self._ZombieSpeedValue = BotMoveSpeeds.NoMovement
	self._FollowTargetPose = false

	-- Shared movement vars.
	---@type BotMoveModes
	self.m_ActiveMoveMode = BotMoveModes.Standstill
	---@type BotMoveSpeeds
	self.m_ActiveSpeedValue = BotMoveSpeeds.NoMovement
	self.m_InVehicle = false
	self.m_OnVehicle = false

	---@class ActiveInput
	---@field value number
	---@field reset boolean

	---@type table<integer|EntryInputActionEnum, ActiveInput>
	self.m_ActiveInputs = {}

	-- Sidewards movement.
	self.m_YawOffset = 0.0
	self.m_StrafeValue = 0.0

	-- Advanced movement.
	---@type BotAttackModes
	self._AttackMode = BotAttackModes.RandomNotSet
	---@type BotActionFlags
	self._ActiveAction = BotActionFlags.NoActionActive
	-- To-do: add emmylua type.
	self._CurrentWayPoint = nil
	self._TargetYaw = 0.0
	self._TargetPitch = 0.0
	-- To-do: add emmylua type.
	self._TargetPoint = nil
	-- To-do: add emmylua type.
	self._NextTargetPoint = nil
	self._PathIndex = 0
	self._LastWayDistance = 0.0
	self._InvertPathDirection = false
	self._ExitVehicleActive = false
	self._ObstacleRetryCounter = 0
	---@type BotMoveSpeeds
	self._Objective = ''
	self._OnSwitch = false

	-- Shooting.
	self._Shoot = false
	---@type Player|nil
	self._ShootPlayer = nil
	self._ShootPlayerName = ''
	self._DistanceToPlayer = 0.0
	---@type BotWeapons
	self._WeaponToUse = BotWeapons.Primary
	-- To-do: add emmylua type.
	self._ShootWayPoints = {}
	self._meleeAttackState = 0;
	self._meleeActive = false;
	---@type Vec3[]
	self._KnifeWayPositions = {}

	---@type Player|nil
	self._TargetPlayer = nil
end

-- =============================================
-- Events
-- =============================================

-- Update frame (every Cycle).
-- Update very fast (0.05) ? Needed? Aiming?
-- Update fast (0.1) ? Movement, Reactions.
-- (Update medium? Maybe some things in between).
-- Update slow (1.0) ? Reload, Deploy, (Obstacle-Handling).

---@param p_DeltaTime number
function Bot:OnUpdatePassPostFrame(p_DeltaTime)
	if self.m_Player.soldier ~= nil then
		self.m_Player.soldier:SingleStepEntry(self.m_Player.controlledEntryId)
	end

	if self.m_Player.soldier == nil then              -- Player not alive.
		self._UpdateTimer = self._UpdateTimer + p_DeltaTime -- Reusage of updateTimer.

		if self._UpdateTimer > Registry.BOT.BOT_UPDATE_CYCLE then
			self:_UpdateRespawn(Registry.BOT.BOT_UPDATE_CYCLE)
			self._UpdateTimer = 0.0
		end
	else -- Player alive.
		-- Update timer.
		self._UpdateFastTimer = self._UpdateFastTimer + p_DeltaTime
		if self._UpdateFastTimer >= Registry.BOT.BOT_FAST_UPDATE_CYCLE then
			-- Increment slow timer.
			self._UpdateTimer = self._UpdateTimer + self._UpdateFastTimer
			-- Detect modes.
			self:_SetActiveVars()
			------------------ CODE OF BEHAVIOUR STARTS HERE ---------------------
			local s_Attacking = self._ShootPlayer ~= nil -- Can be either attacking or reviving or enter of a vehicle with a player.
			-- Sync slow code with fast code. Therefore, execute the slow code first.
			if self._UpdateTimer >= Registry.BOT.BOT_UPDATE_CYCLE then
				-- Common part.
				m_BotWeaponHandling:UpdateWeaponSelection(self)
				-- Differ attacking.
				if s_Attacking then
					m_BotAttacking:UpdateAttacking(self)
					self:_updateMeleeAttack()
					m_BotMovement:UpdateShootMovement(self)
				else
					m_BotMovement:UpdateNormalMovement(self)
					if self.m_Player.soldier == nil then
						return
					end
				end
				-- Common things.
				m_BotMovement:UpdateSpeedOfMovement(self)
				self:_UpdateInputs()
				self._UpdateTimer = 0.0
			end
			-- Fast code.
			if s_Attacking then
				m_BotAiming:UpdateAiming(self)
			else
				m_BotMovement:UpdateTargetMovement(self)
			end
			self._UpdateFastTimer = 0.0
		end
		-- Very fast code.
		m_BotMovement:UpdateYaw(self)
	end
end

-- =============================================
-- Functions
-- =============================================

-- =============================================
-- Public Functions
-- =============================================

function Bot:_updateMeleeAttack()
	if self._ShootPlayer and not self._meleeActive and self._ShootPlayer.soldier.worldTransform.trans:Distance(self.m_Player.soldier.worldTransform.trans) < 1 and self._meleeAttackState == 0 then
		self._meleeActive = true;
		self.activeWeapon = self.m_Knife;
		self.m_Player.input:SetLevel(EntryInputActionEnum.EIAFire, 0);
		self.m_Player.input:SetLevel(EntryInputActionEnum.EIASelectWeapon7, 1);
		self._meleeAttackState = 1;
	else
		if self._meleeAttackState == 1 then
			if self.m_Player.soldier.weaponsComponent.currentWeaponSlot == WeaponSlot.WeaponSlot_7 then
				self.m_Player.input:SetLevel(EntryInputActionEnum.EIASelectWeapon7, 0);
				self._meleeAttackState = 2;
				self._MeleeCooldownTimer = 0.2;
			end
		elseif self._meleeAttackState == 2 then
			if self._MeleeCooldownTimer <= 0 then
				Events:DispatchLocal("ServerDamagePlayer", self._ShootPlayer.name, self.m_Player.name, Config.DamageFactorKnife * 100, true);
				--self.player.input:SetLevel(EntryInputActionEnum.EIAMeleeAttack, 1); 	-- triggers taketown. not supported
				--self.player.input:SetLevel(EntryInputActionEnum.EIAFire, 1);			-- triggers taketown. not supported
				self._meleeAttackState = 3;
				self._MeleeCooldownTimer = 1.2;
			end
		elseif self._meleeAttackState == 3 then
			if self._MeleeCooldownTimer <= 0 then
				--self.player.input:SetLevel(EntryInputActionEnum.EIAMeleeAttack, 0);
				--self.player.input:SetLevel(EntryInputActionEnum.EIAFire, 0);
				self._meleeActive = false;
				self._meleeAttackState = 4;
				self._MeleeCooldownTimer = Config.MeleeAttackCoolDown - 1.2;
			end
		else --if self._meleeAttackState == 4 then
			if self._MeleeCooldownTimer <= 0 then
				self._meleeAttackState = 0;
			end
		end

		self._MeleeCooldownTimer = self._MeleeCooldownTimer - Registry.BOT.BOT_UPDATE_CYCLE;
	end
end

function Bot:UpdateObjective(p_Objective)
	-- local s_AllObjectives = m_NodeCollection:GetKnownObjectives()

	-- for l_Objective, _ in pairs(s_AllObjectives) do
	-- 	if l_Objective == p_Objective then
	-- 		self:SetObjective(p_Objective)
	-- 		break
	-- 	end
	-- end
end

---@return boolean
function Bot:IsReadyToAttack()
	if self._ShootPlayer == nil or self._ShootModeTimer > Config.BotMinTimeAttackOnePlayer then
		return true
	else
		return false
	end
end

---@param p_Player Player
---@param p_IgnoreYaw boolean
---@return boolean
function Bot:ShootAt(p_Player, p_IgnoreYaw)
	-- Don't shoot at teammates.
	if self.m_Player.teamId == p_Player.teamId or p_Player.soldier == nil or self.m_Player.soldier == nil then
		return false
	end

	local s_CurrentTargetPos = nil
	if self._TargetPlayer ~= nil and self._TargetPlayer.soldier ~= nil then
		s_CurrentTargetPos = self._TargetPlayer.soldier.worldTransform.trans:Clone()
	end
	local s_TargetPos = p_Player.soldier.worldTransform.trans:Clone()
	local s_PlayerPos = self.m_Player.soldier.worldTransform.trans:Clone()

	if s_CurrentTargetPos ~= nil and s_PlayerPos:Distance(s_CurrentTargetPos) < s_PlayerPos:Distance(s_TargetPos) then
		return false
	end


	self._TargetPlayer = p_Player

	-- Don't shoot if too far away.
	self._DistanceToPlayer = 0.0
	self._DistanceToPlayer = s_TargetPos:Distance(s_PlayerPos)

	-- Don't attack if too far away.
	if self._DistanceToPlayer > Config.MaxShootDistance then
		return false
	end

	if self._Shoot then
		self._ShootModeTimer = 0.0
		self._ShootPlayerName = p_Player.name
		self._ShootPlayer = nil
		self._KnifeWayPositions = {}
		self._ShootWayPoints = {}
		self._ShotTimer = 0.0
		table.insert(self._KnifeWayPositions, p_Player.soldier.worldTransform.trans:Clone())
		return true
	else
		self._ShootPlayerName = ''
		self._ShootPlayer = nil
		self._ShootModeTimer = Config.BotAttackDuration
		return false
	end
end

function Bot:ResetVars()
	self._SpawnMode = BotSpawnModes.NoRespawn
	self._ForcedMovement = false
	self._ActiveAction = BotActionFlags.NoActionActive
	self._PathIndex = 0
	self._Respawning = false
	self._Shoot = false
	self._TargetPlayer = nil
	self._ShootPlayer = nil
	self._ShootPlayerName = ''
	self._InvertPathDirection = false
	self._ExitVehicleActive = false
	self._ShotTimer = 0.0
	self._UpdateTimer = 0.0
	self._TargetPoint = nil
	self._NextTargetPoint = nil
	self._KnifeWayPositions = {}
	self._ShootWayPoints = {}
	self._SpawnDelayTimer = 0.0
	self._SpawnProtectionTimer = 0.0
	self._Objective = ''
	self._WeaponToUse = BotWeapons.Primary
	self._meleeActive = false;
	self._meleeAttackState = 0;
end

---@param p_Player Player
function Bot:SetVarsStatic(p_Player)
	self._SpawnMode = BotSpawnModes.NoRespawn
	self._ForcedMovement = true
	self._MoveMode = BotMoveModes.Standstill
	self._PathIndex = 0
	self._Respawning = false
	self._Shoot = false
	self._TargetPlayer = p_Player
end

---@param p_Player Player
---@param p_UseRandomWay boolean
---@param p_PathIndex integer
---@param p_CurrentWayPoint any To-do: add emmylua type
---@param p_InverseDirection boolean
function Bot:SetVarsWay(p_Player, p_UseRandomWay, p_PathIndex, p_CurrentWayPoint, p_InverseDirection)
	if p_UseRandomWay then
		self._SpawnMode = BotSpawnModes.RespawnRandomPath
		self._TargetPlayer = nil
		self._Shoot = Globals.AttackWayBots
		self._Respawning = Globals.RespawnWayBots
	else
		self._SpawnMode = BotSpawnModes.RespawnFixedPath
		self._TargetPlayer = p_Player
		self._Shoot = false
		self._Respawning = false
	end

	self.m_ActiveMoveMode = BotMoveModes.Paths
	self._PathIndex = p_PathIndex
	self._CurrentWayPoint = p_CurrentWayPoint
	self._InvertPathDirection = p_InverseDirection
end

---@return boolean
function Bot:IsStaticMovement()
	if self._ForcedMovement and (self._MoveMode == BotMoveModes.Standstill or
			self._MoveMode == BotMoveModes.Mirror or
			self._MoveMode == BotMoveModes.Mimic) then
		return true
	else
		return false
	end
end

---@param p_MoveMode BotMoveModes|integer
function Bot:SetMoveMode(p_MoveMode)
	self._ForcedMovement = true
	self._MoveMode = p_MoveMode
end

---@param p_Respawn boolean
function Bot:SetRespawn(p_Respawn)
	self._Respawning = p_Respawn
end

---@param p_Shoot boolean
function Bot:SetShoot(p_Shoot)
	self._Shoot = p_Shoot
end

function Bot:SetObjective(p_Objective)
	-- if self._Objective ~= p_Objective then
	-- 	self._Objective = p_Objective or ''
	-- 	local s_Point = m_NodeCollection:Get(self._CurrentWayPoint, self._PathIndex)

	-- 	if s_Point ~= nil then
	-- 		local s_Direction = m_NodeCollection:ObjectiveDirection(s_Point, self._Objective, self.m_InVehicle)
	-- 		self._InvertPathDirection = (s_Direction == 'Previous')
	-- 	end
	-- end
end

---@return string
function Bot:GetObjective()
	return self._Objective
end

---@return integer|BotSpawnModes
function Bot:GetSpawnMode()
	return self._SpawnMode
end

---@return integer
function Bot:GetWayIndex()
	return self._PathIndex
end

---@return integer
function Bot:GetPointIndex()
	return self._CurrentWayPoint
end

---@return Player|nil
function Bot:GetTargetPlayer()
	return self._TargetPlayer
end

---@return boolean
function Bot:IsInactive()
	if self.m_Player.soldier ~= nil or self.m_Player.corpse ~= nil then
		return false
	else
		return true
	end
end

---@return boolean
function Bot:IsStuck()
	if self._ObstacleSequenceTimer ~= 0 then
		return true
	else
		return false
	end
end

function Bot:ResetSpawnVars()
	self._SpawnDelayTimer = 0.0
	self._ObstacleSequenceTimer = 0.0
	self._ObstacleRetryCounter = 0
	self._LastWayDistance = 1000.0
	self._ShootPlayer = nil
	self._ShootPlayerName = ''
	self._ShootModeTimer = 0.0
	self._MeleeCooldownTimer = 0.0
	self._ShootTraceTimer = 0.0
	self._ReloadTimer = 0.0
	self._BrakeTimer = 0.0
	self._AttackTimer = 0.0
	self._AttackModeMoveTimer = 0.0
	self._AttackMode = BotAttackModes.RandomNotSet
	self._ShootWayPoints = {}

	self._ShotTimer = 0.0
	self._UpdateTimer = 0.0
	self._StuckTimer = 0.0
	self._SpawnProtectionTimer = 0.0
	self._TargetPoint = nil
	self._NextTargetPoint = nil
	self._ActiveAction = BotActionFlags.NoActionActive
	self._KnifeWayPositions = {}
	self._OnSwitch = false
	self._TargetPitch = 0.0
	self._Objective = '' -- Reset objective on spawn, as another spawn-point might have chosen...
	self._WeaponToUse = BotWeapons.Primary

	-- Reset all input-vars.
	---@type EntryInputActionEnum
	for l_EIA = 0, 36 do
		self.m_ActiveInputs[l_EIA] = {
			value = 0,
			reset = false,
		}
		self.m_Player.input:SetLevel(l_EIA, 0.0)
	end
end

---@param p_Player Player
function Bot:ClearPlayer(p_Player)
	if self._ShootPlayer == p_Player then
		self._ShootPlayer = nil
	end

	if self._TargetPlayer == p_Player then
		self._TargetPlayer = nil
	end

	local s_CurrentShootPlayer = PlayerManager:GetPlayerByName(self._ShootPlayerName)

	if s_CurrentShootPlayer == p_Player then
		self._ShootPlayerName = ''
	end
end

function Bot:Kill()
	self:ResetVars()

	if self.m_Player.soldier ~= nil then
		self.m_Player.soldier:Kill()
	end
end

function Bot:Destroy()
	self:ResetVars()
	self.m_Player.input = nil

	-- if self.m_Player.soldier ~= nil then
	-- 	self.m_Player.soldier:Destroy()
	-- end

	-- if self.m_Player.corpse ~= nil then
	-- 	self.m_Player.corpse:Destroy()
	-- end

	PlayerManager:DeletePlayer(self.m_Player)
	self.m_Player = nil
end

-- =============================================
-- Private Functions
-- =============================================

---@param p_DeltaTime number
function Bot:_UpdateLookAroundPassenger(p_DeltaTime)
	-- Move around a little.
	local s_Pos = self.m_Player.attachedControllable.transform.forward
	local s_AtanDzDx = math.atan(s_Pos.z, s_Pos.x)
	self._TargetYaw = (s_AtanDzDx > math.pi / 2) and (s_AtanDzDx - math.pi / 2) or (s_AtanDzDx + 3 * math.pi / 2)
	self._TargetPitch = 0.0

	self._VehicleWaitTimer = self._VehicleWaitTimer + p_DeltaTime

	if self._VehicleWaitTimer > 9.0 then
		self._VehicleWaitTimer = 0.0
	elseif self._VehicleWaitTimer >= 6.0 then
	elseif self._VehicleWaitTimer >= 3.0 then
		self._TargetYaw = self._TargetYaw - 1.0 -- 60° rotation left.
		self._TargetPitch = 0.2

		if self._TargetYaw < 0.0 then
			self._TargetYaw = self._TargetYaw + (2 * math.pi)
		end
	elseif self._VehicleWaitTimer >= 0.0 then
		self._TargetYaw = self._TargetYaw + 1.0 -- 60° rotation right.
		self._TargetPitch = -0.2

		if self._TargetYaw > (math.pi * 2) then
			self._TargetYaw = self._TargetYaw - (2 * math.pi)
		end
	end
end

---@param p_Input EntryInputActionEnum|integer
---@param p_Value number
function Bot:_SetInput(p_Input, p_Value)
	self.m_ActiveInputs[p_Input] = {
		value = p_Value,
		reset = p_Value == 0,
	}
end

function Bot:_UpdateInputs()
	---@type EntryInputActionEnum
	for i = 0, 36 do
		if self.m_ActiveInputs[i].reset then
			self.m_Player.input:SetLevel(i, 0)
			self.m_ActiveInputs[i].value = 0
			self.m_ActiveInputs[i].reset = false
		elseif self.m_ActiveInputs[i].value ~= 0 then
			self.m_Player.input:SetLevel(i, self.m_ActiveInputs[i].value)
			self.m_ActiveInputs[i].reset = true
		end
	end
end

---@param p_DeltaTime number
function Bot:_UpdateRespawn(p_DeltaTime)
	if not self._Respawning or self._SpawnMode == BotSpawnModes.NoRespawn then
		return
	end

	if self.m_Player.soldier == nil then
		-- Wait for respawn-delay gone.
		if self._SpawnDelayTimer < 0 then
			self._SpawnDelayTimer = self._SpawnDelayTimer + p_DeltaTime
		else
			self._SpawnDelayTimer = 0.0 -- Prevent triggering again.
			Events:DispatchLocal('Bot:RespawnBot', self.m_Name)
		end
	end
end

---@param p_Position Vec3
function Bot:FindVehiclePath(p_Position)
	local s_Node = g_GameDirector:FindClosestPath(p_Position, true, true, self.m_ActiveVehicle.Terrain)

	if s_Node ~= nil then
		-- Switch to vehicle.
		self._InvertPathDirection = false
		self._PathIndex = s_Node.PathIndex
		self._CurrentWayPoint = s_Node.PointIndex
		self._LastWayDistance = 1000.0
		-- Set path.
		self._TargetPoint = s_Node
		self._NextTargetPoint = s_Node
		-- Only for choppers.
		self._TargetHeightAttack = p_Position.y
	end
end

function Bot:UpdateVehicleMovableId()
	self:_SetActiveVars() -- Update if "on vehicle" or "in vehicle".

	if self.m_OnVehicle then
		self._VehicleMovableId = -1
	elseif self.m_InVehicle then
		self._ActiveVehicleWeaponSlot = 0
		self._VehicleMovableId = m_Vehicles:GetPartIdForSeat(self.m_ActiveVehicle, self.m_Player.controlledEntryId,
			self._ActiveVehicleWeaponSlot)

		if self.m_Player.controlledEntryId == 0 then
			self:FindVehiclePath(self.m_Player.soldier.worldTransform.trans)
		end
	end
end

---@param p_Entity ControllableEntity
---@param p_PlayerIsDriver boolean
---@return integer
---@return Vec3|nil
function Bot:_EnterVehicleEntity(p_Entity, p_PlayerIsDriver)
	return -2
end

---@param p_PlayerIsDriver boolean
---@return integer
---@return Vec3|nil
function Bot:_EnterVehicle(p_PlayerIsDriver)
	local s_Iterator = EntityManager:GetIterator('ServerVehicleEntity')
	local s_Entity = s_Iterator:Next()

	local s_ClosestEntity = nil
	local s_ClosestDistance = Registry.VEHICLES.MIN_DISTANCE_VEHICLE_ENTER

	while s_Entity ~= nil do
		s_Entity = ControllableEntity(s_Entity)
		local s_Position = s_Entity.transform.trans
		local s_Distance = s_Position:Distance(self.m_Player.soldier.worldTransform.trans)

		if s_Distance < s_ClosestDistance then
			s_ClosestEntity = s_Entity
			s_ClosestDistance = s_Distance
		end

		s_Entity = s_Iterator:Next()
	end

	if s_ClosestEntity ~= nil then
		return self:_EnterVehicleEntity(s_ClosestEntity, p_PlayerIsDriver)
	end

	return -3 -- No vehicle found.
end

---@param p_CurrentWayPoint integer|nil
---@return integer
function Bot:_GetWayIndex(p_CurrentWayPoint)
	local s_ActivePointIndex = 1

	if p_CurrentWayPoint == nil then
		p_CurrentWayPoint = s_ActivePointIndex
	else
		s_ActivePointIndex = p_CurrentWayPoint

		-- Direction handling.
		local s_CountOfPoints = #m_NodeCollection:Get(nil, self._PathIndex)
		local s_FirstPoint = m_NodeCollection:GetFirst(self._PathIndex)

		if s_ActivePointIndex > s_CountOfPoints then
			if s_FirstPoint.OptValue == 0xFF then -- Inversion needed.
				s_ActivePointIndex = s_CountOfPoints
				self._InvertPathDirection = true
			else
				s_ActivePointIndex = 1
			end
		elseif s_ActivePointIndex < 1 then
			if s_FirstPoint.OptValue == 0xFF then -- Inversion needed.
				s_ActivePointIndex = 1
				self._InvertPathDirection = false
			else
				s_ActivePointIndex = s_CountOfPoints
			end
		end
	end

	return s_ActivePointIndex
end

function Bot:AbortAttack()
	self.m_Player.input.zoomLevel = 0
	self._ShootPlayerName = ''
	self._ShootPlayer = nil
	self._ShootModeTimer = 0.0
	self._AttackMode = BotAttackModes.RandomNotSet
end

---@param p_FlagValue integer|BotActionFlags|nil
function Bot:_ResetActionFlag(p_FlagValue)
	if p_FlagValue == nil then
		self._ActiveAction = BotActionFlags.NoActionActive
	else
		if self._ActiveAction == p_FlagValue then
			self._ActiveAction = BotActionFlags.NoActionActive
		end
	end
end

function Bot:_SetActiveVars()
	if self._ShootPlayerName ~= '' then
		self._ShootPlayer = PlayerManager:GetPlayerByName(self._ShootPlayerName)
	else
		self._ShootPlayer = nil
	end

	if self._ForcedMovement then
		self.m_ActiveMoveMode = self._MoveMode
	end

	self.m_InVehicle = false
	self.m_OnVehicle = false
end

return Bot

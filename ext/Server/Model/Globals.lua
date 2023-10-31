---@class Globals
Globals = {
	WayPoints = {},
	ActiveTraceIndexes = 0,
	YawPerFrame = 0.0,

	IsTdm = false,
	IsSdm = false,
	IsScavenger = false,
	IsRush = false,
	IsRushWithoutVehicles = false,
	IsSquadRush = false,
	IsGm = false,
	IsConquest = false,
	IsDomination = false,
	IsAssault = false,
	NrOfTeams = 0,
	MaxPlayers = 0,
	GameMode = "",
	MaxBotsPerTeam = 0,
	RespawnDelay = 0,
	IsInputAllowed = false,
	IsInputRestrictionDisabled = false,
	RemoveKitVisuals = false,
	IgnoreBotNames = {},

	MaxHealthValue = 0,
	MinHealthValue = 0,
	MaxSpeedAttackValue = 0,
	MinSpeedAttackValue = 0,
	MaxJumpSpeedValue = 0,
	MinJumpSpeedValue = 0,
	DamageFactorZombies = 0,
	DistanceToSpawnBots = 0,
<<<<<<< Updated upstream
=======
	AmmoDropChance = 0,
>>>>>>> Stashed changes

	RespawnWayBots = false,    -- Used for the runtime respawn.
	AttackWayBots = false,     -- Used for the runtime attack.
	SpawnMode = SpawnModes.manual -- Used for the runtime spawn mode.
}



GM.Name = "Fight!"
GM.Author = "snale"
GM.Email = "N/A"
GM.Website = "N/A"
GM.Version = "0.1"

include("util.lua")
include("player_class/player_fight_base.lua")
include("player_class/player_fight_merc.lua")

function GM:Initialize()
end

-- Round states
ROUND_WAIT = 1
ROUND_PREP = 2
ROUND_ACTIVE = 3
ROUND_POST = 4

-- Win states
WIN_NONE = 1
WIN_RED = 2
WIN_BLUE = 3
WIN_TIMELIMIT = 4

-- Create teams
TEAM_BLUE = 1
TEAM_RED = 2
TEAM_SPEC = TEAM_SPECTATOR
TEAM_COUNT = 2

function GM:CreateTeams()
    team.SetUp(TEAM_RED, "Red", Color(0, 120, 174, 255), true)
    team.SetUp(TEAM_BLUE, "Blue", Color(192, 20, 27, 255), true)
    team.SetUp(TEAM_SPEC, "Spectators", Color(200, 200, 0, 255), true)

    -- Not that we use this, but feels good
    team.SetSpawnPoint(TEAM_RED, "info_player_deathmatch")
    team.SetSpawnPoint(TEAM_BLUE, "info_player_deathmatch")
    team.SetSpawnPoint(TEAM_SPEC, "info_player_deathmatch")
end

function GM:PlayerNoClip()
    return false
end

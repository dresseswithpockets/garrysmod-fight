AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("player_extensions_shared.lua")
include("shared.lua")
include("player_extensions_shared.lua")
include("player_extensions.lua")
DEFINE_BASECLASS("gamemode_base")

--
local fight_min_win_score = CreateConVar("fight_min_score_to_win", "5", FCVAR_NONE, "The minimum score necessary for a team to win.", 1, nil)
local fight_min_win_lead = CreateConVar("fight_min_score_lead_to_win", "2", FCVAR_NONE, "The minimum lead a team must have in order to win. i.e A has 5 pts, B has 3 pts, A wins. If B has 4 pts, no the round goes on.", 1, nil)
local fight_round_time = CreateConVar("fight_round_time", "7", FCVAR_NONE, "The total number in minutes that a round can last for, before granting a win by default or a sudden death.", 1, nil)
local fight_sudden_death = CreateConVar("fight_sudden_death_if_default", "1", FCVAR_NONE, "If the round timer ends and a win will be granted by default, the round becomes sudden death and the first point earned grants a win.", 0, 1)
local fight_min_team_size = CreateConVar("fight_min_team_size", "1", FCVAR_NONE, "The minimum number of players necessary for each team before a round can start", 0, nil)

--
util.AddNetworkString("FIGHT_RoundState")

function GM:Initialize()
    MsgN("Fight! gamemode initializing.")
    -- Force friendly fire to be enabled. If it is off, we do not get lag compensation.
    RunConsoleCommand("mp_friendlyfire", "1")
    GAMEMODE.WinState = WIN_NONE
    GAMEMODE.RoundState = ROUND_WAIT
    -- Delay reading of cvars until config has definitely loaded (see GM:InitCvars)
    GAMEMODE.cvarInit = false
    SetGlobalFloat("fight_round_end", -1)
    -- For the paranoid
    math.randomseed(os.time())
    WaitForPlayers()
end

-- Used to do this in Initialize, but server cfg has not always run yet by that
-- point.
function GM:InitCvars()
    MsgN("TTT initializing convar settings...")
    -- Initialize game state that is synced with client
    GAMEMODE:SyncGlobals()
    self.cvarInit = true
end

-- Convar replication is broken in gmod, so we do this.
-- I don't like it any more than you do, dear reader.
function GM:SyncGlobals()
end

-- TODO: anything i need to repl to client here?
function GetRoundState()
    return GAMEMODE.RoundState
end

function SetRoundState(state)
    GAMEMODE.RoundState = state
    -- TODO: SCORE:RoundStateChange
    SendRoundState(state)
end

function SendRoundState(state, ply)
    net.Start("FIGHT_RoundState")
    net.WriteUInt(state, 3)
    if ply then return net.Send(ply) end

    return net.Broadcast()
end

local function EnoughPlayers()
    local ready = 0

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:ShouldSpawn() then
            ready = ready + 1
        end
    end

    return ready >= fight_min_team_size:GetInt() * TEAM_COUNT
end

-- "wait_for_players" timer callback, see: WaitForPlayers()
function WaitForPlayersCallback()
    if GetRoundState() == ROUND_WAIT and EnoughPlayers() then
        timer.Create("wait_for_prep", 1, 1, PrepareRound)
        timer.Stop("wait_for_players")
    end
end

function WaitForPlayers()
    SetRoundState(ROUND_WAIT)

    if not timer.Start("wait_for_players") then
        timer.Create("wait_for_players", 2, 0, WaitForPlayersCallback)
    end
end

-- When a player initially spawns after mapload, everything is a bit strange;
-- just making them spectator for some reason does not work right. Therefore,
-- we regularly check for these broken spectators while we wait for players
-- and immediately fix them.
function FixSpectators()
    for k, ply in ipairs(player.GetAll()) do
        if ply:IsSpec() and not ply:GetRagdollSpec() and ply:GetMoveType() < MOVETYPE_NOCLIP then
            ply:Spectate(OBS_MODE_ROAMING)
        end
    end
end

-- "check_for_win" timer callback, see StartWinChecks()
local function CheckForWinCallback()
    if GetRoundState() == ROUND_ACTIVE then
        local win = hook.Call("FIGHTCheckForWin", GAMEMODE)

        if win != WIN_NONE then
            EndRound(win)
        end
    end
end

function StartWinChecks()
    if not timer.Start("check_for_win") then
        timer.Create("check_for_win", 1, 0, CheckForWinCallback)
    end
end

function StopWinChecks()
    timer.Stop("check_for_win")
end

local function CleanUp()
end

-- TODO: clean up!!!
local function SpawnEntities()
end

-- TODO: spawn entities on the map relevant to Fight!
local function StopRoundTimers()
    timer.Stop("wait_for_prep")
    timer.Stop("prepare_to_begin")
    timer.Stop("end_to_prep")
    timer.Stop("check_for_win")
end

local function CheckForAbort()
    if not EnoughPlayers() then
        -- TODO: localization (ttt's LANG)
        MsgN("round_minplayers")
        StopRoundTimers()
        WaitForPlayers()

        return true
    end

    return false
end

function PrepareRound()
    if CheckForAbort() then return end
    -- TODO: DelayRoundStartForVote?
    -- TODO: respawning weapons?
    CleanUp()
    GAMEMODE.MapWin = WIN_NONE
    -- TODO: SCORE:Reset?
    -- TODO: set player models?
    if CheckForAbort() then return end
    -- schedule round state
    local ptime = GetConVar("fight_round_prep_time"):GetInt()
    -- Piggyback on "round end" time global var to show end of phase timer
    SetRoundEnd(CurTime() + ptime)
    timer.Create("prepare_to_begin", ptime, 1, BeginRound)
    -- TODO: localization
    MsgN("round_begintime", ptime)
    SetRoundState(ROUND_PREP)
    -- Delay spawning until next frame to avoid ent overload
    timer.Simple(0.01, SpawnEntities)
    -- TODO: see TTT_ClearClientState
    -- TODO: see TTTPrepareRound
    -- TODO: see TTT.TriggerRoundStateOutputs(ROUND_PREP)
end

function SetRoundEnd(endtime)
    SetGlobalFloat("fight_round_end", endtime)
end

function SpawnWillingPlayers(deadOnly)
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:SpawnForRound(deadOnly)
        end
    end
end

local function InitRoundEndTime()
    local endtime = CurTime() + GetConVar("fight_round_time"):GetInt() * 60
    SetRoundEnd(endtime)
end

function BeginRound()
    GAMEMODE:SyncGlobals()
    if CheckForAbort() then return end

    InitRoundEndTime()
    if CheckForAbort() then return end

    -- respawn people who died during prep
    SpawnWillingPlayers(true)

    -- TODO: ents.TTT.RemoveRagdolls(true)

    if CheckForAbort() then return end

    SelectTeams()
    -- TODO: LANG.Msg("round_selected")
    SendFullStateUpdate()

    -- Edge case where a player joins just as the round starts and is picked as
    -- traitor, but for whatever reason does not get the traitor state msg. So
    -- re-send after a second just to make sure everyone is getting it.
    timer.Simple(1, SendFullStateUpdate)
    timer.Simple(10, SendFullStateUpdate)

    -- TODO: SCORE:HandleSelection()

    -- TODO: Give the StateUpdate messages ample time to arrive
    -- TODO: timer.Simple(1.5, TellTraitorsAboutTraitors)
    -- TODO: timer.Simple(2.5, ShowRoundStartPopup)

    StartWinChecks()
    GAMEMODE.RoundStartTime = CurTime()

    SetRoundState(ROUND_ACTIVE)
    -- TODO: LANG.Msg("round_started")
    ServerLog("Round proper has begun...\n")

    GAMEMODE:UpdatePlayerLoads() -- needs to happen when round_active

    hook.Call("FIGHTBeginRound")

    -- TODO: ents.TTT.TriggerRoundStateOutputs(ROUND_BEGIN)
end

function PrintResultMessage(type)
    ServerLog("Round ended.\n")
    if type == WIN_TIMELIMIT then
       -- TODO: LANG.Msg("win_time")
       ServerLog("Result: timelimit reached, stalemate.\n")
    elseif type == WIN_BLUE then
       -- TODO: LANG.Msg("win_traitor")
       ServerLog("Result: blue wins.\n")
    elseif type == WIN_RED then
       -- TODO: LANG.Msg("win_red")
       ServerLog("Result: red wins.\n")
    else
       ServerLog("Result: unknown victory condition!\n")
    end
end

-- TODO: Check for map switch

function EndRound(type)
    PrintResultMessage(type)

    -- first handle round end
    SetRoundState(ROUND_POST)

    local ptime = GetConVar("fight_post_round_time"):GetInt()
    -- TODO: LANG.Msg("win_showreport", {num = ptime})
    timer.Create("end_to_prepare", ptime, 1, PrepareRound)

    -- Piggyback on "round end" time global var to show end of phase timer
    SetRoundEnd(CurTime() + ptime)

    -- Stop checking for wins
    StopWinChecks()

    -- TODO: We may need to start a timer for a mapswitch, or start a vote
    -- CheckForMapSwitch()

    -- TODO: now handle potentially error prone scoring stuff
    -- register an end of round event
    -- SCORE:RoundComplete(type)
    -- update player scores
    -- SCORE:ApplyEventLogScores(type)
    -- send the clients the round log, players will be shown the report
    -- SCORE:StreamToClients()

    -- server plugins might want to start a map vote here or something
    -- these hooks are not used by TTT internally
    hook.Call("FIGHTEndRound", GAMEMODE, type)

    -- TODO: ents.TTT.TriggerRoundStateOutputs(ROUND_POST, type) ?
end

function GM:MapTriggeredEnd(wintype)
    self.MapWin = wintype
end

function GM:FIGHTCheckForWin()
    if GAMEMODE.MapWin != WIN_NONE then
        local mw = GAMEMODE.MapWin
        GAMEMODE.MapWin = WIN_NONE
        return mw
    end

    local redScore = team.GetScore(TEAM_RED)
    local blueScore = team.GetScore(TEAM_BLUE)
    local minScore = fight_min_win_score:GetInt()
    local minScoreDiff = fight_min_win_lead:GetInt()
    local roundEnd = GetGlobalFloat("fight_round_end", 0)
    local suddenDeath = fight_sudden_death:GetBool()

    -- if no team is winning, then default to WIN_TIMEOUT for
    -- when we check to see if we are timing out (see below!)
    local leadingWin = WIN_TIMEOUT
    local leadingScore = 0
    local scoreDiff = 0
    if redScore > blueScore then
        leadingWin = WIN_RED
        leadingScore = redScore
        scoreDiff = redScore - blueScore
    elseif blueScore > redScore then
        leadingWin = WIN_BLUE
        leadingScore = blueScore
        scoreDiff = blueScore - redScore
    end

    -- TODO: support sudden death kill = instant win
    -- if we're timing out of the round, then default to the leading
    -- team, or WIN_TIMEOUT (see above)
    if not suddenDeath and CurTime() >= roundEnd then
        return leadingWin
    end

    -- if we meet the criteria for min score and score difference then
    -- the leading team will win!
    if leadingTeam and leadingScore >= minScore and scoreDiff >= minScoreDiff then
        return leadingWin
    end

    return WIN_NONE
end

function SelectTeams()
    for i,ply in ipairs(player.GetAll()) do
        if IsValid(ply) and (not ply:IsSpec()) then
            if i % 2 == 0 then
                ply:SetTeam(TEAM_BLUE)
            else
                ply:SetTeam(TEAM_RED)
            end
        end
    end
end

local function ForceRoundRestart(ply, command, args)
    -- ply is nil on dedicated server console
    if (not IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then
        --TODO: LANG.Msg("round_restart")

        StopRoundTimers()

        -- do prep
        PrepareRound()
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "You must be a GMod Admin or SuperAdmin on the server to use this command, or sv_cheats must be enabled.")
    end
end
concommand.Add("fight_round_restart", ForceRoundRestart)

function ShowVersion(ply)
    local text = Format("This is Fight! version %s\n", GAMEMODE.Version)
    if IsValid(ply) then
       ply:PrintMessage(HUD_PRINTNOTIFY, text)
    else
       Msg(text)
    end
end
concommand.Add("fight_version", ShowVersion)

function GM:PlayerSpawn(ply, transition)
    print(ply:Nick() .. " has spawned!")
    player_manager.SetPlayerClass(ply, "player_fight_merc")
    BaseClass.PlayerSpawn(self, ply, transiton)
end

function GM:PostGamemodeLoaded()
    -- if there are already players, respawn them (or set them to spectate?)
    for i, ply in ipairs(player.GetAll()) do
        ply:Spawn()
    end
end

function GM:GetFallDamage(ply, speed)
    return 0
end

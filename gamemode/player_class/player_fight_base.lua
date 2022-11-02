AddCSLuaFile()
DEFINE_BASECLASS("player_default")

local PLAYER = {}

PLAYER.DisplayName          = "Fight Base Class"

-- "average" base stats
PLAYER.SlowWalkSpeed        = 150        -- 
PLAYER.WalkSpeed            = 300        -- 
PLAYER.RunSpeed             = 300        -- 
PLAYER.CrouchedWalkSpeed    = 0.3        -- Multiply move speed by this when crouching
PLAYER.DuckSpeed            = 0.3        -- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed          = 0.3        -- How fast to go from ducking, to not ducking
PLAYER.JumpPower            = 225        -- How powerful our jump should be
PLAYER.CanUseFlashlight     = true        -- Can we use the flashlight
PLAYER.MaxHealth            = 60        -- Max health we can have
PLAYER.MaxArmor             = 0        -- Max armor we can have
PLAYER.StartHealth          = 60        -- How much health we start with
PLAYER.StartArmor           = 0            -- How much armour we start with
PLAYER.DropWeaponOnDie      = false        -- Do we drop our weapon when we die
PLAYER.TeammateNoCollide    = true        -- Do we collide with teammates or run straight through them
PLAYER.AvoidPlayers         = true        -- Automatically swerves around other players
PLAYER.UseVMHands           = true        -- Uses viewmodel hands

PLAYER.CanDash = false
PLAYER.DashTime = 0.25
PLAYER.DashCooldown = 3.5
PLAYER.DashSpeedMultiplier = 3.75
PLAYER.PostDashVelocityMultiplier = 0.5

-- AccessorFunc(PLAYER, "CanDash", "CanDash", FORCE_BOOL)
-- AccessorFunc(PLAYER, "DashTime", "DashTime", FORCE_NUMBER)
-- AccessorFunc(PLAYER, "DashCooldown", "DashCooldown", FORCE_NUMBER)
-- AccessorFunc(PLAYER, "DashSpeedMultiplier", "DashSpeedMultiplier", FORCE_NUMBER)
-- AccessorFunc(PLAYER, "PostDashVelocityMultiplier", "PostDashVelocityMultiplier", FORCE_NUMBER)

function PLAYER:SetupDataTables()
    self.Player:NetworkVar("Bool", 0, "Dashing")
    self.Player:NetworkVar("Bool", 1, "DashOnCooldown")
    self.Player:NetworkVar("Float", 2, "DashTimeEnd")
    self.Player:NetworkVar("Float", 3, "DashCooldownEnd")
    self.Player:NetworkVar("Vector", 4, "DashDirection")

    self.Player:NetworkVar("Bool", 5, "CanDash")
    self.Player:NetworkVar("Float", 6, "DashTime")
    self.Player:NetworkVar("Float", 7, "DashCooldown")
    self.Player:NetworkVar("Float", 8, "DashSpeedMultiplier")
    self.Player:NetworkVar("Float", 9, "PostDashVelocityMultiplier")

    if SERVER then
        self.Player:SetDashing(false)
        self.Player:SetDashOnCooldown(false)
        self.Player:SetDashTimeEnd(CurTime())
        self.Player:SetDashCooldownEnd(CurTime())
        self.Player:SetDashDirection(Vector())

        self.Player:SetCanDash(self.CanDash)
        self.Player:SetDashTime(self.DashTime)
        self.Player:SetDashCooldown(self.DashCooldown)
        self.Player:SetDashSpeedMultiplier(self.DashSpeedMultiplier)
        self.Player:SetPostDashVelocityMultiplier(self.PostDashVelocityMultiplier)
    end
end

function PLAYER:GetDashFraction()
    local to = self:GetDashTimeEnd()
    local from = to - self:GetDashTime()
    return (CurTime() - from) / (to - from)
end

function PLAYER:Loadout()
    -- the base fight class does not have any weapons/loadout
end

function PLAYER:StartMove(mv, cmd)
    if SERVER and self.Player:GetCanDash() then
        self:StartMoveDash(mv, cmd)
    end

    return true
end

function PLAYER:StartMoveDash(mv, cmd)
    if self.Player:GetDashOnCooldown() and CurTime() >= self.Player:GetDashCooldownEnd() then
        self.Player:SetDashOnCooldown(false)
    end

    if (not self.Player:GetDashing()) and
        (not self.Player:GetDashOnCooldown()) and
        (cmd:GetSideMove() != 0 or cmd:GetForwardMove() != 0) and
        cmd:KeyDown(IN_SPEED)
        then

        self.Player:SetDashing(true)

        local viewAngles = Angle(0, cmd:GetViewAngles().y, 0)
        self.Player:SetDashDirection((viewAngles:Forward() * cmd:GetForwardMove() + 
                                viewAngles:Right() * cmd:GetSideMove()):GetNormalized())
        self.Player:SetDashTimeEnd(CurTime() + self.Player:GetDashTime())
    end

    if self.Player:GetDashing() then
        if CurTime() >= self.Player:GetDashTimeEnd() then
            self.Player:SetDashing(false)
            self.Player:SetDashOnCooldown(true)
            self.Player:SetDashCooldownEnd(CurTime() + self.Player:GetDashCooldown())
            local vel = mv:GetVelocity()
            vel.x = vel.x * self.Player:GetPostDashVelocityMultiplier()
            vel.y = vel.y * self.Player:GetPostDashVelocityMultiplier()
            mv:SetVelocity(mv:GetVelocity() * self.Player:GetPostDashVelocityMultiplier())
        else
            local walkSpeed = self.Player:GetDashSpeedMultiplier() * self.WalkSpeed
            local vel = self.Player:GetDashDirection() * walkSpeed
            -- retain vertical velocity (allows for falling/jumping/etc)
            -- this also means we'll often stay attached to the ground on slopes
            vel.z = mv:GetVelocity().z
            mv:SetVelocity(vel)
            mv:SetSideSpeed(vel.x)
            mv:SetForwardSpeed(vel.y)
        end
    end
end

player_manager.RegisterClass("player_fight_base", PLAYER, "player_default")


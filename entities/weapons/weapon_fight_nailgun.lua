
AddCSLuaFile()

SWEP.Base = "weapon_fight_base"
SWEP.HoldType = "smg"

SWEP.PrintName = "Nailgun"

SWEP.Purpose = "Fight! Merc's Primary Weapon"
SWEP.Instructions = "Primary fire shoots medium-speed projectiles. Alt fire fires a very short range hitscan shotgun blast that destroys projectiles."

SWEP.ViewModel = Model("models/weapons/c_smg1.mdl")
SWEP.WorldModel = Model("models/weapons/w_smg1.mdl")

SWEP.Weight = 6

SWEP.Primary.Sound = Sound("Weapon_Smg1.Single")
SWEP.Primary.Recoil = 2.0
SWEP.Primary.Damage = 2
SWEP.Primary.Speed = 700
SWEP.Primary.Delay = 0.1
SWEP.Primary.Cone = 0.15

SWEP.Primary.Ammo = "SMG1"

SWEP.Secondary.EmptySound = Sound("Weapon_Smg1.Empty")
SWEP.Secondary.Sound = Sound("AlyxEMP.Discharge")
SWEP.Secondary.Ammo = "SMG1_Grenade"
SWEP.Secondary.Automatic = false

-- primary attack functions

function SWEP:FirePrimary()
    self:ShootNail(
        self.Primary.Damage,
        self.Primary.Speed,
        self.Primary.Recoil,
        self.Primary.Count,
        self.Primary.Cone)
end

function SWEP:ShootNail(damage, speed, recoil, count, cone)
    self:GetOwner():MuzzleFlash()
    self:GetOwner():SetAnimation(PLAYER_ATTACK1)

    count = count or 1
    cone = cone or 0.01

    if SERVER then
        local ply = self:GetOwner()
        if not IsValid(ply) then
            return
        end
        local angle = ply:EyeAngles()
        local source = ply:GetPos() +
                        (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset()) +
                        (angle:Forward() * 10) +
                        (angle:Right() * 3) +
                        (angle:Up() * -2)
        local target = ply:GetEyeTraceNoCursor().HitPos
        local targetAngle = (target - source):Angle()
        
        for i = 0, 0, count do
            local spreadX = util.SharedRandom(self:GetClass(),-cone,cone,0) * recoil
            local spreadY = util.SharedRandom(self:GetClass(),-cone,cone,1) * recoil
            local spreadAngle = targetAngle + Angle(spreadX, spreadY, 0)
            local vel = spreadAngle:Forward() * speed

            local nail = self:CreateNail(source, spreadAngle, vel, ply)
            nail:SetDamage(damage)
        end
    end
end

function SWEP:CreateNail(pos, angle, velocity, ply)
    local nail = ents.Create("fight_nail_proj")
    if not IsValid(nail) then
        return
    end

    nail:SetPos(pos)
    nail:SetAngles(angle)

    nail:SetOwner(ply)
    --nail:SetThrower(ply)

    nail:Spawn()
    nail:PhysWake()

    local phys = nail:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(velocity)
    end

    return nail
end

-- secondary attack functions

function SWEP:FireSecondary()
    self:ShootNeutralizer(
        self.Secondary.Damage,
        self.Secondary.Speed,
        self.Secondary.Recoil,
        self.Secondary.Count,
        self.Secondary.Cone)
end

function SWEP:ShootNeutralizer(cone)
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    ply:MuzzleFlash()
    ply:SetAnimation(PLAYER_ATTACK1)

    if SERVER then
        -- util.Effect with TeslaZap? between weapon and each projectile destroyed
        local angle = ply:EyeAngles()
        local source = ply:GetPos() +
                        (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset()) +
                        (angle:Right() * 3) +
                        (angle:Up() * -2)
        local effectSource = source + (angle:Forward() * 10)
        local target = ply:GetEyeTraceNoCursor().HitPos
        local targetAngle = (target - source):Angle()
        
        local vec = targetAngle:Forward()
        local cosine = math.cos(math.rad(15))
        local entities = ents.FindInCone(source, vec, 80, cosine)

        for i,ent in ipairs(entities) do
            if (not IsValid(ent)) or
                ent:IsWorld() or
                ent:IsPlayer() or
                ent:IsNPC() or
                ent:GetCollisionGroup() != COLLISION_GROUP_PROJECTILE then
                    continue
                end

            ent:Remove()
        end

        local sparkEffect = EffectData()
        sparkEffect:SetOrigin(effectSource)
        sparkEffect:SetScale(1)
        sparkEffect:SetRadius(1)
        sparkEffect:SetMagnitude(1.2)
        util.Effect("Sparks", sparkEffect, true, true)
    end
end

function SWEP:CreateNeutralizer(pos, angle, ply)
    local neutralizer = ents.Create("fight_merc_neut_cone")
    if not IsValid(neutralizer) then
        return
    end

    neutralizer:SetPos(pos)
    neutralizer:SetAngles(angle)

    neutralizer:SetOwner(ply)

    neutralizer:Spawn()
    neutralizer:PhysWake()

    local phys = neutralizer:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(velocity)
    end

    return neutralizer
end

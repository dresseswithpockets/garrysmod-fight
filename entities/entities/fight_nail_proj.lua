AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/props_2fort/nail001.mdl")
ENT.Spawnable = true

AccessorFunc(ENT, "damage", "Damage", FORCE_NUMBER)

function ENT:SetupDataTables()
end

function ENT:Initialize()
    self:SetModel(self.Model)

    if CLIENT then
        local m = Matrix()
        m:Scale(Vector(1, 1, 1))
        m:Rotate(Angle(0, 180, 0))
        self:EnableMatrix("RenderMultiply", m)
    end

    self:PhysicsInit(SOLID_VPHYSICS)
    if SERVER then
        self:SetGravity(0)
        self:SetFriction(1.0)
        self:SetElasticity(0.45)

        self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
        local phys = self:GetPhysicsObject()
        phys:EnableGravity(false)
        phys:SetMass(0)

        self:NextThink(CurTime())
    end
end

function ENT:Think()
end

function ENT:HitOther(other, data)

    if SERVER then
        local damage = DamageInfo()
        damage:SetDamage(self:GetDamage())
        damage:SetAttacker(self:GetOwner())
        damage:SetInflictor(self)
        damage:SetDamageForce(self:EyeAngles():Forward())
        damage:SetDamagePosition(self:GetPos())
        damage:SetDamageType(DMG_DIRECT)
        other:TakeDamageInfo(damage)
    end

    self.HitOther = util.noop
end

function ENT:PhysicsCollide(data, collider)
    local other = data.HitEntity
    if not IsValid(other) and not other:IsWorld() then return end

    if other:IsPlayer() or other:IsNPC() then
        local owner = self:GetOwner()
        if owner == other then return end

        self:HitOther(other, data)
        self:Remove()
        return true
    else
        -- todo: emit hit sound?
        -- todo: add decal?

        local bullet = {}
        bullet.Num = count
        bullet.Src = self:GetPos()
        bullet.Dir = self:GetAngles():Forward()
        bullet.Spread = Vector(0, 0, 0)
        bullet.Tracer = 0
        bullet.Force = self:EyeAngles():Forward()
        bullet.Damage = self:GetDamage()
        self:GetOwner():FireBullets(bullet)

        self:Remove()
        return true
    end
end

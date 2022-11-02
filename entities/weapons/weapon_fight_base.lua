AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.HoldType = "pistol"

SWEP.Category = "Fight!"
SWEP.Spawnable = false

SWEP.AdminOnly = false
SWEP.PrintName = "Merc Weapon Base"
SWEP.m_WeaponDeploySpeed = 1

SWEP.Author = "snale"
SWEP.Purpose = "Fight! Weapon Base"
SWEP.Instructions = ""

SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.ViewModelFlip = false
SWEP.ViewModelFLip1 = false
SWEP.ViewModelFlip2 = false
SWEP.ViewModelFOV = 62
SWEP.WorldModel = "models/weapons/w_357.mdl"

SWEP.AutoSwitchFrom = true
SWEP.AutoSwitchTo = true
SWEP.Weight = 5

SWEP.BobScale = 1
SWEP.SwayScale = 1

SWEP.BounceWeaponIcon = true
SWEP.DrawWeaponInfoBox = true
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.RenderGroup = RENDERGROUP_OPAQUE

SWEP.Slot = 0
SWEP.SlotPos = 10

-- SWEP.SpeechBubbleLid = surface.GetTextureID("gui/speech_lid")
-- SWEP.WepSelectIcon = surface.GetTextureID("weapons/swep")

SWEP.CSMuzzleFlashes = false
SWEP.CSMuzzleX = false

-- primary fire properties

SWEP.Primary = {}
SWEP.Primary.EmptySound = Sound("Weapon_Pistol.Empty")
SWEP.Primary.EmptySoundLevel = 1.0
SWEP.Primary.EmptyDelay = 0.1

SWEP.Primary.Enable = true
SWEP.Primary.Sound = Sound("Weapon_357.Single")
SWEP.Primary.SoundLevel = 0.25
SWEP.Primary.Recoil = 15.0
SWEP.Primary.Damage = 0
SWEP.Primary.Speed = 0
SWEP.Primary.Count = 1
SWEP.Primary.Delay = 1.0
SWEP.Primary.AmmoConsumed = 1

SWEP.Primary.Ammo = "none"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true


-- secondary fire properties

SWEP.Secondary = {}
SWEP.Secondary.EmptySound = Sound("Weapon_Pistol.Empty")
SWEP.Secondary.EmptySoundLevel = 1.0
SWEP.Secondary.EmptyDelay = 0.1

SWEP.Secondary.Enable = true
SWEP.Secondary.Sound = Sound("Weapon_357.Double")
SWEP.Secondary.SoundLevel = 0.25
SWEP.Secondary.Recoil = 15.0
SWEP.Secondary.Damage = 0
SWEP.Secondary.Speed = 0
SWEP.Secondary.Count = 1
SWEP.Secondary.Delay = 1.0
SWEP.Secondary.AmmoConsumed = 1

SWEP.Secondary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true


SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK
SWEP.SecondaryAnim = ACT_VM_SECONDARYATTACK
SWEP.ReloadAnim = ACT_VM_RELOAD

SWEP.UseHands = true
SWEP.AccurateCrosshair = false
SWEP.DisableDuplicator = false
SWEP.ScriptedEntityType = "weapon"
SWEP.m_bPlayPickupSound = true

-- fight weapons cannot be reloaded by default (ClipSize = -1)
function SWEP:Reload()
end

function SWEP:Think()
end

-- fight weapons are not droppable by default
function SWEP:ShouldDropOnDie()
    return false
end

function SWEP:DryFire(setnext, delay, sound, soundLevel)
    self:EmitSound(sound, soundLevel)
    setnext(self, CurTime() + delay)
    self:Reload()
end


function SWEP:ShootBullets(damage, recoil, count, cone)
    self:GetOwner():MuzzleFlash()
    self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

    count = count or 1
    cone = cone or 0.01

    local bullet = {}
    bullet.Num = count
    bullet.Src = self:GetOwner():GetShootPos()
    bullet.Dir = self:GetOwner():GetAimVector()
    bullet.Spread = Vector(cone, cone, 0)
    bullet.Tracer = 1
    bullet.TracerName = self.Tracer or "Tracer"
    bullet.Force = 10
    bullet.Damage = damage
    self:GetOwner():FireBullets(bullet)
end


---@returns number
function SWEP:Ammo1()
    return IsValid(self:GetOwner()) and self:GetOwner():GetAmmoCount(self.Primary.Ammo) or false
end

function SWEP:CanPrimaryAttack()
    local clip = self:Clip1()
    return IsValid(self:GetOwner()) and (clip == -1 and self:Ammo1() >= self.Primary.AmmoConsumed) or clip >= self.Primary.AmmoConsumed
end

function SWEP:FirePrimary()
end

---@param playSoundInWorld boolean whether or not to play the attack sound in world or emit locally
function SWEP:PrimaryAttack(playSoundInWorld)
    if not self.Primary.Enable then return end
    
    self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

    if not self:CanPrimaryAttack() then
        self:DryFire(self.SetNextPrimaryFire, self.Primary.EmptyDelay, self.Primary.EmptySound, self.Primary.EmptySoundLevel)
        return
    end

    -- if playSoundInWorld and we're the Server, then play the fire sound
    -- in the world at the weapons pos. otherwise, just play locally
    if not playSoundInWorld then
        self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
    elseif SERVER then
        sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
    end

    self:SendWeaponAnim(self.PrimaryAnim)
    self:FirePrimary()

    self:TakePrimaryAmmo(self.Primary.AmmoConsumed)

    local owner = self:GetOwner()
    if IsValid(owner) and (not owner:IsNPC()) and owner.ViewPunch then
        local x = util.SharedRandom(self:GetClass(),-0.2,-0.1,0) * self.Primary.Recoil
        local y = util.SharedRandom(self:GetClass(),-0.1,0.1,1) * self.Primary.Recoil
        owner:ViewPunch(Angle(x, y, 0))
    end
end


---@returns number
function SWEP:Ammo2()
    return IsValid(self:GetOwner()) and self:GetOwner():GetAmmoCount(self.Secondary.Ammo) or false
end

function SWEP:CanSecondaryAttack()
    local clip = self:Clip2()
    return IsValid(self:GetOwner()) and (clip == -1 and self:Ammo2() >= self.Secondary.AmmoConsumed) or clip >= self.Secondary.AmmoConsumed
end

function SWEP:FireSecondary()
end

function SWEP:SecondaryAttack(playSoundInWorld)
    if not self.Secondary.Enable then return end

    self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
    self:SetNextPrimaryFire( CurTime() + self.Secondary.Delay )

    if not self:CanSecondaryAttack() then
        self:DryFire(self.SetNextSecondaryFire, self.Secondary.EmptyDelay, self.Secondary.EmptySound, self.Secondary.EmptySoundLevel)
        return
    end

    -- if playSoundInWorld and we're the Server, then play the fire sound
    -- in the world at the weapons pos. otherwise, just play locally
    if not playSoundInWorld then
        self:EmitSound(self.Secondary.Sound, self.Secondary.SoundLevel)
    elseif SERVER then
        sound.Play(self.Secondary.Sound, self:GetPos(), self.Secondary.SoundLevel)
    end

    self:SendWeaponAnim(self.SecondaryAnim)
    self:FireSecondary()

    self:TakeSecondaryAmmo(self.Secondary.AmmoConsumed)

    local owner = self:GetOwner()
    if IsValid(owner) and (not owner:IsNPC()) and owner.ViewPunch then
        local x = util.SharedRandom(self:GetClass(),-0.2,-0.1,0) * self.Secondary.Recoil
        local y = util.SharedRandom(self:GetClass(),-0.1,0.1,1) * self.Secondary.Recoil
        owner:ViewPunch(Angle(x, y, 0))
    end
end

AddCSLuaFile()

SWEP.Base = "weapon_fight_base"
SWEP.HoldType = "pistol"

SWEP.PrintName = "Burst Pistol"
SWEP.m_WeaponDeploySpeed = 2.0

SWEP.Purpose = "Fight! Merc's Secondary Weapon"
SWEP.Instructions = "Fires a short 3-round burst."

SWEP.ViewModel = Model("models/weapons/c_pistol.mdl")
SWEP.WorldModel = Model("models/weapons/w_pistol.mdl")

SWEP.Slot = 1
SWEP.SlotPos = 10

SWEP.Primary.EmptySound = Sound("Weapon_Pistol.Empty")
SWEP.Primary.Sound = Sound("Weapon_Pistol.Single")
SWEP.Primary.Ammo = "Pistol"
SWEP.Primary.ClipSize = 15
SWEP.Primary.DefaultClip = 15
SWEP.Primary.Delay = 0.05
SWEP.Primary.Recoil = 5
SWEP.Primary.Damage = 1
SWEP.Primary.Cone = 0.05

SWEP.Secondary.Enable = false

SWEP.Tracer = "AR2Tracer"

SWEP.BurstCount = 3
SWEP.BurstCounter = 0
SWEP.BurstDelay = 0.5

function SWEP:Reload()
    if self:Clip1() == self.Primary.ClipSize or self:GetOwner():GetAmmoCount( self.Primary.Ammo ) <= 0 then return end
    self:DefaultReload(self.ReloadAnim)
end

function SWEP:FirePrimary()
    self:ShootBullets(
        self.Primary.Damage,
        self.Primary.Recoil,
        self.Primary.Count,
        self.Primary.Cone)
    
    self.BurstCounter = self.BurstCounter + 1
    if self.BurstCounter >= self.BurstCount then
        self.BurstCounter = 0
        self:SetNextPrimaryFire(CurTime() + self.BurstDelay)
    end
end

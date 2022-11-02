AddCSLuaFile()

SWEP.Base = "weapon_fight_base"
SWEP.HoldType = "fist"

SWEP.PrintName = "Fists"
SWEP.m_WeaponDeploySpeed = 1

SWEP.Purpose = "Fight! Merc Fists"
SWEP.Instructions = ""

SWEP.ViewModel = Model( "models/weapons/c_arms.mdl" )
SWEP.ViewModelFOV = 54

SWEP.Weight = 4

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.Slot = 2

-- primary fire properties

SWEP.Primary = {}
SWEP.Primary.EmptySoundLevel = 0.0
SWEP.Primary.EmptyDelay = 0.0

SWEP.Primary.Enable = true
SWEP.Primary.Sound = Sound( "WeaponFrag.Throw" )
SWEP.Primary.SoundLevel = 0.25
SWEP.Primary.Recoil = 15.0
SWEP.Primary.Damage = 5
SWEP.Primary.Count = 1
SWEP.Primary.Delay = 1.0
SWEP.Primary.AmmoConsumed = 0

-- secondary fire properties

SWEP.Secondary = {}
SWEP.Secondary.EmptySoundLevel = 0.0
SWEP.Secondary.EmptyDelay = 0.0

SWEP.Secondary.Enable = true
SWEP.Secondary.Sound = Sound( "WeaponFrag.Throw" )
SWEP.Secondary.SoundLevel = 0.25
SWEP.Secondary.Recoil = 15.0
SWEP.Secondary.Damage = 5
SWEP.Secondary.Count = 1
SWEP.Secondary.Delay = 1.0
SWEP.Secondary.AmmoConsumed = 0

SWEP.PrimaryAnim = ACT_VM_MISSLEFT
SWEP.SecondaryAnim = ACT_VM_MISSRIGHT
SWEP.ReloadAnim = ACT_VM_RELOAD

SWEP.UseHands = true
SWEP.AccurateCrosshair = false
SWEP.DisableDuplicator = false
SWEP.ScriptedEntityType = "weapon"
SWEP.m_bPlayPickupSound = true

local HitSound = Sound( "Flesh.ImpactHard" )

function SWEP:Initialize()
    if SERVER then
        PrintMessage(HUD_PRINTTALK, "fists init")
    end
end

function SWEP:Think()
    if not self.firstThink then
        self:SendWeaponAnim(ACT_VM_DRAW)
        self.firstThink = true
    end
end

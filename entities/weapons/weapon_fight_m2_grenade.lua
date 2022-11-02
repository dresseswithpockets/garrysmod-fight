
AddCSLuaFile()

SWEP.HoldType           = "grenade"

if CLIENT then
   SWEP.PrintName       = "M2 Grenade"
   SWEP.Slot            = 3

   SWEP.ViewModelFlip   = false
   SWEP.ViewModelFOV    = 54
end

SWEP.Base               = "weapon_fight_base_grenade"

SWEP.Spawnable          = true
SWEP.AutoSpawnable      = true

SWEP.UseHands           = true
SWEP.ViewModel          = "models/weapons/cstrike/c_eq_fraggrenade.mdl"
SWEP.WorldModel         = "models/weapons/w_eq_fraggrenade.mdl"

SWEP.Weight             = 1

SWEP.detonate_timer     = 0.5

-- really the only difference between grenade weapons: the model and the thrown
-- ent.

function SWEP:GetGrenadeName()
   return "fight_m2_grenade_proj"
end

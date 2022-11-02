AddCSLuaFile()
DEFINE_BASECLASS("player_fight_base")

local PLAYER = {}

PLAYER.DisplayName          = "Merc Class"

PLAYER.CanDash = true

function PLAYER:Loadout()
    self.Player:Give("weapon_fight_burst_pistol")
    self.Player:GiveAmmo(45, "Pistol", true)

    self.Player:Give("weapon_fight_nailgun")
    self.Player:GiveAmmo(50, "SMG1", true)
    self.Player:GiveAmmo(5, "SMG1_Grenade", true)

    self.Player:Give("weapon_fight_merc_fists")

    self.Player:Give("weapon_fight_m2_grenade")
end

function PLAYER:StartRegen()
    print("start regen")
    timer.Create("m2_regen_timer", 3.5, 1, function()
        self:Give("weapon_fight_m2_grenade")
    end)
end

player_manager.RegisterClass("player_fight_merc", PLAYER, "player_fight_base")

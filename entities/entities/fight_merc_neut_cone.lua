AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/hunter/misc/cone1x1.mdl")

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetColor(Color(255, 255, 255, 50))

    if SERVER then
        self:NextThink(CurTime())
        self.HasNeutralized = false
    end
end

function ENT:Think()

    if not SERVER then return end

    if not self.HasNeutralized then

        self.HasNeutralized = true
    else
        self:Remove()
    end
end

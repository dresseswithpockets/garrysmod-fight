-- serverside extensions to player table

local plymeta = FindMetaTable("Player")
if not plymeta then Error("FAILED TO FIND PLAYER TABLE") return end

AccessorFunc(plymeta, "force_spec", "ForceSpec", FORCE_BOOL)

function plymeta:ShouldSpawn()
    -- do not spawn spectators or forced spectators
    return not self:IsSpec() and self:GetForceSpec()
end


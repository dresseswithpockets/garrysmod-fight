-- shared extensions to player table

local plymeta = FindMetaTable("Player")
if not plymeta then Error("FAILED TO FIND PLAYER TABLE") return end

function plymeta:IsSpec()
    return self:Team() == TEAM_SPEC
end

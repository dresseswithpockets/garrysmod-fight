AddCSLuaFile()

DEFINE_BASECLASS("weapon_fists")
SWEP.Base = "weapon_fists"

SWEP.Slot = 2


SWEP.BaseDamage = 5
SWEP.KnockDamage = 7
SWEP.KnocksAfter = 0.5
SWEP.KnocksBefore = 1.1
SWEP.KnockUpForce = 500
SWEP.KnockUpBackForce = 100

SWEP.SwingSound = Sound( "WeaponFrag.Throw" )
SWEP.HitSound = Sound( "Flesh.ImpactHard" )

local phys_pushscale = GetConVar( "phys_pushscale" )

function SWEP:DealDamage()
    local anim = self:GetSequenceName(self.Owner:GetViewModel():GetSequence())

    self.Owner:LagCompensation( true )

    local tr = util.TraceLine( {
        start = self.Owner:GetShootPos(),
        endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
        filter = self.Owner,
        mask = MASK_SHOT_HULL
    } )

    if ( !IsValid( tr.Entity ) ) then
        tr = util.TraceHull( {
            start = self.Owner:GetShootPos(),
            endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
            filter = self.Owner,
            mins = Vector( -10, -10, -8 ),
            maxs = Vector( 10, 10, 8 ),
            mask = MASK_SHOT_HULL
        } )
    end

    -- We need the second part for single player because SWEP:Think is ran shared in SP
    if ( tr.Hit && !( game.SinglePlayer() && CLIENT ) ) then
        self:EmitSound( self.HitSound )
    end

    local hit = false
    local scale = phys_pushscale:GetFloat()

    if ( SERVER && IsValid( tr.Entity ) && ( tr.Entity:IsNPC() || tr.Entity:IsPlayer() || tr.Entity:Health() > 0 ) ) then
        local dmginfo = DamageInfo()

        local attacker = self.Owner
        if ( !IsValid( attacker ) ) then attacker = self end
        dmginfo:SetAttacker( attacker )

        dmginfo:SetInflictor( self )
        dmginfo:SetDamage( self.BaseDamage )

        if ( anim == "fists_left" ) then
            dmginfo:SetDamageForce( self.Owner:GetRight() * 4912 * scale + self.Owner:GetForward() * 9998 * scale ) -- Yes we need those specific numbers
        elseif ( anim == "fists_right" ) then
            dmginfo:SetDamageForce( self.Owner:GetRight() * -4912 * scale + self.Owner:GetForward() * 9989 * scale )
        elseif ( anim == "fists_uppercut" ) then
            dmginfo:SetDamageForce( self.Owner:GetUp() * self.KnockUpForce * scale + self.Owner:GetForward() * self.KnockUpBackForce * scale )
            dmginfo:SetDamage( self.KnockDamage )
        end

        SuppressHostEvents( NULL ) -- Let the breakable gibs spawn in multiplayer on client
        tr.Entity:TakeDamageInfo( dmginfo )
        SuppressHostEvents( self.Owner )

        hit = true

    end

    if ( IsValid( tr.Entity ) ) then
        local phys = tr.Entity:GetPhysicsObject()
        if ( IsValid( phys ) ) then
            local fraction = baseclass.Get("player_fight_base").GetDashFraction(self.Owner)
            if fraction >= self.KnocksAfter and fraction <= self.KnocksBefore then
                local preVelocity = tr.Entity:GetVelocity()
                local addVelocity = self.Owner:GetUp() * self.KnockUpForce * scale + self.Owner:GetForward() * self.KnockUpBackForce * scale
                tr.Entity:SetVelocity(preVelocity + addVelocity)
            else
                phys:ApplyForceOffset( self.Owner:GetAimVector() * 80 * phys:GetMass() * scale, tr.HitPos )
            end
        end
    end

    if ( SERVER ) then
        if ( hit && anim != "fists_uppercut" ) then
            self:SetCombo( self:GetCombo() + 1 )
        else
            self:SetCombo( 0 )
        end
    end

    self.Owner:LagCompensation( false )
end

library SelectionElementConfig requires PlayerMissileLoadout

    function SelectionSetupElement takes integer elementId, player p, unit hero returns nothing
        local integer abilityId
        local real speed
        local real damage
        local integer instances
        local string model
        local string overlay
        local string impactFx
        local string casterFx1 = ""
        local string casterFx2 = ""

        if elementId == 0 then
            set abilityId = 'AM05'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Blue.mdx"
            set overlay = "Miss\\Shot II Blue.mdx"
            set impactFx = "Flamestrike Mystic II.mdx"
            set casterFx1 = "Miss\\Windwalk Blue Soul.mdx"
            set casterFx2 = "Miss\\Valiant Charge Royal.mdx"
        elseif elementId == 1 then
            set abilityId = 'AM03'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Purple.mdx"
            set overlay = "Miss\\Shot II Purple.mdx"
            set impactFx = "Flamestrike Dark Void II.mdx"
            set casterFx1 = "Miss\\Windwalk.mdx"
            set casterFx2 = "Miss\\Valiant Charge Void.mdx"
        elseif elementId == 2 then
            set abilityId = 'AM01'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Red.mdx"
            set overlay = "Miss\\Shot II Red.mdx"
            set impactFx = "Flamestrike Blood II.mdx"
            set casterFx1 = "Miss\\Windwalk Blood.mdx"
            set casterFx2 = "Miss\\Valiant Charge.mdx"
        elseif elementId == 3 then
            set abilityId = 'AM06'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Yellow.mdx"
            set overlay = "Miss\\Shot II Yellow.mdx"
            set impactFx = "Flamestrike Fel II.mdx"
            set casterFx1 = "Miss\\Windwalk.mdx"
            set casterFx2 = "Miss\\Valiant Charge Holy.mdx"
        elseif elementId == 4 then
            set abilityId = 'AM02'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Green.mdx"
            set overlay = "Miss\\Shot II Green.mdx"
            set impactFx = "Flamestrike Nature II.mdx"
            set casterFx1 = "Miss\\Windwalk Necro Soul.mdx"
            set casterFx2 = "Miss\\Valiant Charge Fel.mdx"
        else
            set abilityId = 'AM04'
            set speed = 0.
            set damage = 1.
            set instances = 1
            set model = "Miss\\Shot Orange.mdx"
            set overlay = "Miss\\Shot II Orange.mdx"
            set impactFx = "Flamestrike II.mdx"
            set casterFx1 = "Miss\\Windwalk Fire.mdx"
            set casterFx2 = "Miss\\Valiant Charge.mdx"
        endif

        // El PreSelect ya no otorga habilidad de orbe/elemento.
        // El elementId queda solo como perfil visual/color del proyectil.
        // Tier 1 usa Blue; futuros tiers pueden llamar esta config con otro elementId.
        call SetPlayerLeapCasterFx(p, casterFx1, casterFx2)
        call SetPlayerMissileLoadout(p, abilityId, speed, damage, instances, model, overlay)
        call SetPlayerLeapImpactFx(p, impactFx)
    endfunction

endlibrary

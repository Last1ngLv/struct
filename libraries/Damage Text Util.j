library DamageTextUtil requires TextTagDebug

    function FormatLoadoutDamageText takes real amount returns string
        local integer scaled
        local integer whole
        local integer frac
        local string fracText
        if amount < 0. then
            set amount = 0.
        endif
        set scaled = R2I(amount*100. + 0.5)
        set whole = scaled/100
        set frac = scaled - whole*100
        if frac < 10 then
            set fracText = "0" + I2S(frac)
        else
            set fracText = I2S(frac)
        endif
        return "!! " + I2S(whole) + "." + fracText
    endfunction

    function ShowCustomLoadoutText takes unit target, string msg, integer r, integer g, integer b returns nothing
        local texttag t
        if target == null then
            return
        endif
        set t = CreateTrackedTextTag(TEXTTAG_DEBUG_DAMAGE)
        call SetTextTagText(t, msg, 0.020)
        call SetTextTagPosUnit(t, target, 90.)
        call SetTextTagColor(t, r, g, b, 255)
        call SetTextTagVelocity(t, 0.0, 0.035)
        call SetTextTagLifespan(t, 1.00)
        call SetTextTagFadepoint(t, 0.50)
        call SetTextTagPermanent(t, false)
        call ReleaseTrackedTextTag(TEXTTAG_DEBUG_DAMAGE)
        set t = null
    endfunction

endlibrary

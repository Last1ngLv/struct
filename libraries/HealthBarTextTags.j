library HealthBarTextTags initializer Init requires Table, TimerUtils, PlayerUtils, TextTagDebug

    globals
        private constant real HEALTH_BAR_HERO_PERIOD = 0.03
        private constant real HEALTH_BAR_ENEMY_PERIOD = 0.05
        private constant real HEALTH_BAR_ENEMY_TIMEOUT = 1.50
        private constant integer HEALTH_BAR_SEGMENTS = 10
        private constant integer HEALTH_BAR_ENEMY_SLOTS_PER_VIEWER = 12
        private constant real HEALTH_BAR_HERO_NAME_SIZE = 0.020
        private constant real HEALTH_BAR_HERO_BAR_SIZE = 0.018
        private constant real HEALTH_BAR_ENEMY_BAR_SIZE = 0.017
        private constant real HEALTH_BAR_HERO_NAME_Z = 205.0
        private constant real HEALTH_BAR_HERO_BAR_Z = 145.0
        private constant real HEALTH_BAR_ENEMY_Z = 120.0
        private constant real HEALTH_BAR_HERO_X_OFFSET = -42.0
        private constant real HEALTH_BAR_ENEMY_X_OFFSET = -28.0
        private constant integer HEALTH_BAR_ALPHA = 255

        private timer HealthBarHeroTicker = null
        private timer HealthBarEnemyTicker = null
        private real HealthBarEnemyNow = 0.00

        private texttag array HeroNameTag
        private texttag array HeroBarTag
        private integer array HeroBoundHandleId
        private integer array HeroLastPercent

        private texttag array EnemyBarTag
        private unit array EnemyBarTarget
        private integer array EnemyBarTargetHid
        private real array EnemyBarExpireAt
        private integer array EnemyBarLastPercent
        private Table EnemySlotByKey
    endglobals

    private function HealthBarEnemyKey takes integer targetHid returns integer
        return targetHid
    endfunction

    private function HealthBarGetPlayerColorR takes integer pid returns integer
        if pid == 0 then
            return 255
        elseif pid == 1 then
            return 0
        elseif pid == 2 then
            return 28
        elseif pid == 3 then
            return 84
        elseif pid == 4 then
            return 255
        elseif pid == 5 then
            return 254
        elseif pid == 6 then
            return 32
        elseif pid == 7 then
            return 229
        elseif pid == 8 then
            return 149
        elseif pid == 9 then
            return 126
        elseif pid == 10 then
            return 16
        elseif pid == 11 then
            return 78
        endif
        return 255
    endfunction

    private function HealthBarGetPlayerColorG takes integer pid returns integer
        if pid == 0 then
            return 3
        elseif pid == 1 then
            return 66
        elseif pid == 2 then
            return 230
        elseif pid == 3 then
            return 0
        elseif pid == 4 then
            return 252
        elseif pid == 5 then
            return 138
        elseif pid == 6 then
            return 192
        elseif pid == 7 then
            return 91
        elseif pid == 8 then
            return 150
        elseif pid == 9 then
            return 191
        elseif pid == 10 then
            return 98
        elseif pid == 11 then
            return 42
        endif
        return 255
    endfunction

    private function HealthBarGetPlayerColorB takes integer pid returns integer
        if pid == 0 then
            return 3
        elseif pid == 1 then
            return 255
        elseif pid == 2 then
            return 185
        elseif pid == 3 then
            return 129
        elseif pid == 4 then
            return 1
        elseif pid == 5 then
            return 14
        elseif pid == 6 then
            return 0
        elseif pid == 7 then
            return 176
        elseif pid == 8 then
            return 151
        elseif pid == 9 then
            return 241
        elseif pid == 10 then
            return 70
        elseif pid == 11 then
            return 4
        endif
        return 255
    endfunction

    private function HealthBarGetPercent takes unit whichUnit returns integer
        local real maxLife
        local real life
        local real ratio
        local integer percent
        if whichUnit == null or GetUnitTypeId(whichUnit) == 0 then
            return 0
        endif
        set maxLife = GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE)
        if maxLife <= 0.405 then
            return 0
        endif
        set life = GetUnitState(whichUnit, UNIT_STATE_LIFE)
        if life < 0.00 then
            set life = 0.00
        endif
        set ratio = life/maxLife
        if ratio < 0.00 then
            set ratio = 0.00
        elseif ratio > 1.00 then
            set ratio = 1.00
        endif
        set percent = R2I(ratio*100.00 + 0.5)
        if percent < 0 then
            set percent = 0
        elseif percent > 100 then
            set percent = 100
        endif
        return percent
    endfunction

    private function HealthBarGetFilledSegments takes integer percent returns integer
        local integer filled = R2I((I2R(percent)*I2R(HEALTH_BAR_SEGMENTS))/100.00 + 0.5)
        if filled < 0 then
            set filled = 0
        elseif filled > HEALTH_BAR_SEGMENTS then
            set filled = HEALTH_BAR_SEGMENTS
        endif
        return filled
    endfunction

    private function HealthBarGetBarText takes integer percent returns string
        local integer filled = HealthBarGetFilledSegments(percent)
        local string filledColor
        local string emptyColor = "|cff808080"
        local string result = ""
        local integer i = 0
        if filled < 0 then
            set filled = 0
        elseif filled > HEALTH_BAR_SEGMENTS then
            set filled = HEALTH_BAR_SEGMENTS
        endif
        if filled >= 7 then
            set filledColor = "|cff50ff50"
        elseif filled >= 4 then
            set filledColor = "|cffffdc00"
        else
            set filledColor = "|cffff5050"
        endif
        loop
            exitwhen i >= HEALTH_BAR_SEGMENTS
            if i < filled then
                set result = result + filledColor + "||"
            else
                set result = result + emptyColor + "||"
            endif
            set i = i + 1
        endloop
        return result + "|r |cffffffff" + I2S(percent) + "%|r"
    endfunction

    private function HealthBarGetLifeColorR takes integer percent returns integer
        local integer filled = HealthBarGetFilledSegments(percent)
        if filled >= 7 then
            return 80
        elseif filled >= 4 then
            return 255
        endif
        return 255
    endfunction

    private function HealthBarGetLifeColorG takes integer percent returns integer
        local integer filled = HealthBarGetFilledSegments(percent)
        if filled >= 7 then
            return 255
        elseif filled >= 4 then
            return 220
        endif
        return 80
    endfunction

    private function HealthBarGetLifeColorB takes integer percent returns integer
        local integer filled = HealthBarGetFilledSegments(percent)
        if filled >= 7 then
            return 80
        elseif filled >= 4 then
            return 0
        endif
        return 80
    endfunction

    private function HealthBarIsTrackedUnit takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0
    endfunction

    private function HealthBarIsEnemyDisplayTargetValid takes unit whichUnit returns boolean
        if not HealthBarIsTrackedUnit(whichUnit) then
            return false
        endif
        if IsUnitType(whichUnit, UNIT_TYPE_DEAD) then
            return false
        endif
        return true
    endfunction

    private function HealthBarCreatePersistentTextTag takes nothing returns texttag
        local texttag tag = CreateTrackedTextTag(TEXTTAG_DEBUG_HEALTHBAR)
        call SetTextTagPermanent(tag, true)
        call SetTextTagVisibility(tag, false)
        call SetTextTagVelocity(tag, 0.00, 0.00)
        call SetTextTagFadepoint(tag, 0.00)
        call SetTextTagLifespan(tag, 999999.00)
        return tag
    endfunction

    function GetHealthBarEnemySlotCap takes nothing returns integer
        return HEALTH_BAR_ENEMY_SLOTS_PER_VIEWER
    endfunction

    function GetHealthBarTextTagCap takes nothing returns integer
        return HEALTH_BAR_ENEMY_SLOTS_PER_VIEWER + User.AmountPlaying*2
    endfunction

    private function HealthBarSetTagPosition takes texttag tag, unit u, real xOffset, real zOffset returns nothing
        call SetTextTagPos(tag, GetUnitX(u) + xOffset, GetUnitY(u), zOffset + GetUnitFlyHeight(u))
    endfunction

    function HealthBarsRefreshHeroForPlayer takes integer pid returns nothing
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        set HeroBoundHandleId[pid] = 0
        set HeroLastPercent[pid] = -1
    endfunction

    private function HealthBarUpdateHeroEntry takes integer pid returns nothing
        local unit hero = PlayerHero[pid]
        local texttag nameTag = HeroNameTag[pid]
        local texttag barTag = HeroBarTag[pid]
        local integer hid = 0
        local integer percent

        if not User.fromIndex(pid).isPlaying or not HealthBarIsTrackedUnit(hero) then
            if nameTag != null then
                call SetTextTagVisibility(nameTag, false)
            endif
            if barTag != null then
                call SetTextTagVisibility(barTag, false)
            endif
            set HeroBoundHandleId[pid] = 0
            set HeroLastPercent[pid] = -1
            set hero = null
            set nameTag = null
            set barTag = null
            return
        endif

        if nameTag == null then
            set nameTag = HealthBarCreatePersistentTextTag()
            set HeroNameTag[pid] = nameTag
        endif
        if barTag == null then
            set barTag = HealthBarCreatePersistentTextTag()
            set HeroBarTag[pid] = barTag
        endif

        set hid = GetHandleId(hero)
        call SetTextTagVisibility(nameTag, true)
        call SetTextTagVisibility(barTag, true)
        call HealthBarSetTagPosition(nameTag, hero, HEALTH_BAR_HERO_X_OFFSET, HEALTH_BAR_HERO_NAME_Z)
        call HealthBarSetTagPosition(barTag, hero, HEALTH_BAR_HERO_X_OFFSET, HEALTH_BAR_HERO_BAR_Z)

        if HeroBoundHandleId[pid] != hid then
            set HeroBoundHandleId[pid] = hid
            set HeroLastPercent[pid] = -1
            call SetTextTagText(nameTag, User.fromIndex(pid).name, HEALTH_BAR_HERO_NAME_SIZE)
            call SetTextTagColor(nameTag, HealthBarGetPlayerColorR(pid), HealthBarGetPlayerColorG(pid), HealthBarGetPlayerColorB(pid), HEALTH_BAR_ALPHA)
        endif

        set percent = HealthBarGetPercent(hero)
        if HeroLastPercent[pid] != percent then
            set HeroLastPercent[pid] = percent
            call SetTextTagText(barTag, HealthBarGetBarText(percent), HEALTH_BAR_HERO_BAR_SIZE)
            call SetTextTagColor(barTag, HealthBarGetLifeColorR(percent), HealthBarGetLifeColorG(percent), HealthBarGetLifeColorB(percent), HEALTH_BAR_ALPHA)
        endif

        set hero = null
        set nameTag = null
        set barTag = null
    endfunction

    private function HealthBarHeroTick takes nothing returns nothing
        local integer pid = 0
        loop
            exitwhen pid >= bj_MAX_PLAYER_SLOTS
            call HealthBarUpdateHeroEntry(pid)
            set pid = pid + 1
        endloop
    endfunction

    private function HealthBarEnemyClearSlot takes integer slotIndex returns nothing
        local integer key
        if slotIndex < 0 or slotIndex >= HEALTH_BAR_ENEMY_SLOTS_PER_VIEWER then
            return
        endif
        if EnemyBarTargetHid[slotIndex] != 0 then
            set key = HealthBarEnemyKey(EnemyBarTargetHid[slotIndex])
            if EnemySlotByKey.has(key) then
                call EnemySlotByKey.remove(key)
            endif
        endif
        set EnemyBarTarget[slotIndex] = null
        set EnemyBarTargetHid[slotIndex] = 0
        set EnemyBarExpireAt[slotIndex] = 0.00
        set EnemyBarLastPercent[slotIndex] = -1
        if EnemyBarTag[slotIndex] != null then
            call SetTextTagVisibility(EnemyBarTag[slotIndex], false)
        endif
    endfunction

    private function HealthBarEnemyFindSlot takes unit target returns integer
        local integer hid = GetHandleId(target)
        local integer key = HealthBarEnemyKey(hid)
        local integer slotIndex
        local integer localSlot = 0
        local integer oldestIndex = 0
        local real oldestExpire = 9999999.00

        if EnemySlotByKey.has(key) then
            return EnemySlotByKey[key]
        endif

        loop
            exitwhen localSlot >= HEALTH_BAR_ENEMY_SLOTS_PER_VIEWER
            set slotIndex = localSlot
            if EnemyBarTarget[slotIndex] == null or EnemyBarExpireAt[slotIndex] <= HealthBarEnemyNow or not HealthBarIsEnemyDisplayTargetValid(EnemyBarTarget[slotIndex]) then
                call HealthBarEnemyClearSlot(slotIndex)
                return slotIndex
            endif
            if EnemyBarExpireAt[slotIndex] < oldestExpire then
                set oldestExpire = EnemyBarExpireAt[slotIndex]
                set oldestIndex = slotIndex
            endif
            set localSlot = localSlot + 1
        endloop

        call HealthBarEnemyClearSlot(oldestIndex)
        return oldestIndex
    endfunction

    private function HealthBarEnemyRefreshSlot takes integer slotIndex returns nothing
        local unit target = EnemyBarTarget[slotIndex]
        local texttag tag = EnemyBarTag[slotIndex]
        local integer percent
        if tag == null then
            set tag = HealthBarCreatePersistentTextTag()
            set EnemyBarTag[slotIndex] = tag
        endif
        if tag == null or not HealthBarIsEnemyDisplayTargetValid(target) then
            call HealthBarEnemyClearSlot(slotIndex)
            set target = null
            set tag = null
            return
        endif

        set percent = HealthBarGetPercent(target)
        call HealthBarSetTagPosition(tag, target, HEALTH_BAR_ENEMY_X_OFFSET, HEALTH_BAR_ENEMY_Z)
        if EnemyBarLastPercent[slotIndex] != percent then
            set EnemyBarLastPercent[slotIndex] = percent
            call SetTextTagText(tag, HealthBarGetBarText(percent), HEALTH_BAR_ENEMY_BAR_SIZE)
            call SetTextTagColor(tag, HealthBarGetLifeColorR(percent), HealthBarGetLifeColorG(percent), HealthBarGetLifeColorB(percent), HEALTH_BAR_ALPHA)
        endif

        call SetTextTagVisibility(tag, true)

        set target = null
        set tag = null
    endfunction

    function HealthBarsNotifyEnemyDamagedByPid takes integer ownerPid, unit target returns nothing
        local player ownerPlayer
        local integer slotIndex
        local integer key
        if ownerPid < 0 or ownerPid >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        if not HealthBarIsEnemyDisplayTargetValid(target) then
            return
        endif

        set ownerPlayer = Player(ownerPid)
        if IsPlayerAlly(User.Local, ownerPlayer) then
            set slotIndex = HealthBarEnemyFindSlot(target)
            set key = HealthBarEnemyKey(GetHandleId(target))
            set EnemyBarTarget[slotIndex] = target
            set EnemyBarTargetHid[slotIndex] = GetHandleId(target)
            set EnemyBarExpireAt[slotIndex] = HealthBarEnemyNow + HEALTH_BAR_ENEMY_TIMEOUT
            if not EnemySlotByKey.has(key) or EnemySlotByKey[key] != slotIndex then
                set EnemySlotByKey[key] = slotIndex
            endif
            call HealthBarEnemyRefreshSlot(slotIndex)
        endif
        set ownerPlayer = null
    endfunction

    function HealthBarsNotifyEnemyDamaged takes unit source, unit target returns nothing
        local integer ownerPid
        if source == null or target == null then
            return
        endif
        if not HealthBarIsTrackedUnit(source) or not HealthBarIsTrackedUnit(target) then
            return
        endif
        set ownerPid = GetPlayerId(GetOwningPlayer(source))
        if ownerPid < 0 or ownerPid >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        if not IsPlayerEnemy(GetOwningPlayer(target), Player(ownerPid)) then
            return
        endif
        call HealthBarsNotifyEnemyDamagedByPid(ownerPid, target)
    endfunction

    private function HealthBarEnemyTick takes nothing returns nothing
        local integer slotIndex = 0
        set HealthBarEnemyNow = HealthBarEnemyNow + HEALTH_BAR_ENEMY_PERIOD
        loop
            exitwhen slotIndex >= HEALTH_BAR_ENEMY_SLOTS_PER_VIEWER
            if EnemyBarTarget[slotIndex] != null then
                if EnemyBarExpireAt[slotIndex] <= HealthBarEnemyNow then
                    call HealthBarEnemyClearSlot(slotIndex)
                else
                    call HealthBarEnemyRefreshSlot(slotIndex)
                endif
            endif
            set slotIndex = slotIndex + 1
        endloop
    endfunction

    private function Init takes nothing returns nothing
        local integer i = 0
        local integer slotIndex

        set EnemySlotByKey = Table.create()

        set i = 0
        loop
            exitwhen i >= HEALTH_BAR_ENEMY_SLOTS_PER_VIEWER
            set slotIndex = i
            set EnemyBarLastPercent[slotIndex] = -1
            set EnemyBarTag[slotIndex] = null
            set i = i + 1
        endloop

        set i = 0
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set HeroLastPercent[i] = -1
            set i = i + 1
        endloop

        set HealthBarHeroTicker = NewTimer()
        call SetTimerDebugTag(HealthBarHeroTicker, TIMER_DEBUG_TAG_OTHER)
        call TimerStart(HealthBarHeroTicker, HEALTH_BAR_HERO_PERIOD, true, function HealthBarHeroTick)

        set HealthBarEnemyTicker = NewTimer()
        call SetTimerDebugTag(HealthBarEnemyTicker, TIMER_DEBUG_TAG_OTHER)
        call TimerStart(HealthBarEnemyTicker, HEALTH_BAR_ENEMY_PERIOD, true, function HealthBarEnemyTick)
    endfunction

endlibrary

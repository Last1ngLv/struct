library HealthBarTextTags initializer Init requires Table, TimerUtils, PlayerUtils, PlayerHeroState

    globals
        private constant real HEALTH_BAR_HERO_PERIOD = 0.03
        private constant real HEALTH_BAR_ENEMY_PERIOD = 0.05
        private constant real HEALTH_BAR_ENEMY_TIMEOUT = 1.50
        private constant integer HEALTH_BAR_SEGMENTS = 10
        private constant integer HEALTH_BAR_HERO_CAP = 8
        private constant integer HEALTH_BAR_ENEMY_CAP = 40
        private constant real HEALTH_BAR_HERO_TEXT_SIZE = 0.018
        private constant real HEALTH_BAR_ENEMY_TEXT_SIZE = 0.017
        private constant real HEALTH_BAR_HERO_Z = 145.0
        private constant real HEALTH_BAR_ENEMY_Z = 120.0
        private constant real HEALTH_BAR_HERO_X_OFFSET = -42.0
        private constant real HEALTH_BAR_ENEMY_X_OFFSET = -28.0
        private constant integer HEALTH_BAR_ALPHA = 255

        private timer HealthBarHeroTicker = null
        private timer HealthBarEnemyTicker = null
        private timer HealthBarClock = null

        private texttag array HeroTag
        private integer array HeroBoundHandleId
        private integer array HeroLastPercent

        private texttag array EnemyBarTag
        private unit array EnemyBarTarget
        private integer array EnemyBarTargetHid
        private real array EnemyBarExpireAt
        private integer array EnemyBarLastPercent
        private Table EnemySlotByTarget

        private integer HealthBarHeroVisibleCount = 0
        private integer HealthBarEnemyVisibleCount = 0
        private integer HealthBarVisibleCount = 0
        private integer HealthBarPeakVisibleCount = 0
    endglobals

    private function HealthBarClockNoop takes nothing returns nothing
    endfunction

    private function HealthBarNow takes nothing returns real
        return TimerGetElapsed(HealthBarClock)
    endfunction

    private function HealthBarRefreshVisibleTotals takes nothing returns nothing
        set HealthBarVisibleCount = HealthBarHeroVisibleCount + HealthBarEnemyVisibleCount
        if HealthBarVisibleCount > HealthBarPeakVisibleCount then
            set HealthBarPeakVisibleCount = HealthBarVisibleCount
        endif
    endfunction

    private function HealthBarEnemyKey takes integer targetHid returns integer
        return targetHid
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

    private function HealthBarGetHeroText takes integer pid, integer percent returns string
        return User.fromIndex(pid).nameColored + "\n" + HealthBarGetBarText(percent)
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
        local texttag tag = CreateTextTag()
        call SetTextTagPermanent(tag, true)
        call SetTextTagVisibility(tag, false)
        call SetTextTagVelocity(tag, 0.00, 0.00)
        call SetTextTagFadepoint(tag, 0.00)
        call SetTextTagLifespan(tag, 999999.00)
        return tag
    endfunction

    private function HealthBarSetTagPosition takes texttag tag, unit u, real xOffset, real zOffset returns nothing
        call SetTextTagPos(tag, GetUnitX(u) + xOffset, GetUnitY(u), zOffset + GetUnitFlyHeight(u))
    endfunction

    function GetHealthBarEnemySlotCap takes nothing returns integer
        return HEALTH_BAR_ENEMY_CAP
    endfunction

    function GetHealthBarHeroSlotCap takes nothing returns integer
        if User.AmountPlaying > HEALTH_BAR_HERO_CAP then
            return HEALTH_BAR_HERO_CAP
        endif
        return User.AmountPlaying
    endfunction

    function GetHealthBarTextTagCap takes nothing returns integer
        return HEALTH_BAR_ENEMY_CAP + GetHealthBarHeroSlotCap()
    endfunction

    function GetHealthBarVisibleCount takes nothing returns integer
        return HealthBarVisibleCount
    endfunction

    function GetHealthBarPeakVisibleCount takes nothing returns integer
        return HealthBarPeakVisibleCount
    endfunction

    function HealthBarsRefreshHeroForPlayer takes integer pid returns nothing
        if pid < 0 or pid >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        set HeroBoundHandleId[pid] = 0
        set HeroLastPercent[pid] = -1
    endfunction

    private function HealthBarUpdateHeroEntry takes integer pid returns boolean
        local unit hero = PlayerHero[pid]
        local texttag heroTag = HeroTag[pid]
        local integer hid = 0
        local integer percent

        if not User.fromIndex(pid).isPlaying or not HealthBarIsTrackedUnit(hero) then
            if heroTag != null then
                call SetTextTagVisibility(heroTag, false)
            endif
            set HeroBoundHandleId[pid] = 0
            set HeroLastPercent[pid] = -1
            set hero = null
            set heroTag = null
            return false
        endif

        if heroTag == null then
            set heroTag = HealthBarCreatePersistentTextTag()
            set HeroTag[pid] = heroTag
        endif

        set hid = GetHandleId(hero)
        if HeroBoundHandleId[pid] != hid then
            set HeroBoundHandleId[pid] = hid
            set HeroLastPercent[pid] = -1
        endif

        set percent = HealthBarGetPercent(hero)
        call SetTextTagText(heroTag, HealthBarGetHeroText(pid, percent), HEALTH_BAR_HERO_TEXT_SIZE)
        call SetTextTagColor(heroTag, 255, 255, 255, HEALTH_BAR_ALPHA)
        call HealthBarSetTagPosition(heroTag, hero, HEALTH_BAR_HERO_X_OFFSET, HEALTH_BAR_HERO_Z)
        call SetTextTagVisibility(heroTag, true)
        set HeroLastPercent[pid] = percent

        set hero = null
        set heroTag = null
        return true
    endfunction

    private function HealthBarHeroTick takes nothing returns nothing
        local integer pid = 0
        local integer visibleCount = 0

        loop
            exitwhen pid >= bj_MAX_PLAYER_SLOTS
            if HealthBarUpdateHeroEntry(pid) then
                set visibleCount = visibleCount + 1
            endif
            set pid = pid + 1
        endloop

        set HealthBarHeroVisibleCount = visibleCount
        call HealthBarRefreshVisibleTotals()
    endfunction

    private function HealthBarEnemyClearSlot takes integer slotIndex returns nothing
        local integer key
        if slotIndex < 0 or slotIndex >= HEALTH_BAR_ENEMY_CAP then
            return
        endif
        if EnemyBarTargetHid[slotIndex] != 0 then
            set key = HealthBarEnemyKey(EnemyBarTargetHid[slotIndex])
            if EnemySlotByTarget.has(key) then
                call EnemySlotByTarget.remove(key)
            endif
        endif
        set EnemyBarTarget[slotIndex] = null
        set EnemyBarTargetHid[slotIndex] = 0
        set EnemyBarExpireAt[slotIndex] = 0.00
        set EnemyBarLastPercent[slotIndex] = -1
        call SetTextTagVisibility(EnemyBarTag[slotIndex], false)
    endfunction

    private function HealthBarEnemyFindSlot takes unit target returns integer
        local integer hid = GetHandleId(target)
        local integer key = HealthBarEnemyKey(hid)
        local integer slotIndex = 0
        local integer oldestIndex = 0
        local real oldestExpire = 9999999.00
        local real now = HealthBarNow()

        if EnemySlotByTarget.has(key) then
            return EnemySlotByTarget[key]
        endif

        loop
            exitwhen slotIndex >= HEALTH_BAR_ENEMY_CAP
            if EnemyBarTarget[slotIndex] == null or EnemyBarExpireAt[slotIndex] <= now or not HealthBarIsEnemyDisplayTargetValid(EnemyBarTarget[slotIndex]) then
                call HealthBarEnemyClearSlot(slotIndex)
                return slotIndex
            endif
            if EnemyBarExpireAt[slotIndex] < oldestExpire then
                set oldestExpire = EnemyBarExpireAt[slotIndex]
                set oldestIndex = slotIndex
            endif
            set slotIndex = slotIndex + 1
        endloop

        call HealthBarEnemyClearSlot(oldestIndex)
        return oldestIndex
    endfunction

    private function HealthBarEnemyRefreshSlot takes integer slotIndex returns boolean
        local unit target = EnemyBarTarget[slotIndex]
        local integer percent

        if not HealthBarIsEnemyDisplayTargetValid(target) then
            call HealthBarEnemyClearSlot(slotIndex)
            set target = null
            return false
        endif

        set percent = HealthBarGetPercent(target)
        if EnemyBarLastPercent[slotIndex] != percent then
            call SetTextTagText(EnemyBarTag[slotIndex], HealthBarGetBarText(percent), HEALTH_BAR_ENEMY_TEXT_SIZE)
            call SetTextTagColor(EnemyBarTag[slotIndex], 255, 255, 255, HEALTH_BAR_ALPHA)
            set EnemyBarLastPercent[slotIndex] = percent
        endif
        call HealthBarSetTagPosition(EnemyBarTag[slotIndex], target, HEALTH_BAR_ENEMY_X_OFFSET, HEALTH_BAR_ENEMY_Z)
        call SetTextTagVisibility(EnemyBarTag[slotIndex], true)

        set target = null
        return true
    endfunction

    function HealthBarsNotifyEnemyDamagedByPid takes integer ownerPid, unit target returns nothing
        local integer slotIndex
        local integer key
        if ownerPid < 0 or ownerPid >= bj_MAX_PLAYER_SLOTS then
            return
        endif
        if not HealthBarIsEnemyDisplayTargetValid(target) then
            return
        endif

        set slotIndex = HealthBarEnemyFindSlot(target)
        set key = HealthBarEnemyKey(GetHandleId(target))
        set EnemyBarTarget[slotIndex] = target
        set EnemyBarTargetHid[slotIndex] = GetHandleId(target)
        set EnemyBarExpireAt[slotIndex] = HealthBarNow() + HEALTH_BAR_ENEMY_TIMEOUT
        set EnemySlotByTarget[key] = slotIndex
        call HealthBarEnemyRefreshSlot(slotIndex)
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
        local integer visibleCount = 0
        local real now = HealthBarNow()

        loop
            exitwhen slotIndex >= HEALTH_BAR_ENEMY_CAP
            if EnemyBarTarget[slotIndex] != null then
                if EnemyBarExpireAt[slotIndex] <= now then
                    call HealthBarEnemyClearSlot(slotIndex)
                elseif HealthBarEnemyRefreshSlot(slotIndex) then
                    set visibleCount = visibleCount + 1
                endif
            endif
            set slotIndex = slotIndex + 1
        endloop

        set HealthBarEnemyVisibleCount = visibleCount
        call HealthBarRefreshVisibleTotals()
    endfunction

    private function Init takes nothing returns nothing
        local integer i = 0

        set EnemySlotByTarget = Table.create()

        loop
            exitwhen i >= HEALTH_BAR_ENEMY_CAP
            set EnemyBarTag[i] = HealthBarCreatePersistentTextTag()
            set EnemyBarLastPercent[i] = -1
            set i = i + 1
        endloop

        set i = 0
        loop
            exitwhen i >= bj_MAX_PLAYER_SLOTS
            set HeroLastPercent[i] = -1
            set i = i + 1
        endloop

        set HealthBarClock = CreateTimer()
        call TimerStart(HealthBarClock, 864000.00, false, function HealthBarClockNoop)

        set HealthBarHeroTicker = NewTimer()
        call SetTimerDebugTag(HealthBarHeroTicker, TIMER_DEBUG_TAG_OTHER)
        call TimerStart(HealthBarHeroTicker, HEALTH_BAR_HERO_PERIOD, true, function HealthBarHeroTick)

        set HealthBarEnemyTicker = NewTimer()
        call SetTimerDebugTag(HealthBarEnemyTicker, TIMER_DEBUG_TAG_OTHER)
        call TimerStart(HealthBarEnemyTicker, HEALTH_BAR_ENEMY_PERIOD, true, function HealthBarEnemyTick)
    endfunction

endlibrary


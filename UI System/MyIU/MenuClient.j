library MenuClient initializer Init requires UserInterface, GameState, WeaponInventoryCore

globals
    public filterfunc FuncLClickSlot = null
    public filterfunc FuncRClickSlot = null
    public integer array PlayerLastSlot
    public UIButton array PlayerLastButton
    private string array WaveStatusText
    private real array PlayerMenuCameraHeight
    private real array PlayerMenuCameraOffset
    private real array PlayerMenuFogAppliedHeight
    private integer array WeaponHudLastVersion
endglobals

    public /*constant*/ function HERO_WINDOW_NAME takes unit u returns string
        return User[GetOwningPlayer(u)].nameColored
    endfunction

    private function GetDefaultMenuCameraHeight takes nothing returns real
        return 500.
    endfunction

    private function GetDefaultMenuCameraOffset takes nothing returns real
        return 467.
    endfunction

    private function GetMinMenuCameraHeight takes nothing returns real
        return 500.
    endfunction

    private function GetMaxMenuCameraHeight takes nothing returns real
        return 4000.
    endfunction

    private function GetMenuCameraHeightStep takes nothing returns real
        return 500.
    endfunction

    private function GetMenuCameraOffsetForHeight takes real height returns real
        return GetDefaultMenuCameraOffset() + ((height - GetDefaultMenuCameraHeight())/1000.)*667.
    endfunction

    private function GetMenuCameraFogEnd takes real height returns real
        return 3500. + (height - GetDefaultMenuCameraHeight())*1.75
    endfunction

    private function ApplyMenuCameraFog takes player p, real height returns nothing
        if User.Local == p then
            call SetTerrainFogExBJ(0, 0.00, GetMenuCameraFogEnd(height), 0.00, 24.00, 24.00, 24.00)
        endif
    endfunction

    private function ResetMenuCameraFog takes player p returns nothing
        if User.Local == p then
            call ResetTerrainFogBJ()
        endif
    endfunction

    private function EnsureMenuCameraSettings takes integer pid returns nothing
        if PlayerMenuCameraHeight[pid] < GetMinMenuCameraHeight() then
            set PlayerMenuCameraHeight[pid] = GetDefaultMenuCameraHeight()
            set PlayerMenuCameraOffset[pid] = GetDefaultMenuCameraOffset()
        endif
    endfunction

    private function StepMenuCameraHeight takes integer pid, real delta returns nothing
        local real nextHeight
        call EnsureMenuCameraSettings(pid)
        set nextHeight = PlayerMenuCameraHeight[pid] + delta
        if nextHeight > GetMaxMenuCameraHeight() then
            set nextHeight = GetMinMenuCameraHeight()
        elseif nextHeight < GetMinMenuCameraHeight() then
            set nextHeight = GetMaxMenuCameraHeight()
        endif
        set PlayerMenuCameraHeight[pid] = nextHeight
        set PlayerMenuCameraOffset[pid] = GetMenuCameraOffsetForHeight(nextHeight)
    endfunction

    struct Client
        static constant real X = -0.32
        static constant real Y = .99
        static constant real SLOT_OFFSET_Y = 0.065
        static constant real SLOT_OFFSET_ROWLEFT_X = 0.105
        static constant real HERO_NAME_Y = 0.86
        static constant real HERO_NAME_X = 0.28
        static constant integer MAX_SLOTS = 50
        static constant integer SLOT_CAMERA_UP = 2
        static constant integer SLOT_CAMERA_DOWN = 7
        static constant integer TEXT_WAVE_STATUS = 10
        static constant integer PICTURE_WEAPON_SLOT_1 = 20
        static constant integer PICTURE_WEAPON_SLOT_2 = 21
        static constant integer TEXT_WEAPON_SLOT_1 = 22
        static constant integer TEXT_WEAPON_SLOT_2 = 23
        static constant real SLOT_WIDTH = 0.095
        static constant real SLOT_HEIGHT = 0.095 * SCREEN_ASPECT_RATIO
        static constant real WEAPON_HUD_X = -0.315-1
        static constant real WEAPON_HUD_Y = 0.735
        static constant real WEAPON_HUD_GAP_Y = 0.082+.15
        static constant real WEAPON_HUD_ICON_SIZE = 0.058
        static constant real WEAPON_HUD_TEXT_X = -0.250-1
        static constant real WEAPON_HUD_TEXT_Y = 0.705
        static constant real WEAPON_HUD_TEXT_GAP_Y = 0.082+.25

        readonly static boolean Initialized = false
        readonly static integer DisplayCount = 0
        readonly static timer UpdateTimer
        readonly static unit array PlayerCurrentUnit
        readonly static thistype array UnitsIndex

        static UIButton array buttons[.MAX_SLOTS]
        static UIPicture array pictures[.MAX_SLOTS]
        static UIText array title[.MAX_SLOTS]

        Camera camera
        unit unit
        player player
        User user
        readonly boolean displayed

        static method operator [] takes unit u returns thistype
            return .UnitsIndex[GetUnitUserData(u)]
        endmethod

        method getButton takes integer index returns UIButton
            return this.buttons[(this.user.id * .MAX_SLOTS) + index]
        endmethod

        method getPicture takes integer index returns UIPicture
            return this.pictures[(this.user.id * .MAX_SLOTS) + index]
        endmethod

        method setButton takes integer index, UIButton value returns nothing
            set this.buttons[(this.user.id * .MAX_SLOTS) + index] = value
        endmethod

        private static method getWaveStatusText takes integer userId returns string
            if WaveStatusText[userId] == null or WaveStatusText[userId] == "" then
                return "Wave"
            endif
            return WaveStatusText[userId]
        endmethod

        private static method formatAmmoText takes integer ammo returns string
            if ammo == WEAPON_AMMO_INFINITE then
                return "|cff99ff99INF|r"
            endif
            return "|cffffcc00" + I2S(ammo) + "|r"
        endmethod

        private static method formatWeaponSlotText takes player p, integer slot returns string
            local integer profileId = WeaponInventoryGetSlotProfile(p, slot)
            local integer ammo = WeaponInventoryGetSlotAmmo(p, slot)
            local string prefix = "  "
            if WeaponInventoryGetActiveSlot(p) == slot then
                set prefix = "|cffffff00>|r "
            endif
            return prefix + WeaponProfileGetName(profileId) + "\nMunicion: " + thistype.formatAmmoText(ammo)
        endmethod

        private method refreshWeaponHud takes nothing returns nothing
            local integer pid = this.user.id
            local integer hudVersion = WeaponInventoryGetHudVersion(this.player)
            local integer profile1
            local integer profile2

            if WeaponHudLastVersion[pid] != hudVersion then
                set profile1 = WeaponInventoryGetSlotProfile(this.player, WEAPON_INVENTORY_SLOT_1)
                set profile2 = WeaponInventoryGetSlotProfile(this.player, WEAPON_INVENTORY_SLOT_2)

                if .pictures[(pid * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_1] != 0 then
                    call .pictures[(pid * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_1].setTexture(WeaponProfileGetTexture(profile1))
                endif
                if .pictures[(pid * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_2] != 0 then
                    call .pictures[(pid * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_2].setTexture(WeaponProfileGetTexture(profile2))
                endif
                if .title[(pid * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_1] != 0 then
                    call SetTextTagText(.title[(pid * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_1].text, thistype.formatWeaponSlotText(this.player, WEAPON_INVENTORY_SLOT_1), 7 * 0.0027)
                endif
                if .title[(pid * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_2] != 0 then
                    call SetTextTagText(.title[(pid * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_2].text, thistype.formatWeaponSlotText(this.player, WEAPON_INVENTORY_SLOT_2), 7 * 0.0027)
                endif
                set WeaponHudLastVersion[pid] = hudVersion
            endif
        endmethod

        method setWaveStatusTitle takes string value returns nothing
            if value == null or value == "" then
                set WaveStatusText[this.user.id] = "Wave"
            else
                set WaveStatusText[this.user.id] = value
            endif
            if this.title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WAVE_STATUS] != 0 then
                call SetTextTagText(this.title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WAVE_STATUS].text, thistype.getWaveStatusText(this.user.id), 8 * 0.0027)
            endif
        endmethod

        method setEnemyPreviewWave takes integer waveId returns nothing
            // Desactivado: el MenuClient minimal solo conserva camara, niebla y contador de wave.
        endmethod

        method clearEnemyPreview takes nothing returns nothing
            // Desactivado: no se crean previews/modelos en el MenuClient minimal.
        endmethod

        private method setupCameraButton takes integer slot returns nothing
            if this.getButton(slot) != 0 then
                set this.getButton(slot).customValue = slot
                set this.getButton(slot).selectUnit = this.unit
                set this.getButton(slot).onLeftClick = FuncLClickSlot
                set this.getButton(slot).onRightClick = FuncRClickSlot
            endif
        endmethod

        static method create takes unit u returns thistype
            local thistype this = thistype.allocate()
            local real x1 = X + SLOT_OFFSET_ROWLEFT_X
            local real y1 = Y - SLOT_OFFSET_Y

            set this.unit = u
            set this.player = GetOwningPlayer(u)
            set this.user = User[this.player]
            set this.displayed = false
            set this.camera = 0

            if WaveStatusText[this.user.id] == null or WaveStatusText[this.user.id] == "" then
                set WaveStatusText[this.user.id] = "Wave"
            endif

            set .UnitsIndex[GetUnitUserData(u)] = this

            call this.setButton(thistype.SLOT_CAMERA_UP, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.00, y1 - (.SLOT_HEIGHT*5)+1.05, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00G'))
            call this.setButton(thistype.SLOT_CAMERA_DOWN, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.10, y1 - (.SLOT_HEIGHT*5)+1.05, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00H'))
            call this.setupCameraButton(thistype.SLOT_CAMERA_UP)
            call this.setupCameraButton(thistype.SLOT_CAMERA_DOWN)

            set .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WAVE_STATUS] = UIText.createEx(this.user.toPlayer(), X + HERO_NAME_X, HERO_NAME_Y + 0.22, 1)
            call this.setWaveStatusTitle(WaveStatusText[this.user.id])

            set .pictures[(this.user.id * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_1] = UIPicture.create(thistype.WEAPON_HUD_X, thistype.WEAPON_HUD_Y, thistype.WEAPON_HUD_ICON_SIZE, thistype.WEAPON_HUD_ICON_SIZE * SCREEN_ASPECT_RATIO, 8, WeaponProfileGetTexture(WEAPON_PROFILE_HANDGUN))
            set .pictures[(this.user.id * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_2] = UIPicture.create(thistype.WEAPON_HUD_X, thistype.WEAPON_HUD_Y - thistype.WEAPON_HUD_GAP_Y, thistype.WEAPON_HUD_ICON_SIZE, thistype.WEAPON_HUD_ICON_SIZE * SCREEN_ASPECT_RATIO, 8, WeaponProfileGetTexture(WEAPON_PROFILE_HANDGUN))
            set .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_1] = UIText.createEx(this.user.toPlayer(), thistype.WEAPON_HUD_TEXT_X, thistype.WEAPON_HUD_TEXT_Y, 1)
            set .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_2] = UIText.createEx(this.user.toPlayer(), thistype.WEAPON_HUD_TEXT_X, thistype.WEAPON_HUD_TEXT_Y - thistype.WEAPON_HUD_TEXT_GAP_Y, 1)
            set WeaponHudLastVersion[this.user.id] = -1
            call this.refreshWeaponHud()

            return this
        endmethod

        method destroy takes nothing returns nothing
            local integer i = 0
            call this.show(false, this.camera)
            loop
                exitwhen i == thistype.MAX_SLOTS
                if this.getButton(i) != 0 then
                    call this.getButton(i).destroy()
                    call this.setButton(i, 0)
                endif
                if .pictures[(this.user.id * .MAX_SLOTS) + i] != 0 then
                    call .pictures[(this.user.id * .MAX_SLOTS) + i].destroy()
                    set .pictures[(this.user.id * .MAX_SLOTS) + i] = 0
                endif
                if .title[(this.user.id * .MAX_SLOTS) + i] != 0 then
                    call .title[(this.user.id * .MAX_SLOTS) + i].destroy()
                    set .title[(this.user.id * .MAX_SLOTS) + i] = 0
                endif
                set i = i + 1
            endloop
            set .UnitsIndex[GetUnitUserData(this.unit)] = 0
            call this.deallocate()
        endmethod

        private static method onDisplay takes nothing returns nothing
            local User user = User(User.LocalId)
            local thistype equipment = Client[Client.PlayerCurrentUnit[user.id]]
            local real x
            local real y
            local real z

            if equipment == 0 or not equipment.displayed or User.Local != user.handle then
                return
            endif
            if equipment.unit == null or GetUnitTypeId(equipment.unit) == 0 then
                return
            endif

            set x = GetUnitX(equipment.unit)
            set y = GetUnitY(equipment.unit)
            call EnsureMenuCameraSettings(user.id)
            if PlayerMenuFogAppliedHeight[user.id] != PlayerMenuCameraHeight[user.id] then
                call ApplyMenuCameraFog(user.handle, PlayerMenuCameraHeight[user.id])
                set PlayerMenuFogAppliedHeight[user.id] = PlayerMenuCameraHeight[user.id]
            endif
            set z = GetTerrainZ(x, y) + PlayerMenuCameraHeight[user.id] + GetUnitDefaultFlyHeight(equipment.unit)
            call equipment.camera.setPosition(x, y - PlayerMenuCameraOffset[user.id], z)
            call equipment.refreshWeaponHud()

            if equipment.camera.applyCameraForPlayer(user.handle, false) then
                call Interface.updateAll(true, true, true)
            endif
        endmethod

        private method applyVisualState takes nothing returns nothing
            if this.getButton(thistype.SLOT_CAMERA_UP) != 0 then
                call this.getButton(thistype.SLOT_CAMERA_UP).showPlayer(this.user.handle, this.displayed, this.camera)
            endif
            if this.getButton(thistype.SLOT_CAMERA_DOWN) != 0 then
                call this.getButton(thistype.SLOT_CAMERA_DOWN).showPlayer(this.user.handle, this.displayed, this.camera)
            endif
            if .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WAVE_STATUS] != 0 then
                call SetTextTagText(.title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WAVE_STATUS].text, thistype.getWaveStatusText(this.user.id), 8 * 0.0027)
                call .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WAVE_STATUS].setPosition(X + HERO_NAME_X, HERO_NAME_Y + 0.22)
                call .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WAVE_STATUS].show(this.displayed, this.camera)
            endif
            call this.refreshWeaponHud()
            if .pictures[(this.user.id * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_1] != 0 then
                call .pictures[(this.user.id * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_1].setPosition(thistype.WEAPON_HUD_X, thistype.WEAPON_HUD_Y)
                call .pictures[(this.user.id * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_1].showPlayer(this.user.handle, this.displayed, this.camera)
            endif
            if .pictures[(this.user.id * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_2] != 0 then
                call .pictures[(this.user.id * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_2].setPosition(thistype.WEAPON_HUD_X, thistype.WEAPON_HUD_Y - thistype.WEAPON_HUD_GAP_Y)
                call .pictures[(this.user.id * .MAX_SLOTS) + thistype.PICTURE_WEAPON_SLOT_2].showPlayer(this.user.handle, this.displayed, this.camera)
            endif
            if .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_1] != 0 then
                call .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_1].setPosition(thistype.WEAPON_HUD_TEXT_X, thistype.WEAPON_HUD_TEXT_Y)
                call .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_1].show(this.displayed, this.camera)
            endif
            if .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_2] != 0 then
                call .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_2].setPosition(thistype.WEAPON_HUD_TEXT_X, thistype.WEAPON_HUD_TEXT_Y - thistype.WEAPON_HUD_TEXT_GAP_Y)
                call .title[(this.user.id * .MAX_SLOTS) + thistype.TEXT_WEAPON_SLOT_2].show(this.displayed, this.camera)
            endif
        endmethod

        method show takes boolean flag, Camera cam returns nothing
            local thistype current = 0
            local boolean wasDisplayed = this.displayed

            set this.camera = cam

            if flag then
                if not wasDisplayed then
                    set .DisplayCount = .DisplayCount + 1
                    if .DisplayCount >= 1 then
                        call PauseTimer(.UpdateTimer)
                        call TimerStart(.UpdateTimer, 0.01, true, function thistype.onDisplay)
                    endif
                endif

                if .PlayerCurrentUnit[this.user.id] != null then
                    set current = Client[.PlayerCurrentUnit[this.user.id]]
                endif
                if .PlayerCurrentUnit[this.user.id] != null and .PlayerCurrentUnit[this.user.id] != this.unit and current != 0 and current != this then
                    call current.show(false, this.camera)
                endif
                set .PlayerCurrentUnit[this.user.id] = this.unit
            elseif wasDisplayed then
                if .DisplayCount > 0 then
                    set .DisplayCount = .DisplayCount - 1
                endif
                if .PlayerCurrentUnit[this.user.id] == this.unit then
                    set .PlayerCurrentUnit[this.user.id] = null
                endif
                if .DisplayCount == 0 then
                    call PauseTimer(.UpdateTimer)
                else
                    call PauseTimer(.UpdateTimer)
                    call TimerStart(.UpdateTimer, 0.03125, true, function thistype.onDisplay)
                endif
                call ResetMenuCameraFog(this.player)
                set PlayerMenuFogAppliedHeight[this.user.id] = -1.
                if User.Local == this.player then
                    call ResetToGameCamera(0)
                endif
            endif

            set this.displayed = flag
            call this.applyVisualState()
        endmethod

        private static method onInit takes nothing returns nothing
            set thistype.UpdateTimer = CreateTimer()
            set thistype.Initialized = true
        endmethod
    endstruct

    function MenuClientRefreshEnemyPreviewForActivePlayers takes nothing returns nothing
        // Compatibilidad temporal: RestTime ya no debe pedir previews al MenuClient minimal.
    endfunction

    function MenuClientClearEnemyPreviewForActivePlayers takes nothing returns nothing
        // Compatibilidad temporal: no hay previews/modelos que limpiar.
    endfunction

    private function ExecuteCameraButton takes Client client, integer pid, integer slot returns nothing
        if slot == Client.SLOT_CAMERA_UP then
            call StepMenuCameraHeight(pid, GetMenuCameraHeightStep())
        elseif slot == Client.SLOT_CAMERA_DOWN then
            call StepMenuCameraHeight(pid, -GetMenuCameraHeightStep())
        endif

        call client.setWaveStatusTitle(WaveStatusText[pid])
        call client.show(true, client.camera)
    endfunction

    private function LeftClickCameraButton takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pid = GetPlayerId(p)
        local Client client = Client[Client.PlayerCurrentUnit[pid]]

        if client != 0 and p == client.user.handle and User.Local == p then
            call SelectUnit(client.unit, true)
        endif

        set p = null
        return false
    endfunction

    private function RightClickCameraButton takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pid = GetPlayerId(p)
        local Client client = Client[Client.PlayerCurrentUnit[pid]]
        local integer slot = 0

        if but != 0 then
            set slot = but.customValue
        endif
        if client == 0 or p != client.user.handle then
            set p = null
            return false
        endif

        if PlayerLastButton[pid] == but and PlayerLastSlot[pid] == slot + 1 then
            set PlayerLastButton[pid] = 0
            set PlayerLastSlot[pid] = 0
            call ExecuteCameraButton(client, pid, slot)
        else
            set PlayerLastButton[pid] = but
            set PlayerLastSlot[pid] = slot + 1
        endif

        if User.Local == p then
            call SelectUnit(client.unit, true)
        endif

        set p = null
        return false
    endfunction

    private function Init takes nothing returns nothing
        local User user = User.first
        loop
            exitwhen user == User.NULL
            set PlayerMenuCameraHeight[user.id] = GetDefaultMenuCameraHeight()
            set PlayerMenuCameraOffset[user.id] = GetDefaultMenuCameraOffset()
            set PlayerMenuFogAppliedHeight[user.id] = -1.
            set WeaponHudLastVersion[user.id] = -1
            set WaveStatusText[user.id] = "Wave"
            set PlayerLastSlot[user.id] = 0
            set PlayerLastButton[user.id] = 0
            set user = user.next
        endloop
        set FuncLClickSlot = Filter(function LeftClickCameraButton)
        set FuncRClickSlot = Filter(function RightClickCameraButton)
    endfunction

endlibrary

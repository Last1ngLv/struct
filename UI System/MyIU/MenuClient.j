library MenuClient initializer Init requires UserInterface,EquipHeroModels,PlayerMissileLoadout,TimerUtils,WaveTest,TenderSystem,PreConfi,EnemyPreviewConfig,PlayerHeroState // requires InventoryCore, EquipmentItem
    
globals
    public filterfunc FuncLClickSlot = null
    public filterfunc FuncRClickSlot = null
    public integer array PlayerLastSlot 
    public UIButton array PlayerLastButton
    private string array WaveStatusText
    private effect array WaveEnemyPreviewFx
    private integer array WaveEnemyPreviewWaveId
    private string array WaveEnemyPreviewModelPath
    private real array PlayerMenuCameraHeight
    private real array PlayerMenuCameraOffset
    private real array PlayerMenuFogAppliedHeight
endglobals
    
    public /*constant*/ function HERO_WINDOW_NAME takes unit u returns string
        return User[GetOwningPlayer(u)].nameColored
        // return GetHeroProperName(u)
    endfunction

    // Version local de Inventory.localInt para mostrar solo al jugador local.
    private function DesignLocalInt takes integer pid, integer value, integer other returns integer
        if (User.Local != User(pid).handle) then
            set value = other
        endif
        return value
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
        //
        // configuration
        //
        static constant real X = -0.32//0.425
        static constant real Y = .99
        
        static constant real WINDOW_SIZE = 0.21
        
        static constant real SLOT_OFFSET_Y          = 0.065
        static constant real SLOT_OFFSET_ROWRIGHT_X = 0.460
        static constant real SLOT_OFFSET_ROWLEFT_X  = 0.105
        
        static constant real HERO_NAME_Y = 0.86
        static constant real HERO_NAME_X = 0.28
        
        static constant real CHARMODEL_OFFSET_X  = X + 0.32
        static constant real CHARMODEL_OFFSET_Y  = 0.200
        
        static constant integer MAX_SLOTS = 11
        static constant real SLOT_WIDTH   = 0.095
        static constant real SLOT_HEIGHT  = 0.095 * SCREEN_ASPECT_RATIO
        
        static constant integer MODEL_DUMMY  = 'e000' // for character model
        static constant integer WINDOW_DUMMY = 'ewin'
        //
        // end config
        //
        
        readonly static boolean Initialized = false
        readonly static integer DisplayCount = 0
        readonly static hashtable Hashtable
        readonly static timer UpdateTimer
        readonly static unit array PlayerCurrentUnit
        readonly static thistype array UnitsIndex
        
        static UIButton array buttons[.MAX_SLOTS] //
        static UIPicture array slotButton[.MAX_SLOTS] //
        //InvItem array item[.MAX_SLOTS]
        integer array itemId[.MAX_SLOTS]
        static UIPicture array pictures[.MAX_SLOTS] //
        static UIPicture array selector //
        static UIText array title[.MAX_SLOTS] //
        static trigger onSocket
        
        UIPicture charModel
        UIPicture charModel2
        UIPicture array charMOrb[.MAX_SLOTS]
        effect array chain[.MAX_SLOTS]
        Camera camera
    
        unit unit
        player player
        User user
        
        readonly boolean displayed
        readonly thistype next
        readonly thistype prev
        
        static method operator [] takes unit u returns thistype
            return .UnitsIndex[GetUnitUserData(u)] 
        endmethod 
 
        method getButton takes integer index returns UIButton
            return this.buttons[(this.user.id * .MAX_SLOTS) + index]
        endmethod
        
        method getPicture takes integer index returns UIButton
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

        private method destroyEnemyPreviewFx takes nothing returns nothing
            if WaveEnemyPreviewFx[this.user.id] != null then
                call DestroyEffect(WaveEnemyPreviewFx[this.user.id])
                set WaveEnemyPreviewFx[this.user.id] = null
            endif
            set WaveEnemyPreviewWaveId[this.user.id] = 0
            set WaveEnemyPreviewModelPath[this.user.id] = ""
        endmethod

        method setEnemyPreviewWave takes integer waveId returns nothing
            local string modelPath
            local string previewText
            local real previewScale
            local boolean createFx
            set modelPath = EnemyPreviewGetModelPath(waveId)
            set previewText = EnemyPreviewGetText(waveId)
            set previewScale = EnemyPreviewGetModelScale(waveId)
            if this.title[(this.user.id * MAX_SLOTS) + 7] != 0 then
                call SetTextTagText(this.title[(this.user.id * MAX_SLOTS) + 7].text, previewText, 8 * 0.0020)
            endif
            if this.charModel != 0 then
                call SetUnitScale(this.charModel.picture, previewScale, previewScale, previewScale)
                set createFx = false
                if modelPath == "" then
                    call this.destroyEnemyPreviewFx()
                elseif WaveEnemyPreviewFx[this.user.id] == null then
                    set createFx = true
                elseif WaveEnemyPreviewWaveId[this.user.id] != waveId then
                    call this.destroyEnemyPreviewFx()
                    set createFx = true
                elseif WaveEnemyPreviewModelPath[this.user.id] != modelPath then
                    call this.destroyEnemyPreviewFx()
                    set createFx = true
                endif
                if createFx then
                    set WaveEnemyPreviewFx[this.user.id] = AddSpecialEffectTarget(modelPath, this.charModel.picture, "origin")
                    set WaveEnemyPreviewWaveId[this.user.id] = waveId
                    set WaveEnemyPreviewModelPath[this.user.id] = modelPath
                endif
            endif
        endmethod

        method clearEnemyPreview takes nothing returns nothing
            call this.destroyEnemyPreviewFx()
        endmethod

        method setWaveStatusTitle takes string value returns nothing
            if value == null or value == "" then
                set WaveStatusText[this.user.id] = "Wave"
            else
                set WaveStatusText[this.user.id] = value
            endif
            if this.title[(this.user.id * MAX_SLOTS) + 10] != 0 then
                call SetTextTagText(this.title[(this.user.id * MAX_SLOTS) + 10].text, thistype.getWaveStatusText(this.user.id), 8 * 0.0027)
            endif
        endmethod
         
        static method create takes unit u returns thistype
            local thistype this = thistype.allocate()
            local real x1 = X + SLOT_OFFSET_ROWLEFT_X
            local real x2 = X + SLOT_OFFSET_ROWRIGHT_X
            local real y1 = Y - SLOT_OFFSET_Y
            local integer i = 0

            set this.unit = u
            set this.player = GetOwningPlayer(u)
            set this.user = User[this.player]
            if WaveStatusText[this.user.id] == null or WaveStatusText[this.user.id] == "" then
                set WaveStatusText[this.user.id] = "Wave"
            endif
             
            set .UnitsIndex[GetUnitUserData(u)] = this

            //
            // GEAR SLOTS
            //
            
            if (this.getButton(0) == 0) then
            
                set selector[this.user.id] = UIPicture.createEx(X - 0.15, (Y + SLOT_OFFSET_Y) - .250, 0, .70, 'e000', 1, 1, 0)
                set selector[this.user.id].animIndex = 56
                call selector[this.user.id].show(false, this.camera)

                call AddSpecialEffectTarget("UI\\TRSHerolevel.mdx", selector[this.user.id].picture, "origin")
                
                // middle
                call this.setButton(0, UIButton.create(x1 + (.SLOT_WIDTH*0.75)+1.00+0.1, y1 - (.SLOT_HEIGHT*5)-0.15, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00D'))
                
                // Slot 1 era el boton viejo para abrir/cerrar Tender.
                // Ahora el Tender se abre con ESC desde TenderEscInteraction.
                
                call this.setButton(2, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.00, y1 - (.SLOT_HEIGHT*5)+1.05, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00G'))
                
                call this.setButton(3, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.00+0.1, y1 - (.SLOT_HEIGHT*5)-0.15, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00D')) // intev shot
                
                call this.setButton(4, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.50+0.1, y1 - (.SLOT_HEIGHT*5)-0.15, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00D')) // intev large
                
                call this.setButton(5, UIButton.create(x1 + (.SLOT_WIDTH*0.75)+0.00+0.1, y1 - (.SLOT_HEIGHT*5)-0.15, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00D')) // grade shot
                
                call this.setButton(6, UIButton.create(x1 + (.SLOT_WIDTH*0.75)+0.50+0.1, y1 - (.SLOT_HEIGHT*5)-0.15, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00D')) // lvlup orb
                
                call this.setButton(7, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.10, y1 - (.SLOT_HEIGHT*5)+1.05, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00H'))

                call this.setButton(8, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.90, y1 - (.SLOT_HEIGHT*5)+1.05, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00I'))
                //call this.setButton(7, UIButton.create(x1 + (.SLOT_WIDTH*0.75)+1.00, y1 - (.SLOT_HEIGHT*5)-0.20, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00F')) // int
                
                /*
                call this.setButton(2, UIButton.create(x2 - (.SLOT_WIDTH*2.00), y1 - (.SLOT_HEIGHT*5), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                
                call this.setButton(3, UIButton.create(x2 - (.SLOT_WIDTH*12), y1 + (.SLOT_HEIGHT*0.4), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(4, UIButton.create(x2 + (.SLOT_WIDTH*8), y1 + (.SLOT_HEIGHT*0.4), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(5, UIButton.create(x2 - (.SLOT_WIDTH*12), y1 - (.SLOT_HEIGHT*5.1), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(6, UIButton.create(x2 + (.SLOT_WIDTH*8), y1 - (.SLOT_HEIGHT*5.1), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                
                call this.setButton(7, UIButton.create(x2 - (.SLOT_WIDTH*12), y1 + (.SLOT_HEIGHT*-4), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(8, UIButton.create(x2 + (.SLOT_WIDTH*8), y1 + (.SLOT_HEIGHT*-4), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(9, UIButton.create(x2 - (.SLOT_WIDTH*12), y1 - (.SLOT_HEIGHT*9.6), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(10, UIButton.create(x2 + (.SLOT_WIDTH*8), y1 - (.SLOT_HEIGHT*9.6), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                */
                
                loop
                    exitwhen i == 11 // numero de botones siempre + 1, and charge too Max_SLOTS
                    if this.getButton(i) != 0 then
                        set this.getButton(i).customValue = i
                        set this.getButton(i).selectUnit = this.unit
                        set this.getButton(i).onLeftClick = FuncLClickSlot
                        set this.getButton(i).onRightClick = FuncRClickSlot
                        set this.slotButton[(this.user.id * MAX_SLOTS) + i] = UIPicture.create(this.getButton(i).minx + (.SLOT_WIDTH/6.3), this.getButton(i).maxy - 0.022, .SLOT_WIDTH * .7, .SLOT_HEIGHT * .7, 9, 'dbnk')
                        set this.slotButton[(this.user.id * MAX_SLOTS) + i].customValue = i
                    endif

                    set i = i + 1
                endloop
                
                set .pictures[(this.user.id * MAX_SLOTS) + 0] = UIPicture.createEx(X+0.03, Y-0.30, 11, WINDOW_SIZE+0.04, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))

                set .pictures[(this.user.id * MAX_SLOTS) + 1] = UIPicture.createEx(X+0.15, Y - 1.46, 11, WINDOW_SIZE-0.04, 'lewn', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                
                /*
     /*left*/   set .pictures[(this.user.id * MAX_SLOTS) + 2] = UIPicture.createEx(X - 0.90, Y + 0.10, 11, WINDOW_SIZE, 'bwn2', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
    /*right*/   set .pictures[(this.user.id * MAX_SLOTS) + 3] = UIPicture.createEx(X + 0.90, Y + 0.10, 11, WINDOW_SIZE, 'bwn2', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
   /*left*/     set .pictures[(this.user.id * MAX_SLOTS) + 4] = UIPicture.createEx(X - 0.90, Y - 0.80, 11, WINDOW_SIZE, 'bwn2', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
  /*right*/     set .pictures[(this.user.id * MAX_SLOTS) + 5] = UIPicture.createEx(X + 0.90, Y - 0.80, 11, WINDOW_SIZE, 'bwn2', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                */
                set .pictures[(this.user.id * MAX_SLOTS) + 2] = UIPicture.createEx(X - 0.23 , Y - 0.98-.46, 2, WINDOW_SIZE-0.05, 'pwin', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                set .pictures[(this.user.id * MAX_SLOTS) + 3] = UIPicture.createEx(X - 0.24 , Y - 0.98-.46, 11, WINDOW_SIZE + .03-.06, 'pwif', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                
                set .pictures[(this.user.id * MAX_SLOTS) + 4] = UIPicture.createEx(X-.5+.03, Y-0.30, 11, WINDOW_SIZE+0.04, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                set .pictures[(this.user.id * MAX_SLOTS) + 5] = UIPicture.createEx(X-1.+.03, Y-0.30, 11, WINDOW_SIZE+0.04, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                set .pictures[(this.user.id * MAX_SLOTS) + 6] = UIPicture.createEx(X+.5+.03, Y-0.30, 11, WINDOW_SIZE+0.04, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                set .pictures[(this.user.id * MAX_SLOTS) + 7] = UIPicture.createEx(X+1.+.03, Y-0.30, 11, WINDOW_SIZE+0.04, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))

            endif
            
            // enemy preview model slot (reused from the old charModel slot)
            set .charModel = UIPicture.createEx(CHARMODEL_OFFSET_X+0.00, .CHARMODEL_OFFSET_Y-0.15, 5, 0.11, MODEL_DUMMY, 1, 1, 0)
            set .charModel.animIndex = 140
            call SetUnitColor(.charModel.picture, this.user.color)
            //2
            set i = EquipGetHeroModel('hhou')
            set .charModel2 = UIPicture.createEx(CHARMODEL_OFFSET_X+0.03-1.117+0.744, .CHARMODEL_OFFSET_Y - 0.97-.063, 6, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charModel2.animIndex = 140
            call SetUnitColor(.charModel2.picture, this.user.color) //0.03-1.117+0.734

            call AddSpecialEffectTarget(HeroModelData(i).path, .charModel2.picture, "origin")
            
            set i = EquipGetHeroModel(GetPlayerMissileAbilityChoice(.player))
            set .charMOrb[0] = UIPicture.createEx(CHARMODEL_OFFSET_X-.5+.0, .CHARMODEL_OFFSET_Y - 0.20, 6, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charMOrb[0].animIndex = 140
            call SetUnitColor(.charMOrb[0].picture, this.user.color)
            call AddSpecialEffectTarget(HeroModelData(i).path, .charMOrb[0].picture, "origin")
            
            set .charMOrb[1] = UIPicture.createEx(CHARMODEL_OFFSET_X-1.+.0, .CHARMODEL_OFFSET_Y - 0.20, 6, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charMOrb[1].animIndex = 140
            call SetUnitColor(.charMOrb[1].picture, this.user.color)
            call AddSpecialEffectTarget(HeroModelData(i).path, .charMOrb[1].picture, "origin")
            
            set .charMOrb[2] = UIPicture.createEx(CHARMODEL_OFFSET_X+.5+.0, .CHARMODEL_OFFSET_Y - 0.20, 6, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charMOrb[2].animIndex = 140
            call SetUnitColor(.charMOrb[2].picture, this.user.color)
            call AddSpecialEffectTarget(HeroModelData(i).path, .charMOrb[2].picture, "origin")
            
            set .charMOrb[3] = UIPicture.createEx(CHARMODEL_OFFSET_X+1.+.0, .CHARMODEL_OFFSET_Y - 0.20, 6, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charMOrb[3].animIndex = 140
            call SetUnitColor(.charMOrb[3].picture, this.user.color)
            call AddSpecialEffectTarget(HeroModelData(i).path, .charMOrb[3].picture, "origin")

            /*
            call .pictures[(this.user.id * .MAX_SLOTS) + 1].showPlayer(this.user.handle, true, this.camera)
            call .pictures[(this.user.id * .MAX_SLOTS) + 2].showPlayer(this.user.handle, true, this.camera)
            call .pictures[(this.user.id * .MAX_SLOTS) + 3].showPlayer(this.user.handle, true, this.camera)
            */
            call this.charMOrb[0].showPlayer(this.user.toPlayer(), false, this.camera)
            call this.charMOrb[1].showPlayer(this.user.toPlayer(), false, this.camera)
            call this.charMOrb[2].showPlayer(this.user.toPlayer(), false, this.camera)
            call this.charMOrb[3].showPlayer(this.user.toPlayer(), false, this.camera)
            call this.charModel.showPlayer(this.user.toPlayer(), false, this.camera)
            
            
            /*
            set i = 0
            loop
                exitwhen i == 3 // numero de botones siempre + 1, and charge too Max_SLOTS
                
                set i = i + 1
            endloop
            */
            //set .title[this.user.id] = UIText.createEx(this.user.toPlayer(), X/1.4, 0.1, 1)
            
            set .title[(this.user.id * MAX_SLOTS) + 0] = UIText.createEx(this.user.toPlayer(), X/1.4, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + 1] = UIText.createEx(this.user.toPlayer(), X/1.9, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + 2] = UIText.createEx(this.user.toPlayer(), X/1.9, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + 3] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + 4] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            //set .title[(this.user.id * MAX_SLOTS) + 5] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + 5] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + 6] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + 7] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + 8] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + 9] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + 10] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)


            set thistype(0).next.prev = this
            set this.next = thistype(0).next
            set thistype(0).next = this

            set this.prev = 0

            return this
        endmethod

        /* Solo logica de equipamiento jeje guardadita 
        method equip takes InvItem itm, integer equipSlot returns boolean
            local integer slot = itm.slot - 1
            
            if (slot < 0) then
                return false
            endif
            
            if (this.item[equipSlot] != 0) then
                return false
            endif
            
            if (itm.slotAlt - 1 > 0) then
                if (equipSlot != slot and equipSlot != itm.slotAlt -1) then
                    call Inventory.err(this.player, "The item doesn't belong in that slot.")
                    return false
                endif
            else
                if (equipSlot != slot) then
                    call Inventory.err(this.player, "The item doesn't belong in that slot.")
                    return false
                endif
            endif
            
            if (itm.reqUnitType > 0 and GetUnitTypeId(this.unit) != itm.reqUnitType) then
                call Inventory.err(this.player, "Your unit type cannot equip this item.")
                return false
            endif
            
            if (itm.reqAbility > 0 and GetUnitAbilityLevel(this.unit, itm.reqAbility) < 0) then
                call Inventory.err(this.player, "Failed requirements.")
                return false
            endif
            
            if (GetHeroLevel(this.unit) < itm.reqLevel and GetUnitLevel(this.unit) < itm.reqLevel) then
                call Inventory.err(this.player, "Your level is too low to equip that item.")
                return false
            endif
            
            if (itm.equipCondition != null) then
                call TriggerClearConditions(InvItem.equipEval)
                call TriggerAddCondition(InvItem.equipEval, itm.equipCondition)
                set InvItem.eventUnit = this.unit
                if (not TriggerEvaluate(InvItem.equipEval)) then
                    return false
                endif
            endif

            set slot = equipSlot
            
            if (this.item[slot] != 0) then
                return false
            endif
            
            if (itm.equipAbility > 0) then
                call UnitAddAbility(this.unit, itm.equipAbility)
            endif
            
            set this.item[slot] = itm
            set this.itemId[slot] = itm.tempCustomId
            
            call this.slotButton[(this.user.id * .MAX_SLOTS) + slot].setTexture(Inventory.localInt(this.user.id, itm.icon, Inventory.ICON_TRANSPARENT))
            call this.slotButton[(this.user.id * .MAX_SLOTS) + slot].show(true, this.camera)

            set InvEventPlayer = this.player
            set InvEventItem = itm
            set InvEventSlot = equipSlot
            
            if (InvItem.onEquip != null and TriggerEvaluate(InvItem.onEquip)) then
                call TriggerExecute(InvItem.onEquip)
            endif
                    
            // add bonuses
            call itm.applyBonuses(this.unit)
            
            set itm.tempCustomId = 0
            
            return true
        endmethod */
        
        /* EL par de la otra cosita dksalj
        method unequip takes InvItem itm, integer slot returns boolean
            local InvItem i2
            local integer i = 0
            local integer cid = itm.tempCustomId
            
            if (slot != itm.slot -1 and slot != itm.slotAlt - 1) then
                return false
            endif
            
            if (itm.equipAbility > 0) then
                call UnitRemoveAbility(this.unit, itm.equipAbility)
            endif
            
            // run unequip event
            set InvEventPlayer = this.player
            set InvEventItem = this.item[slot]
            set InvEventSlot = slot
                
            if (InvItem.onUnequip != null and TriggerEvaluate(InvItem.onUnequip)) then
                call TriggerExecute(InvItem.onUnequip)
            endif
            
            set this.item[slot] = 0

            call this.slotButton[(this.user.id * .MAX_SLOTS) + slot].setTexture(Inventory.ICON_EMPTY)
            call this.slotButton[(this.user.id * .MAX_SLOTS) + slot].show(false, this.camera)
            
            // remove bonuses
            call itm.removeBonuses(this.unit)

            return true
        endmethod */
        
        method destroy takes nothing returns nothing
            set this.next.prev = this.prev
            set this.prev.next = this.next
            
            call this.clearEnemyPreview()
            if this.charModel != 0 then
                call this.charModel.destroy()
            endif
            call this.charModel2.destroy()
            
            call this.deallocate()
        endmethod

        private static method onDisplay takes nothing returns nothing
            local User user = User(User.LocalId)
            local thistype equipment = Client[Client.PlayerCurrentUnit[user.id]]
            local real x
            local real y 
            local real z
                                                            //para doble interfaz y evitar doble cam y sa wea xDD
            if (equipment == 0 or not equipment.displayed /*or Inventory.PlayerCurrent[equipment.user.id] > 0*/ or User.Local != user.handle) then
                return
            endif
            /*
            equipment == 0
            No hay instancia de equipo activa para ese jugador.

            not equipment.displayed
            La UI de equipo está oculta.

            Inventory.PlayerCurrent[equipment.user.id] > 0
            Hay inventario activo para ese jugador (evita conflicto entre paneles).

            User.Local != user.handle
            No es el cliente local que debe renderizar esa cámara/UI.
            */
            
            set x = GetUnitX(equipment.unit)
            set y = GetUnitY(equipment.unit)
            call EnsureMenuCameraSettings(user.id)
            if PlayerMenuFogAppliedHeight[user.id] != PlayerMenuCameraHeight[user.id] then
                call ApplyMenuCameraFog(user.handle, PlayerMenuCameraHeight[user.id])
                set PlayerMenuFogAppliedHeight[user.id] = PlayerMenuCameraHeight[user.id]
            endif
            set z = GetTerrainZ(x, y) + PlayerMenuCameraHeight[user.id] + GetUnitDefaultFlyHeight(equipment.unit)
            call equipment.camera.setPosition(x, y - PlayerMenuCameraOffset[user.id], z)
            
            if equipment.camera.applyCameraForPlayer(user.handle, false) then
                call Interface.updateAll(true, true, true)
            endif
        endmethod
        
        private method isTenderPanelVisible takes nothing returns boolean
            return this.displayed and isTender[this.user.id]
        endmethod

        private method shouldShowButton takes integer slot returns boolean
            if not this.displayed then
                return false
            endif

            if slot == 2 or slot == 7 then
                return true
            endif

            if slot == 0 or slot == 3 or slot == 4 or slot == 6 then
                return isTender[this.user.id]
            endif

            return false
        endmethod

        private method applyButtonVisibility takes nothing returns nothing
            local integer i = 0
            loop
                exitwhen i == thistype.MAX_SLOTS
                if this.getButton(i) != 0 then
                    call this.getButton(i).showPlayer(this.user.handle, this.shouldShowButton(i), this.camera)
                endif
                set i = i + 1
            endloop
        endmethod

        private method applyTitleLayout takes nothing returns nothing
            call .title[(this.user.id * MAX_SLOTS) + 0].setPosition(X + HERO_NAME_X-0.12, HERO_NAME_Y-.28)
            call .title[(this.user.id * MAX_SLOTS) + 1].setPosition(X + HERO_NAME_X-.27-0.12+.18, HERO_NAME_Y-1.73)
            call .title[(this.user.id * MAX_SLOTS) + 2].setPosition(X + HERO_NAME_X+.01-0.54+.18, HERO_NAME_Y-1.80)
            call .title[(this.user.id * MAX_SLOTS) + 3].setPosition(X + HERO_NAME_X+0.95, HERO_NAME_Y-0.85)
            call .title[(this.user.id * MAX_SLOTS) + 4].setPosition(X + HERO_NAME_X+1.4, HERO_NAME_Y-0.85)
            call .title[(this.user.id * MAX_SLOTS) + 5].setPosition(X + HERO_NAME_X-0.55, HERO_NAME_Y-0.85)
            call .title[(this.user.id * MAX_SLOTS) + 6].setPosition(X + HERO_NAME_X-1.05, HERO_NAME_Y-0.85)
            call .title[(this.user.id * MAX_SLOTS) + 7].setPosition(X + HERO_NAME_X-0.12, HERO_NAME_Y-1.05)
            call .title[(this.user.id * MAX_SLOTS) + 8].setPosition(X + HERO_NAME_X+0.45, HERO_NAME_Y-0.85)
            call .title[(this.user.id * MAX_SLOTS) + 9].setPosition(X + HERO_NAME_X-0.14, HERO_NAME_Y+0.08)
            call .title[(this.user.id * MAX_SLOTS) + 10].setPosition(X + HERO_NAME_X-0.0, HERO_NAME_Y+0.22)
        endmethod

        private method applyTitleText takes nothing returns nothing
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 0].text, "NextEnemyInformation", 8 * 0.0023)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 1].text, Message, 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 2].text, "Fuente", 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 3].text, "Improve Instance\nNumer instancia: "+ I2S(GetPlayerMissileInstanceCount(this.user.toPlayer())), 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 4].text, "|cffff6a00L|cffff7400O|cffff7e00R|cffff8800D|cffff9200S|cffff6a00 E|cffff7400N|cffff7e00G|cffff8800I|cffff9200N|cffff9c00E|cffffa600S|r", 8 * 0.0025)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 5].text, "Improve RegeShot\nReg impact en: "+ R2S(GetPlayerMissileHealOnHit(this.user.toPlayer())), 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 6].text, "Improve Damage\nBase Dmg en: "+ R2S(GetPlayerMissileDamageValue(this.user.toPlayer())), 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 7].text, EnemyPreviewGetText(TargetWave), 8 * 0.0018)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 8].text, "Improve OrbLevel\nMax4, OrbLevel: "+ I2S(GetPlayerOrbLevel(this.user.toPlayer())), 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 9].text, "Welcome To LordsEngines", 8 * 0.0027)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + 10].text, thistype.getWaveStatusText(this.user.id), 8 * 0.0027)
        endmethod

        private method applyTitleVisibility takes nothing returns nothing
            local boolean tenderVisible = this.isTenderPanelVisible()
            call this.title[(this.user.id * MAX_SLOTS) + 0].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + 1].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + 2].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + 3].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + 4].show(false, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + 5].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + 6].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + 7].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + 8].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + 9].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + 10].show(this.displayed, this.camera)
        endmethod

        private method applyPictureVisibility takes nothing returns nothing
            local integer i = 0
            local boolean tenderVisible = this.isTenderPanelVisible()
            loop
                exitwhen i == 8
                if .pictures[(this.user.id * .MAX_SLOTS) + i] != 0 then
                    call .pictures[(this.user.id * .MAX_SLOTS) + i].showPlayer(this.user.handle, tenderVisible, this.camera)
                endif
                set i = i + 1
            endloop
        endmethod

        private method applyModelVisibility takes nothing returns nothing
            local integer i = 0
            local boolean tenderVisible = this.isTenderPanelVisible()
            call SetUnitColor(.charModel.picture, this.user.color)
            call SetUnitColor(.charModel2.picture, this.user.color)
            call this.charModel2.showPlayer(this.user.toPlayer(), tenderVisible, this.camera)
            call this.charModel.showPlayer(this.user.toPlayer(), tenderVisible, this.camera)
            loop
                exitwhen i == 4
                call this.charMOrb[i].showPlayer(this.user.toPlayer(), tenderVisible, this.camera)
                set i = i + 1
            endloop
        endmethod

        private method applyVisualState takes nothing returns nothing
            call this.applyTitleLayout()
            call this.applyTitleText()
            call this.applyTitleVisibility()
            call this.applyPictureVisibility()
            call this.applyModelVisibility()
            call this.applyButtonVisibility()
            if not this.displayed and selector[this.user.id] != 0 then
                call selector[this.user.id].showPlayer(this.user.handle, false, this.camera)
                set PlayerLastSlot[this.user.id] = 0
                set PlayerLastButton[this.user.id] = 0
            endif
        endmethod

        method show takes boolean flag, Camera cam returns nothing
            local thistype equip = 0
            local boolean wasDisplayed = this.displayed
            
            set this.camera = cam
            
            if (flag) then
                if not wasDisplayed then
                    set .DisplayCount = .DisplayCount + 1
                    if (DisplayCount >= 1) then
                        call PauseTimer(.UpdateTimer)
                        call TimerStart(.UpdateTimer, 0.01, true, function thistype.onDisplay)
                    endif
                endif
                
                if (.PlayerCurrentUnit[this.user.id] != null) then
                    set equip = Client[.PlayerCurrentUnit[this.user.id]]
                endif
                
                if (.PlayerCurrentUnit[this.user.id] != null and .PlayerCurrentUnit[this.user.id] != this.unit and equip != this) then
                    call equip.show(false, this.camera)
                endif
                
                set .PlayerCurrentUnit[this.user.id] = this.unit
            elseif wasDisplayed then
                if .DisplayCount > 0 then
                    set .DisplayCount = .DisplayCount - 1
                endif
                if .PlayerCurrentUnit[this.user.id] == this.unit then
                    set .PlayerCurrentUnit[this.user.id] = null
                endif
                
                if (DisplayCount == 0) then
                    call PauseTimer(.UpdateTimer)
                else
                    call PauseTimer(.UpdateTimer)
                    call TimerStart(.UpdateTimer, 0.03125, true, function thistype.onDisplay)
                endif
                if (User.Local == this.player) then
                    call ResetMenuCameraFog(this.player)
                    set PlayerMenuFogAppliedHeight[this.user.id] = -1.
                    call ResetToGameCamera(0)
                endif
            endif
            
            set this.displayed = flag
            call this.applyVisualState()
        endmethod
        
        private static method onInit takes nothing returns nothing
            set thistype.Hashtable = InitHashtable()
            set thistype.UpdateTimer = CreateTimer()
            set thistype.Initialized = true
        endmethod
        
    endstruct

    function MenuClientRefreshEnemyPreviewForActivePlayers takes nothing returns nothing
        local integer i = 0
        local User u
        local unit hero
        local Client client
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set hero = PlayerHero[u.id]
            if hero != null and GetUnitTypeId(hero) != 0 then
                set client = Client[hero]
                if client != 0 then
                    call client.setEnemyPreviewWave(TargetWave)
                endif
            endif
            set i = i + 1
        endloop
        set hero = null
    endfunction

    function MenuClientClearEnemyPreviewForActivePlayers takes nothing returns nothing
        local integer i = 0
        local User u
        local unit hero
        local Client client
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set hero = PlayerHero[u.id]
            if hero != null and GetUnitTypeId(hero) != 0 then
                set client = Client[hero]
                if client != 0 then
                    call client.clearEnemyPreview()
                endif
            endif
            set i = i + 1
        endloop
        set hero = null
    endfunction
    
    /*
    private function OnInventoryItemClick takes nothing returns nothing
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pid = GetPlayerId(p)
        local Inventory inv =  Inventory.PlayerCurrent[pid]
        local integer slot =  but.customValue
        local integer itemId = 0
        local integer last = InvPlayerLastSlot[inv.pid] - 1
        local integer lastItemId
        local UIButton lastButton = InvPlayerLastButton[inv.pid]
        local Equipment gear = Equipment[Equipment.PlayerCurrentUnit[inv.pid]]
        local integer gearSlot
        local InvItem itm
        
        call Equipment.selector[inv.pid].show(false, inv.camera)
       
        if (gear <= 0) then
            return
        endif
        
        if (PlayerLastSlot[inv.pid] > 0) then
            
            set gearSlot = PlayerLastSlot[inv.pid] - 1

            if (inv.getItem(slot) == 0) then
                set gear.item[gearSlot].tempCustomId = gear.itemId[gearSlot]
                call inv.setItem(slot, gear.item[gearSlot])
                
                set gear.item[gearSlot].tempCustomId = gear.itemId[gearSlot]
                call gear.unequip(gear.item[gearSlot], gearSlot)
            endif
            
            set PlayerLastSlot[inv.pid] = 0
        else
            set itm = inv.getItem(slot)
            
            if (itm > 0 and not itm.isSocket) then
                set but = gear.getButton(itm.slot - 1)
                
                call Equipment.selector[inv.pid].show(true, inv.camera)
                call Equipment.selector[inv.pid].setPosition(but.centerx - 0.007, but.centery + 0.0272)
                call Equipment.selector[inv.pid].showPlayer(Player(inv.pid), true, inv.camera)
            endif
        endif
    endfunction
    
    private function OnInventoryItemRightClick takes nothing returns nothing
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pid = GetPlayerId(p)
        local Inventory inv =  Inventory.PlayerCurrent[pid]
        local integer slot =  but.customValue
        local Equipment gear = Equipment[Equipment.PlayerCurrentUnit[inv.pid]]
        local InvItem itm = inv.getItem(slot)
        local integer gearSlot = itm.slot - 1
        local integer unequippedSlot = 0
        local InvItem unequipItem = 0
        local integer unequipId = 0
        
        if (gear <= 0 or itm <= 0) then
            return
        endif
        
        set itm.tempCustomId = inv.getItemId(slot)
        
        if (gear.item[gearSlot] > 0) then
            set unequipId = gear.itemId[gearSlot]
            set gear.item[gearSlot].tempCustomId = unequipId
            call gear.unequip(gear.item[gearSlot], gearSlot)
            set unequippedSlot = InvEventSlot
            set unequipItem = InvEventItem
        endif
        
        set itm.tempCustomId = inv.getItemId(slot)
        
        if (gear.equip(itm, itm.slot - 1)) then
            call inv.setItem(slot, 0)
            set unequipItem.tempCustomId = unequipId
            call inv.addItem(unequipItem)
        elseif (unequipItem > 0) then
            call gear.equip(unequipItem, unequippedSlot)
        endif
    endfunction */ 

    /* derecho, no por ahora
    private function RClickItemSlot takes nothing returns boolean
        local UIButton but   = GetTriggerButton()
        local unit u         = Equipment.PlayerCurrentUnit[GetPlayerId(GetClickingPlayer())]
        local Equipment gear = Equipment[u]
        local Inventory inv  = Inventory[u]
        local integer slot   = but.customValue
        local integer itemId
        local InvItem itm
        local integer cid
        
        if (GetClickingPlayer() != User(inv.pid).handle or gear.item[slot] <= 0) then
            return false
        endif

        // clear tooltip
        call inv.showLines(inv.pid, false, inv.camera)
        
        set itm = gear.item[slot]
        set itemId = itm.id
        set cid = gear.itemId[slot]
        
        set gear.item[slot].tempCustomId = cid
        
        if (gear.unequip(itm, slot)) then
            set itm.tempCustomId = cid
            if (not inv.addItem(itm)) then
                set gear.item[slot].tempCustomId = cid
                call gear.equip(itm, slot)
                return false
            endif
        else
            return false
        endif
    
        call Inventory.showTooltip(inv, false)
        
        return false
    endfunction */
    
    private function MenuClientGetSlotTooltip takes player p, integer slot returns string
        local integer pid = GetPlayerId(p)
        if slot == 0 then
            return "|cffffcc00Improve Instance|r\nCosto: 1 oro\nActual: " + I2S(GetPlayerMissileInstanceCount(p))
        elseif slot == 2 then
            return "|cffffcc00Camara +|r\nSube la altura de camara.\nActual: " + I2S(R2I(PlayerMenuCameraHeight[pid]))
        elseif slot == 3 then
            return "|cffffcc00Improve Damage|r\nCosto: 1 oro\nActual: " + R2S(GetPlayerMissileDamageValue(p))
        elseif slot == 4 then
            return "|cffffcc00Improve RegeShot|r\nCosto: 1 oro\nActual: " + R2S(GetPlayerMissileHealOnHit(p))
        elseif slot == 5 then
            if GetPlayerMissileUseSmartRecast(p) then
                return "|cffffcc00Smart Recast|r\nCosto: 10 oro\nEstado: ON"
            endif
            return "|cffffcc00Smart Recast|r\nCosto: 10 oro\nEstado: OFF"
        elseif slot == 6 then
            return "|cffffcc00Improve Orb Level|r\nCosto: 1 oro\nMax: 4\nActual: " + I2S(GetPlayerOrbLevel(p))
        elseif slot == 7 then
            return "|cffffcc00Camara -|r\nBaja la altura de camara.\nActual: " + I2S(R2I(PlayerMenuCameraHeight[pid]))
        endif
        return "|cffffcc00Boton sin accion activa|r"
    endfunction

    private function MenuClientShowSlotTooltip takes UIButton but, player p returns nothing
        local integer slot = but.customValue
        call DisplayTimedTextToPlayer(p, .52, .82, 3.5, MenuClientGetSlotTooltip(p, slot) + "\n|cff999999Click derecho: seleccionar / confirmar.|r")
    endfunction

    private function ExecuteMenuSlotAction takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pdex = GetPlayerId(p)
        local Client equip = Client[Client.PlayerCurrentUnit[pdex]]
        //local Inventory inv = Inventory.PlayerCurrent[equip.user.id] //nventario activo asociado al mismo usuario del equip.
        local integer slot =  but.customValue
        //local integer last = InvPlayerLastSlot[inv.pid] - 1
        local integer itemId = 0
        local User u = User[GetClickingPlayer()]
        local integer i = 0
        local integer oro = GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)
        
        
        //local UIButton lastButton = InvPlayerLastButton[equip.user.id]
        //local InvItem itm
        if equip == 0 then
            return false
        endif
        if (p != equip.user.handle) then
            return false
        endif
        if (User.Local == p) then
            call SelectUnit(but.picture, false)
            call SelectUnit(equip.unit, true)
        endif
        
        if (slot == 0) then
            if oro > 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - 1)
                call SetPlayerMissileInstanceCount(GetClickingPlayer(),GetPlayerMissileInstanceCount(GetClickingPlayer())+1)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                // Acción que quieres ejecutar
                //call DisplayTextToPlayer(p,0,0,"Se restó 1 de oro")
            elseif oro <= 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Oro Insuficiente Para Comprar Instance!|r")
            else 
                if User.fromLocal() == u then
                    call StartSound(error_Neg)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Lords Engines No Activa/Fuera de Distancia!|r")            
            endif
        endif
        
        if (slot == 2) then
            call StepMenuCameraHeight(pdex, GetMenuCameraHeightStep())
            call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Cam Height:|r " + I2S(R2I(PlayerMenuCameraHeight[pdex])) + " |cffffcc00Offset:|r -" + I2S(R2I(PlayerMenuCameraOffset[pdex])))
        endif
        
        if (slot == 3) then
            if oro > 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - 1)
                call SetPlayerMissileDamageValue(GetClickingPlayer(),GetPlayerMissileDamageValue(GetClickingPlayer())+0.05)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                // Acción que quieres ejecutar
                //call DisplayTextToPlayer(p,0,0,"Se restó 1 de oro")
            elseif oro <= 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Oro Insuficiente Para Comprar damage!|r")
            else 
                if User.fromLocal() == u then
                    call StartSound(error_Neg)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Lords Engines No Activa/Fuera de Distancia!|r")            
            endif
            
        endif
        
        if (slot == 4) then
            if oro > 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - 1)
                call SetPlayerMissileHealOnHit(GetClickingPlayer(),GetPlayerMissileHealOnHit(GetClickingPlayer())+2.5)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                // Acción que quieres ejecutar
                //call DisplayTextToPlayer(p,0,0,"Se restó 1 de oro")
            elseif oro <= 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Oro Insuficiente Para Comprar Rege!|r")
            else 
                if User.fromLocal() == u then
                    call StartSound(error_Neg)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Lords Engines No Activa/Fuera de Distancia!|r")            
            endif
            
        endif
        
        if (slot == 5) then
            if oro > 5 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) and GetPlayerMissileUseSmartRecast(GetClickingPlayer()) == false then
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - 10)
                call SetPlayerMissileUseSmartRecast(GetClickingPlayer(),true)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                // Acción que quieres ejecutar
                //call DisplayTextToPlayer(p,0,0,"Se restó 1 de oro")
            elseif oro <= 5 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) and GetPlayerMissileUseSmartRecast(GetClickingPlayer()) == false then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Oro Insuficiente Para Comprar Smart!|r")
                
            elseif GetPlayerMissileUseSmartRecast(GetClickingPlayer()) == true then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Smart On!|r")
            else 
                if User.fromLocal() == u then
                    call StartSound(error_Neg)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Lords Engines No Activa/Fuera de Distancia!|r")            
            endif
            
            
        endif
        
        if (slot == 6) then
            if oro > 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) and GetPlayerOrbLevel(GetClickingPlayer()) <= 3 then
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - 1)
                call SetPlayerOrbLevel(GetClickingPlayer(),GetPlayerOrbLevel(GetClickingPlayer())+1)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                // Acción que quieres ejecutar
                //call DisplayTextToPlayer(p,0,0,"Se restó 1 de oro")
            elseif oro <= 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) and GetPlayerOrbLevel(GetClickingPlayer()) <= 3 then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Oro Insuficiente Para Comprar LevelOrb!|r")
                
            elseif GetPlayerOrbLevel(GetClickingPlayer()) == 4 then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Max LevelOrb!|r")
            else 
                if User.fromLocal() == u then
                    call StartSound(error_Neg)
                    call ClearTextMessages()
                endif

                call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Lords Engines No Activa/Fuera de Distancia!|r")            
            endif
        endif
        
        if (slot == 7) then 
            call StepMenuCameraHeight(pdex, -GetMenuCameraHeightStep())
            call DisplayTimedTextToPlayer(u.toPlayer(), .52, .96, 2., "|cffffcc00Cam Height:|r " + I2S(R2I(PlayerMenuCameraHeight[pdex])) + " |cffffcc00Offset:|r -" + I2S(R2I(PlayerMenuCameraOffset[pdex])))
        endif

        /*
        if (slot == 2) then
            call UnitAddItemSwapped(CreateItem('tdex',0.,0.),PlayerHero[GetPlayerId(p)])
        endif
        if (slot == 3) then
            call SelectHeroSkill( PlayerHero[GetPlayerId(p)], 'AHfs' )
        endif
        if (slot == 4) then
            call SelectHeroSkill( PlayerHero[GetPlayerId(p)], 'AHbn' )
        endif
        if (slot == 5) then
            call SelectHeroSkill( PlayerHero[GetPlayerId(p)], 'AHdr' )
        endif
        if (slot == 6) then
            call SelectHeroSkill( PlayerHero[GetPlayerId(p)], 'AHpx' )
        endif
        if (slot == 7) then
            call IncUnitAbilityLevel(PlayerHero[GetPlayerId(p)],'AHfs')
        endif
        if (slot == 8) then
            call IncUnitAbilityLevel(PlayerHero[GetPlayerId(p)],'AHbn')
        endif
        if (slot == 9) then
            call IncUnitAbilityLevel(PlayerHero[GetPlayerId(p)],'AHdr')
        endif
        if (slot == 10) then
            call IncUnitAbilityLevel(PlayerHero[GetPlayerId(p)],'AHpx')
        endif
        */
        
        /*
        if (InvButtonDisabled[but]) then
            return false
        endif
        */
        //call inv.showLines(inv.pid, false, inv.camera) Oculta líneas/guías visuales del inventario antes de seguir.
        
        //set PlayerLastSlot[equip.user.id] = slot + 1
        
        // equip item
        /*
        if (inv > 0 and last+1 > 0) then
        
            set last = (Inventory.MAX_SLOTS * inv.currentPage) + last
            
            set itm = inv.getItem(last)
            
            if (itm.slot - 1 == slot or itm.slotAlt - 1 == slot) then
                set itm.tempCustomId = inv.getItemId(last)
                
                if (equip.equip(itm, slot)) then
                    set PlayerLastSlot[inv.pid] = 0
                    call inv.setItem(last, 0)
            
                    call TimerStart(NewTimerEx(but), 2, false, function InventoryCore_GracePeriod)
                    set InvButtonDisabled[but] = true
                endif
            endif
        endif
        */ 

        //set InvPlayerLastButton[equip.user.id] = but
        //set InvPlayerLastSlot[equip.user.id] = 0
        
        /*
        if (but != lastButton) then
            call SetUnitVertexColor(lastButton.picture, 255, 255, 255, 255)
            call SetUnitVertexColor(but.picture, 175, 175, 175, 255)
        endif
        
        set itemId = equip.item[slot].id
        */
        /*
        call Inventory.selector[inv.pid].show(false, inv.camera)
        call Equipment.selector[inv.pid].setPosition(but.centerx - 0.007, but.centery + 0.0272)
        call Equipment.selector[inv.pid].showPlayer(Player(inv.pid), true, inv.camera)
        */
        /*
        if (itemId > 0) then
            set equip.item[slot].tempCustomId = equip.itemId[slot]
            
            call inv.setTooltipTitle(GetObjectName(itemId))
            call GetInvItem(itemId).buildDescription(inv.owner)
            call inv.setTooltipCost("|cffffcc00" + I2S(GetInvItem(itemId).cost) + "|r")
            call inv.setTooltipIcon(inv.localInt(inv.pid, GetItemIcon(itemId), Inventory.ICON_TRANSPARENT))
            
            set equip.item[slot].tempCustomId = 0
        endif
        
        // display tooltip
        set Inventory.TOOLTIP_X = but.minx - 0.4
        set Inventory.TOOLTIP_Y = but.miny - 0.08
        
        call Inventory.showTooltip(inv, itemId > 0)
        */ 
        call equip.show(true, equip.camera)
        set p = null
        return false
    endfunction
    
    private function LClickItemSlot takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pdex = GetPlayerId(p)
        local Client equip = Client[Client.PlayerCurrentUnit[pdex]]

        if equip == 0 then
            set p = null
            return false
        endif
        if p != equip.user.handle then
            set p = null
            return false
        endif

        if (User.Local == p) then
            call SelectUnit(but.picture, false)
            call SelectUnit(equip.unit, true)
        endif

        call MenuClientShowSlotTooltip(but, p)
        set p = null
        return false
    endfunction

    private function RClickItemSlot takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pdex = GetPlayerId(p)
        local Client equip = Client[Client.PlayerCurrentUnit[pdex]]
        local integer slot = but.customValue

        if equip == 0 then
            set p = null
            return false
        endif
        if p != equip.user.handle then
            set p = null
            return false
        endif

        if (User.Local == p) then
            call SelectUnit(but.picture, false)
            call SelectUnit(equip.unit, true)
        endif

        if PlayerLastButton[pdex] == but and PlayerLastSlot[pdex] == slot + 1 then
            set PlayerLastButton[pdex] = 0
            set PlayerLastSlot[pdex] = 0
            if Client.selector[pdex] != 0 then
                call Client.selector[pdex].showPlayer(p, false, equip.camera)
            endif
            set p = null
            return ExecuteMenuSlotAction()
        endif

        set PlayerLastButton[pdex] = but
        set PlayerLastSlot[pdex] = slot + 1
        if Client.selector[pdex] != 0 then
            call Client.selector[pdex].setPosition(but.centerx - 0.007, but.centery + 0.0272)
            call Client.selector[pdex].showPlayer(p, true, equip.camera)
        endif
        call MenuClientShowSlotTooltip(but, p)

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
            set user = user.next
        endloop
        set FuncLClickSlot = Filter(function LClickItemSlot)
        set FuncRClickSlot = Filter(function RClickItemSlot)
        //call Inventory.addLeftClickHook(function OnInventoryItemClick)
        //call Inventory.addRightClickHook(function OnInventoryItemRightClick)
    endfunction

endlibrary

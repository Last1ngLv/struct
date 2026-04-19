library EquipmentCore initializer Init requires InventoryCore, EquipmentItem
    
    globals
        public filterfunc FuncLClickSlot = null
        public filterfunc FuncRClickSlot = null
        public integer array PlayerLastSlot 
    endglobals
    
    public /*constant*/ function HERO_WINDOW_NAME takes unit u returns string
        return User[GetOwningPlayer(u)].nameColored
        // return GetHeroProperName(u)
    endfunction
    
    struct Equipment
        //
        // configuration
        //
        static constant real X = 0.425
        static constant real Y = .93
        
        static constant real WINDOW_SIZE = 0.28
        
        static constant real SLOT_OFFSET_Y          = 0.065
        static constant real SLOT_OFFSET_ROWRIGHT_X = 0.460
        static constant real SLOT_OFFSET_ROWLEFT_X  = 0.105
        
        static constant real HERO_NAME_Y = 0.9
        
        static constant real CHARMODEL_OFFSET_X  = X + 0.32
        static constant real CHARMODEL_OFFSET_Y  = 0.200
        
        static constant integer MAX_SLOTS = 14
        static constant real SLOT_WIDTH   = 0.090
        static constant real SLOT_HEIGHT  = 0.090 * SCREEN_ASPECT_RATIO
        
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
        
        static UIButton array buttons[.MAX_SLOTS]
        static UIPicture array slotButton[.MAX_SLOTS]
        InvItem array item[.MAX_SLOTS]
        integer array itemId[.MAX_SLOTS]
        static UIPicture array pictures[.MAX_SLOTS]
        static UIPicture array selector
        static UIText array title
        static trigger onSocket
        
        UIPicture charModel
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
        
        method setButton takes integer index, UIButton value returns nothing
            set this.buttons[(this.user.id * .MAX_SLOTS) + index] = value
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
                call this.setButton(12, UIButton.create(x1 + (.SLOT_WIDTH*1.5), y1 - (.SLOT_HEIGHT*5), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B005'))
                call this.setButton(13, UIButton.create(x2 - (.SLOT_WIDTH*1.5), y1 - (.SLOT_HEIGHT*5), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B00B'))
                
                // left side
                call this.setButton(0, UIButton.create(x1, y1, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B003'))
                call this.setButton(1, UIButton.create(x1, y1 - (.SLOT_HEIGHT*1), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B004'))
                call this.setButton(2, UIButton.create(x1, y1 - (.SLOT_HEIGHT*2), .SLOT_WIDTH, .SLOT_HEIGHT, 10,'B006'))
                call this.setButton(3, UIButton.create(x1, y1 - (.SLOT_HEIGHT*3), .SLOT_WIDTH, .SLOT_HEIGHT, 10,'B007'))
                call this.setButton(4, UIButton.create(x1, y1 - (.SLOT_HEIGHT*4), .SLOT_WIDTH, .SLOT_HEIGHT, 10,'B008'))
                call this.setButton(5, UIButton.create(x1, y1 - (.SLOT_HEIGHT*5), .SLOT_WIDTH, .SLOT_HEIGHT, 10,'D05W'))
                
                // right side
                call this.setButton(6, UIButton.create(x2, y1, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B009'))
                call this.setButton(7, UIButton.create(x2, y1 - (.SLOT_HEIGHT*1), .SLOT_WIDTH, .SLOT_HEIGHT, 10,'B00A'))
            
                call this.setButton(8, UIButton.create(x2, y1 - (.SLOT_HEIGHT*2), .SLOT_WIDTH, .SLOT_HEIGHT, 10,'B00C'))
                call this.setButton(9, UIButton.create(x2, y1 - (.SLOT_HEIGHT*3), .SLOT_WIDTH, .SLOT_HEIGHT, 10,'B00D'))
                call this.setButton(10, UIButton.create(x2, y1 - (.SLOT_HEIGHT*4), .SLOT_WIDTH, .SLOT_HEIGHT, 10,'B00E'))
                call this.setButton(11, UIButton.create(x2, y1 - (.SLOT_HEIGHT*5), .SLOT_WIDTH, .SLOT_HEIGHT, 10,'B00F'))
                            
                loop
                    exitwhen i == 14
                    set this.getButton(i).customValue = i
                    
                     set this.getButton(i).selectUnit = this.unit
                     
                    set this.getButton(i).onLeftClick = FuncLClickSlot
                    set this.getButton(i).onRightClick = FuncRClickSlot
                    
                    set this.slotButton[(this.user.id * MAX_SLOTS) + i] = UIPicture.create(this.getButton(i).minx + (.SLOT_WIDTH/6.3), this.getButton(i).maxy - 0.022, .SLOT_WIDTH * .7, .SLOT_HEIGHT * .7, 9, Inventory.ICON_EMPTY)
                    set this.slotButton[(this.user.id * MAX_SLOTS) + i].customValue = i

                    set i = i + 1
                endloop
                
                set .pictures[(this.user.id * MAX_SLOTS) + 0] = UIPicture.createEx(X, Y, 11, WINDOW_SIZE, .WINDOW_DUMMY, 140., 130., Inventory.localInt(this.user.id, Inventory.RACE_BORDERS_START+(GetHandleId(GetPlayerRace(this.player))-1), Inventory.ICON_TRANSPARENT))
                
            endif
            
            // unit model
            set i = EquipGetHeroModel(GetUnitTypeId(this.unit))
            
            set .charModel = UIPicture.createEx(CHARMODEL_OFFSET_X, .CHARMODEL_OFFSET_Y, 5, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charModel.animIndex = 140
            call SetUnitColor(.charModel.picture, this.user.color)

            call AddSpecialEffectTarget(HeroModelData(i).path, .charModel.picture, "origin")

            set .title[this.user.id] = UIText.createEx(this.user.toPlayer(), X/1.4, 0.1, 1)

            set thistype(0).next.prev = this
            set this.next = thistype(0).next
            set thistype(0).next = this

            set this.prev = 0

            return this
        endmethod

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
        endmethod
        
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
        endmethod
        
        method destroy takes nothing returns nothing
            set this.next.prev = this.prev
            set this.prev.next = this.next
            
            call this.charModel.destroy()
            
            call this.deallocate()
        endmethod

        private static method onDisplay takes nothing returns nothing
            local User user = User(User.LocalId)
            local thistype equipment = Equipment[Equipment.PlayerCurrentUnit[user.id]]
            local real x
            local real y 
            local real z
            
            if (equipment == 0 or not equipment.displayed or Inventory.PlayerCurrent[equipment.user.id] > 0 or User.Local != user.handle) then
                return
            endif
            
            set x = GetUnitX(equipment.unit)
            set y = GetUnitY(equipment.unit)
            set z = GetTerrainZ(x, y) + GetUnitDefaultFlyHeight(equipment.unit)
            
            call equipment.camera.setPosition(x, y, z)
            
            if equipment.camera.applyCameraForPlayer(user.handle, false) then
                call Interface.updateAll(true, true, true)
            endif
        endmethod
        
        method show takes boolean flag, Camera cam returns nothing
            local integer i = 0
            local thistype equip = 0
            local integer len
            local real timeout
            
            set this.displayed = flag
            set this.camera = cam
            
            if (flag) then
                set .DisplayCount = .DisplayCount + 1

                if (DisplayCount >= 1) then
                    call PauseTimer(.UpdateTimer)
                    
                    call TimerStart(.UpdateTimer, Inventory.UI_REFRESH_RATE, true, function thistype.onDisplay)
                endif
                
                if (.PlayerCurrentUnit[this.user.id] != null) then
                    set equip = Equipment[.PlayerCurrentUnit[this.user.id]]
                endif
                
                if (.PlayerCurrentUnit[this.user.id] != null and .PlayerCurrentUnit[this.user.id] != this.unit and equip != this) then
                    call equip.show(false, this.camera)
                endif
                
                set .PlayerCurrentUnit[this.user.id] = this.unit
                
                if (Inventory.PlayerCurrent[this.user.id] > 0 and Inventory.PlayerCurrent[this.user.id].owner != this.unit) then
                    call Inventory.PlayerCurrent[this.user.id].show(false, this.camera)
                endif

            else
                set .DisplayCount = .DisplayCount - 1
                set .PlayerCurrentUnit[this.user.id] = null
                
                if (DisplayCount == 0) then
                    call PauseTimer(.UpdateTimer)
                else
                    call PauseTimer(.UpdateTimer)
                    call TimerStart(.UpdateTimer, Inventory.UI_REFRESH_RATE, true, function thistype.onDisplay)
                endif
                if (User.Local == this.player) then
                    call ResetToGameCamera(0)
                endif
            endif
            
            call this.charModel.showPlayer(this.user.toPlayer(), flag, this.camera)
            //call this.selector[this.user.id].show(flag, cam)
            
            call SetUnitColor(.charModel.picture, this.user.color)

            // todo: make one line / recode
            set len = StringLength(this.user.name)
            
            call .title[this.user.id].setPosition(X + 0.10, HERO_NAME_Y)

            call SetTextTagText(.title[this.user.id].text, HERO_WINDOW_NAME(this.unit), 8 * 0.0023)
            
            call this.title[this.user.id].show(flag, this.camera)
            
            set i = 0 
            
            loop
                exitwhen i == thistype.MAX_SLOTS
                
                if (.getButton(i) != 0) then
                    call .getButton(i).showPlayer(this.user.handle, flag, this.camera)
                endif
                
                if (this.pictures[(this.user.id * .MAX_SLOTS) + i] != 0) then
                    call .pictures[(this.user.id * .MAX_SLOTS) + i].showPlayer(this.user.handle, flag, this.camera)
                endif
                
                if (this.item[i] > 0) then
                    call slotButton[(this.user.id * .MAX_SLOTS) + i].showPlayer(this.user.handle, flag, this.camera)
                endif
                
                set i = i + 1
            endloop
        endmethod
        
        private static method onInit takes nothing returns nothing
            set thistype.Hashtable = InitHashtable()
            set thistype.UpdateTimer = CreateTimer()
            set thistype.Initialized = true
        endmethod
        
    endstruct
    
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
    endfunction

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
    endfunction
    
    private function LClickItemSlot takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local Equipment equip = Equipment[Equipment.PlayerCurrentUnit[GetPlayerId(p)]]
        local Inventory inv = Inventory.PlayerCurrent[equip.user.id]
        local integer slot =  but.customValue
        local integer last = InvPlayerLastSlot[inv.pid] - 1
        local integer itemId = 0
        local UIButton lastButton = InvPlayerLastButton[equip.user.id]
        local InvItem itm
        
        if (User.Local == p) then
            call SelectUnit(but.picture, false)
            call SelectUnit(equip.unit, true)
        endif
        
        if (p != equip.user.handle) then
            return false
        endif
        
        if (InvButtonDisabled[but]) then
            return false
        endif

        call inv.showLines(inv.pid, false, inv.camera)
        
        set PlayerLastSlot[equip.user.id] = slot + 1
        
        // equip item
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
        
        set InvPlayerLastButton[equip.user.id] = but
        set InvPlayerLastSlot[equip.user.id] = 0
        
        if (but != lastButton) then
            call SetUnitVertexColor(lastButton.picture, 255, 255, 255, 255)
            call SetUnitVertexColor(but.picture, 175, 175, 175, 255)
        endif
        
        set itemId = equip.item[slot].id
        
        call Inventory.selector[inv.pid].show(false, inv.camera)
        call Equipment.selector[inv.pid].setPosition(but.centerx - 0.007, but.centery + 0.0272)
        call Equipment.selector[inv.pid].showPlayer(Player(inv.pid), true, inv.camera)
        
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

        return false
    endfunction
    
    private function Init takes nothing returns nothing
        set FuncLClickSlot = Filter(function LClickItemSlot)
        set FuncRClickSlot = Filter(function RClickItemSlot)
        call Inventory.addLeftClickHook(function OnInventoryItemClick)
        call Inventory.addRightClickHook(function OnInventoryItemRightClick)
    endfunction

endlibrary
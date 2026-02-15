library MenuUplates initializer Init requires UserInterface, InventoryItem, PlayerUtils, TimerUtils
    
    struct MUplates
        //
        // configuration
        //
        
        // location of inventory
        static real X = 0.61
        static real Y = -0.3
        
        // size of the background wwindow
        static real SCALE = 0.228
        
        // location of the tooltip information
        static real TOOLTIP_X = -0.7
        static real TOOLTIP_Y = 0.0
        
        // max # of pages the inventory can have 
        static integer MAX_PAGES = 5
        
        // how many slots are on each row/column
        static constant integer BUTTON_ROWS = 6
        static constant integer BUTTON_COLS = 5
        
        // how fast the UI updates
        static constant real UI_REFRESH_RATE = 0.01
        
        // show errors
        static constant boolean SHOW_ERRORS = true

        // icon size
        static constant real SLOT_WIDTH  = 0.065
        static constant real SLOT_HEIGHT = 0.065 * SCREEN_ASPECT_RATIO
        static constant real SLOT_SPACING = 1.00 // 0%
        
        // icon offsets (from X,Y)
        static constant real SLOT_OFFSET_X  = -0.0485
        static constant real SLOT_OFFSET_Y  = 0.072
        
        // raw id's
        static constant integer ICON_EMPTY          = 'dbnk'
        static constant integer ICON_TRANSPARENT    = 'B00S'
        static constant integer ICON_PAGEUP         = 'B00U'
        static constant integer ICON_PAGEDOWN       = 'B00T'
        static constant integer ICON_SELL           = 'B011'
        static constant integer ICON_DROP           = 'B00N'
        
        static constant integer RACE_BORDERS_START = 'D201'
        
        static constant integer BACKGROUND = 'bwn2'
        
        //
        // don't edit below here unless you know what you're doing
        //
        
        static constant integer MAX_SLOTS = BUTTON_ROWS * BUTTON_COLS
        static constant integer MAX_ITEMS = MAX_SLOTS * MAX_PAGES
        
        readonly static hashtable Hashtable = InitHashtable()
        readonly static trigger ExecL = CreateTrigger()
        readonly static trigger ExecR = CreateTrigger()
        readonly static integer DisplayCount = 0
        readonly static timer UpdateTimer = CreateTimer()
        readonly static thistype array PlayerCurrent
        readonly static UIButton array buttons
        
        readonly integer itemCount
        readonly thistype next
        readonly thistype prev
        readonly integer pid
        readonly User user
        readonly unit owner
        
        static UIPicture array background
        static UIText array pageNum
        static UIButton array btnPageUp    
        static UIButton array btnPageDown
        static UIButton array btnSell
        static UIButton array btnDrop
        static UIPicture array selector
        
        Camera camera
        Table countTable
        integer currentPage
        
        readonly boolean displayed
        readonly integer freeSlot
        
        public static trigger onSell
        public static trigger onDrop
        
        public static key KEY_ITEMS
        public static key KEY_ITEM_ID
        public static key KeyUnit
        public static constant integer KEY_UNIT = INVENTORY_KEY_START + KeyUnit
        public static key KeyItemCount
        public static constant integer KEY_ITEM_COUNT = INVENTORY_KEY_START + KeyItemCount
    
        static method localInt takes integer pid, integer value, integer other returns integer
            if (User.Local != User(pid).handle) then
                set value = other
            endif
            return value
        endmethod
        
        static method err takes player p, string s returns nothing
            static if (Inventory.SHOW_ERRORS) then
                static if (LIBRARY_SimError) then
                    call SimError(p, s)
                else
                    call DisplayTimedTextToPlayer(p, 0, 0, 15, "Error: " + s)
                endif
            endif
        endmethod
        
        static method operator [] takes unit u returns thistype
            return thistype(LoadInteger(.Hashtable, KEY_UNIT, GetHandleId(u)))
        endmethod
        
        static method operator []= takes unit u, thistype value returns nothing
            call SaveInteger(.Hashtable, KEY_UNIT, GetHandleId(u), value)
        endmethod
 
        method getButton takes integer index returns UIButton
            return this.buttons[(this.pid * MAX_SLOTS) + index]
        endmethod
        
        method setButton takes integer index, UIButton value returns nothing
            set this.buttons[(this.pid * MAX_SLOTS) + index] = value
        endmethod
        
        method getItem takes integer index returns InvItem
            return LoadInteger(.Hashtable, this, (MAX_ITEMS * .KEY_ITEMS) + index)
        endmethod
        
        method itemsOfType takes integer id returns integer
            return this.countTable[id]
        endmethod
        
        static method addLeftClickHook takes code func returns nothing
            call TriggerAddAction(ExecL, func)
        endmethod
        
        static method addRightClickHook takes code func returns nothing
            call TriggerAddAction(ExecR, func)
        endmethod
        
        method getItemId takes integer index returns integer
            return LoadInteger(.Hashtable, this, (MAX_ITEMS * .KEY_ITEM_ID) + index)
        endmethod
        
        method setItem takes integer index, InvItem itm returns nothing
            local UIButton btn
            local integer slot = index
            local integer id = itm.id
            local integer icon = GetItemIcon(id)
            local InvItem oldItem
            
            if (this.currentPage > 0) then
                set slot = index - (.MAX_SLOTS*this.currentPage)
            endif
            
            set btn = this.getButton(slot)

            set oldItem = this.getItem(index)
            
            call SaveInteger(.Hashtable, this, (MAX_ITEMS * .KEY_ITEMS) + index, itm)
            
            if (itm.tempCustomId > 0) then
                call SaveInteger(.Hashtable, this, (MAX_ITEMS * .KEY_ITEM_ID) + index, itm.tempCustomId)
            endif
            
            set itm.tempCustomId = 0
            
            if (id == 0 and HaveSavedInteger(.Hashtable, this, (MAX_ITEMS * .KEY_ITEMS) + index)) then
                set id = oldItem.id
                
                set this.itemCount = this.itemCount - 1
                set this.countTable[id] = this.countTable[id] - 1
                
                call RemoveSavedInteger(.Hashtable, this, (MAX_ITEMS * .KEY_ITEMS) + index)
                
                // remove ability
                if (oldItem.ability > 0 and itemsOfType(id) <= 0) then
                    call UnitRemoveAbility(this.owner, oldItem.ability)
                endif
            elseif (id > 0) then
                set this.itemCount = this.itemCount + 1
                set this.countTable[id] = this.countTable[id] + 1
                
                // add ability
                if (itm.ability > 0 and itemsOfType(id) == 1) then
                    call UnitAddAbility(this.owner, itm.ability)
                endif
            endif
            
            call btn.setTexture(.localInt(this.pid, icon, ICON_TRANSPARENT))
            call btn.showPlayer(this.user.handle, this.displayed, this.camera)
        endmethod
        
        method findFreeSlot takes integer page returns integer //O(n)
            local integer i = 0
            loop
                exitwhen i == MAX_SLOTS
                if (this.getItem((MAX_SLOTS*page)+i) == 0) then
                    return i
                endif
                set i = i + 1
            endloop
            return -1
        endmethod

        method createButtons takes nothing returns nothing
            local integer row = 0
            local integer col = 0
            local UIButton btn = 0
            local integer i = 0

            if (btnPageUp[this.pid] == 0) then
                set btnPageUp[this.pid] = UIButton.create(X - 0.15, (Y + SLOT_OFFSET_Y) - (col * (SLOT_HEIGHT*SLOT_SPACING)), .SLOT_WIDTH, .SLOT_HEIGHT, 0.5, thistype.localInt(this.pid, ICON_PAGEUP, ICON_TRANSPARENT))
                set btnPageDown[this.pid] = UIButton.create(X - 0.15, (Y + SLOT_OFFSET_Y) - ((.BUTTON_COLS-1) * (SLOT_HEIGHT*SLOT_SPACING)), .SLOT_WIDTH, .SLOT_HEIGHT, 0.5, thistype.localInt(this.pid, ICON_PAGEDOWN, ICON_TRANSPARENT))
                set btnSell[this.pid] = UIButton.create(X - 0.15, (Y + SLOT_OFFSET_Y) - .300, .SLOT_WIDTH, .SLOT_HEIGHT, 0.5, thistype.localInt(this.pid, ICON_SELL, ICON_TRANSPARENT))
                set btnDrop[this.pid] = UIButton.create(X - 0.15, (Y + SLOT_OFFSET_Y) - .150, .SLOT_WIDTH, .SLOT_HEIGHT, 0.5, thistype.localInt(this.pid, ICON_DROP, ICON_TRANSPARENT))
                
                set btnPageUp[this.pid].onLeftClick = InvFuncLClickSlot
                set btnPageDown[this.pid].onLeftClick = InvFuncLClickSlot
                set btnSell[this.pid].onLeftClick = InvFuncLClickSlot
                set btnDrop[this.pid].onLeftClick = InvFuncLClickSlot
                
                set btnPageUp[this.pid].selectUnit = this.owner
                set btnPageDown[this.pid].selectUnit = this.owner
                set btnSell[this.pid].selectUnit = this.owner
                set btnDrop[this.pid].selectUnit = this.owner
                
                set selector[this.pid] = UIPicture.createEx(X - 0.15, (Y + SLOT_OFFSET_Y) - .250, 0, .55, 'e000', 1, 1, 0)
                set selector[this.pid].animIndex = 56
                call selector[this.user.id].show(false, this.camera)
                
                call AddSpecialEffectTarget("UI\\TRSHerolevel.mdx", selector[this.pid].picture, "origin")
            endif
            
            loop
                exitwhen col == BUTTON_COLS
                
                set row = 0
                
                loop
                    exitwhen row == BUTTON_ROWS
                    
                    if (this.getButton(i) == 0) then
                    
                        set btn = UIButton.create( (X + SLOT_OFFSET_X) + (row * (SLOT_WIDTH*SLOT_SPACING)), (Y + SLOT_OFFSET_Y) - (col * (SLOT_HEIGHT*SLOT_SPACING)), .SLOT_WIDTH, .SLOT_HEIGHT, 0.5, GetItemIcon(this.getItem(i).id))
                        
                        set btn.customValue = i
                        
                        set btn.selectUnit = this.owner
                        
                        set btn.onLeftClick = InvFuncLClickSlot
                        set btn.onRightClick = InvFuncRClickSlot
                        
                        call this.setButton(i, btn)

                        //call SetUnitVertexColor(.background[this.pid].picture, 255, 255, 255, thistype.localInt(this.pid, 255, 0))
                    endif
                    set i = i + 1
                    
                    set row = row + 1
                endloop
                
                set col = col + 1
            endloop
        endmethod
        
        implement InvPlugins
        
        static method create takes unit owner returns thistype
            local thistype this = thistype.allocate()
            local boolean showLocally
            local integer raceId
            local integer i = 0
            
            set this.itemCount = 0
            set this.owner = owner
            set this.freeSlot = 0
            set this.pid = GetPlayerId(GetOwningPlayer(this.owner))
            set this.user = User(this.pid)
            set this.countTable=Table.create()
            
            set raceId = GetHandleId(GetPlayerRace(User(this.pid).handle))-1
            
            set showLocally = (User.Local == User(this.pid).handle)
            
            call this.createButtons()
            
            static if (thistype.createTooltip.exists) then
                call thistype.createTooltip(this, raceId)
            endif
            
            if (this.pageNum[this.pid] == 0) then
                set this.pageNum[this.pid] = UIText.createEx(this.user.toPlayer(), X + 0.300, Y + .10, 1)
            endif
            
            set Inventory[this.owner] = this
            
            if (.background[this.pid] == 0) then
                set .background[this.pid] = UIPicture.createEx(X, Y, 2, SCALE, BACKGROUND, 70., 60, .localInt(this.pid, RACE_BORDERS_START + raceId, ICON_TRANSPARENT))
            endif

            set thistype(0).next.prev = this
            set this.next = thistype(0).next
            set thistype(0).next = this

            set this.prev = 0

            return this
        endmethod
        
        method addItem takes InvItem itm returns boolean
            local integer slot
            
            if (itm <= 0 or itm.id <= 0) then
                return false
            endif
            
            set slot = findFreeSlot(this.currentPage)
            
            if (slot == -1) then
                call err(User(this.pid).handle, "There are no free slots on this inventory page.")
                return false
            endif
            
            if (itm.icon == ICON_EMPTY) then
                return false
            endif
            
            call this.setItem((.MAX_SLOTS * this.currentPage) + slot, itm)
            
            return true
        endmethod
        
        method destroy takes nothing returns nothing
            set this.next.prev = this.prev
            set this.prev.next = this.next

            call this.deallocate()
        endmethod
        
        private static method onDisplay takes nothing returns nothing
            local thistype inv
            local real x
            local real y 
            local real z
            
            local User user = User(User.LocalId)
            
            set inv = Inventory.PlayerCurrent[user.id]
            
            if (inv == 0 or not inv.displayed) then
                return
            endif
            
            set x = GetUnitX(inv.owner)
            set y = GetUnitY(inv.owner)
            set z = GetTerrainZ(x, y) + GetUnitDefaultFlyHeight(inv.owner)
            
            call inv.camera.setPosition(x, y, z)
            
            if inv.camera.applyCameraForPlayer(user.handle, false) then
                call Interface.updateAll(true, true, true)
            endif

        endmethod
        
        method show takes boolean flag, Camera cam returns nothing
            local integer i
            local thistype equip
            local real timeout
            
            if (this.currentPage >= .MAX_PAGES) then
                set this.currentPage = 0
            elseif (this.currentPage < 0) then
                set this.currentPage = .MAX_PAGES - 1
            endif
            
            if (flag) then
                if (not this.displayed) then
                    set .DisplayCount = .DisplayCount + 1
                endif
                
                if (PlayerCurrent[this.pid] > 0 and PlayerCurrent[this.pid] != this) then
                    call PlayerCurrent[this.pid].show(false, cam)
                endif
                
                set PlayerCurrent[this.pid] = this

                call PauseTimer(.UpdateTimer)
                call TimerStart(.UpdateTimer, UI_REFRESH_RATE, true, function thistype.onDisplay)
            else
                set .DisplayCount = .DisplayCount - 1
                
                if (DisplayCount == 0) then
                    call PauseTimer(.UpdateTimer)
                else
                    call TimerStart(.UpdateTimer, UI_REFRESH_RATE, true, function thistype.onDisplay)
                endif
                
                if (User.LocalId == this.pid) then
                    call ResetToGameCamera(0)
                endif
                
                set PlayerCurrent[this.pid] = 0
            endif
            
            set this.displayed = flag
            set this.camera = cam
            
            call this.btnPageUp[this.pid].show(flag, cam)
            call this.btnSell[this.pid].show(flag, cam)
            call this.btnDrop[this.pid].show(flag, cam)
            //call this.selector[this.pid].show(flag, cam)
            call this.btnPageDown[this.pid].show(flag, cam)
            call this.background[this.pid].show(flag, cam)

            static if thistype.showTooltip.exists then
                if (not flag) then
                    call thistype.showTooltip(this, flag)
                endif
            endif
            
            call SetTextTagText(this.pageNum[this.pid].text, I2S(this.currentPage + 1) + "/" + I2S(.MAX_PAGES), 10 * 0.0023)
            
            call this.pageNum[this.pid].show(flag, cam)
            
            set i = 0
            
            loop
                exitwhen i == .MAX_SLOTS
                
                call this.getButton(i).setTexture(thistype.localInt(this.pid, GetItemIcon(this.getItem((.MAX_SLOTS*this.currentPage) + i).id), ICON_TRANSPARENT))

                call this.getButton(i).showPlayer(this.user.handle, flag, this.camera)
                
                call this.getButton(i).showPlayer(this.user.handle, flag, this.camera)
                
                
                set i = i + 1
            endloop

        endmethod
        
        /*private static method onInit takes nothing returns nothing
        endmethod*/
    endstruct
    
    public function GracePeriod takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local UIButton but = UIButton(GetTimerData(t))
        
        set InvButtonDisabled[but] = false
        
        call ReleaseTimer(t)
    endfunction
    
    function DisableButtonIfUsingTimer takes UIButton but, real time returns nothing
        static if (Inventory.USE_LEFT_CLICK_TIMER) then
            call TimerStart(NewTimerEx(but), time, false, function GracePeriod)
            set InvButtonDisabled[but] = true
        endif
    endfunction
    
    private function LClickItemSlot takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pid = GetPlayerId(p)
        local Inventory inv =  Inventory.PlayerCurrent[pid]
        local integer slot =  but.customValue
        local integer itemId = 0
        local integer icon = 0
        local integer last = InvPlayerLastSlot[inv.pid] - 1
        local integer lastItemId
        local InvItem lastItem
        local UIButton lastButton = InvPlayerLastButton[inv.pid]

        if (User.Local == p) then
            call SelectUnit(but.picture, false)
            call SelectUnit(inv.owner, true)
        endif
        
        if (InvButtonDisabled[but]) then
            return false
        endif
        
        // sell item
        if (but == Inventory.btnSell[inv.pid]) then
            set last = InvPlayerLastSlot[inv.pid] - 1
            
            if (last < 0) then
                return false 
            endif
            
           if (p != User(inv.pid).handle) then
                return false 
            endif
            
            // run onSell event
            set InvEventPlayer = User(inv.pid).handle
            set InvEventItem = inv.getItem((Inventory.MAX_SLOTS*inv.currentPage)+last)
            set InvEventSlot = (Inventory.MAX_SLOTS*inv.currentPage)+last
            
            if (Inventory.onSell != null and TriggerEvaluate(Inventory.onSell)) then
                call TriggerExecute(Inventory.onSell)
            endif
            
            call DisableButtonIfUsingTimer(but, 2)
            
            return false
        elseif (but == Inventory.btnDrop[inv.pid]) then
            set last = InvPlayerLastSlot[inv.pid] - 1
            
            if (last < 0) then
                return false 
            endif
            
           if (p != User(inv.pid).handle) then
                return false 
            endif
            
            // run onSell event
            set InvEventPlayer = User(inv.pid).handle
            set InvEventItem = inv.getItem((Inventory.MAX_SLOTS*inv.currentPage)+last)
            set InvEventSlot = (Inventory.MAX_SLOTS*inv.currentPage)+last
            
            if (Inventory.onDrop != null and TriggerEvaluate(Inventory.onDrop)) then
                call TriggerExecute(Inventory.onDrop)
                return false
            endif
            
            call DisableButtonIfUsingTimer(but, 2)
        elseif (but == Inventory.btnPageDown[inv.pid]) then
           if (p != User(inv.pid).handle) then
                return false
            endif
        
            set inv.currentPage = inv.currentPage + 1
            call inv.show(true, inv.camera)
            call DisableButtonIfUsingTimer(but, .6)
            return false
        elseif (but == Inventory.btnPageUp[inv.pid]) then
           if (p != User(inv.pid).handle) then
                return false
            endif
            
            set inv.currentPage = inv.currentPage - 1
            call inv.show(true, inv.camera)
            call DisableButtonIfUsingTimer(but, .6)
            return false
        else
            call Inventory.selector[inv.pid].show(true, inv.camera)
            call Inventory.selector[pid].setPosition(but.centerx - 0.004, but.centery + 0.0262)
            call Inventory.selector[pid].showPlayer(Player(pid), true, inv.camera)
        endif

        if (p != User(inv.pid).handle) then
            return false
        endif
        
        if (last + 1 != slot) then
            call inv.showLines(inv.pid, false, inv.camera)
        endif
        
        call TriggerExecute(Inventory.ExecL)
        
        // get item in slot
        set itemId = inv.getItem((Inventory.MAX_SLOTS*inv.currentPage)+slot).id
        
         // check for switch
        if (last+1 != 0) then

            call SetUnitVertexColor(lastButton.picture, 255, 255, 255, 255)
            call SetUnitVertexColor(but.picture, 255, 255, 255, 255)
            
            set InvPlayerLastSlot[inv.pid] = 0
            set InvPlayerLastButton[inv.pid] = but
                
            if (itemId == 0) then
                set last = (Inventory.MAX_SLOTS * inv.currentPage) + last
                
                set lastItem = inv.getItem(last)
            
                set lastItemId = lastItem.id
                
                set lastItem.tempCustomId = inv.getItemId(last)
            
                call inv.setItem((Inventory.MAX_SLOTS*inv.currentPage)+slot, lastItem)
                call inv.setItem(last, 0)
                
                call DisableButtonIfUsingTimer(but, 2)
            elseif (inv.getItem((Inventory.MAX_SLOTS * inv.currentPage) + last).isSocket) then
                
                set last = (Inventory.MAX_SLOTS * inv.currentPage) + last
                
                set lastItem = inv.getItem(last)
                set lastItem.tempCustomId = inv.getItemId(last)
                set slot = (Inventory.MAX_SLOTS*inv.currentPage)+slot
                
                if (Equipment.onSocket != null) then
                    if (lastItem.sockets <= lastItem.maxSockets) then
                        set SocketInv = inv
                        set SocketLast = last
                        set SocketSlot = slot
                        
                        if (not inv.getItem(slot).isSocket and Equipment.onSocket != null and TriggerEvaluate(Equipment.onSocket)) then
                            call TriggerExecute(Equipment.onSocket)
                            return false
                        endif
                    endif
                else
                    set inv.getItem(slot).tempCustomId = inv.getItemId(slot)
                    
                    if (inv.getItem(slot).addSocket(lastItem)) then
                        call inv.setItem(last, 0)
                    endif
                endif
    
            endif
        else//if (itemId != 0) then
            set InvPlayerLastSlot[inv.pid] = 0
            set InvPlayerLastButton[inv.pid] = but
        endif
        
        if (itemId == 0 or InvPlayerLastSlot[inv.pid] != 0) then
        else
            set InvPlayerLastSlot[inv.pid] = slot + 1
        endif
        
        if (but != lastButton) then
            call SetUnitVertexColor(lastButton.picture, 255, 255, 255, 255)
            call SetUnitVertexColor(but.picture, 175, 175, 175, 255)
        endif
        
        if (itemId > 0) then
            
            call inv.setTooltipTitle(GetObjectName(itemId))
            
            static if (InvItem.buildDescription.exists) then
                set GetInvItem(itemId).tempCustomId = inv.getItemId((Inventory.MAX_SLOTS*inv.currentPage)+slot)

                call GetInvItem(itemId).buildDescription(inv.owner)
            else
                call inv.setTooltipInfo(GetItemDescription(itemId))
            endif
            
            call inv.setTooltipCost("|cffffcc00" + I2S(GetInvItem(itemId).cost) + "|r")
            
            call inv.setTooltipIcon(inv.localInt(inv.pid, GetItemIcon(itemId), Inventory.ICON_TRANSPARENT))
        endif
        
        set Inventory.TOOLTIP_X = but.minx - 0.4
        set Inventory.TOOLTIP_Y = but.maxy + 0.4
        
        call inv.showTooltip(inv, itemId > 0)
        
        return false
    endfunction

    private function RClickItemSlot takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pid = GetPlayerId(p)
        local Inventory inv =  Inventory.PlayerCurrent[pid]
        
        local integer slot =  but.customValue
        local integer itemId
 
        if (p != User(inv.pid).handle) then
            return false
        endif
        
        call TriggerExecute(Inventory.ExecR)
        
        set slot = (Inventory.MAX_SLOTS * inv.currentPage) + slot

        set itemId = inv.getItem(slot).id

        if (itemId == 0) then
            return false
        endif
        
        call inv.showTooltip(inv, false)
        
        /*call SetItemUserData(CreateItem(itemId, GetUnitX(inv.owner), GetUnitY(inv.owner)), inv.getItemId(slot))
        
        call inv.setItem(slot, 0)*/
        
        return false
    endfunction
    
    private function Init takes nothing returns nothing
        set InvFuncLClickSlot = Filter(function LClickItemSlot)
        set InvFuncRClickSlot = Filter(function RClickItemSlot)
    endfunction
    
endlibrary
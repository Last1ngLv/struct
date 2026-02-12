library EquipmentItem initializer Init requires BonusMod, InventoryCore
    
    globals
        public string array BonusString
    endglobals

    public function Init takes nothing returns nothing
        set BonusString[BONUS_DAMAGE] = "Damage"
        set BonusString[BONUS_ARMOR] = "Armor"
        set BonusString[BONUS_STRENGTH] = "Strength"
        set BonusString[BONUS_AGILITY] = "Agility"
        set BonusString[BONUS_INTELLIGENCE] = "Intelligence"
        set BonusString[BONUS_ATTACK_SPEED] = "Attack Speed"
        set BonusString[BONUS_SIGHT_RANGE] = "Visibility"
        set BonusString[BONUS_LIFE_REGEN] = "Life Regen"
        set BonusString[BONUS_MANA_REGEN_PERCENT] = "% Mana Regen"
        set BonusString[BONUS_MOVEMENT_SPEED] = "Movement Speed"
        set BonusString[BONUS_LIFE]  = "Life"
        set BonusString[BONUS_MANA]  = "Mana"
    endfunction
    
    module InvItemEquipment
        //
        // configuration
        //
        
        public static constant integer MAX_BONUSES = 1000 // can be any number
        
        //
        // end config
        //
        
        static trigger onEquip = null
        static trigger onUnequip = null
        public static trigger equipEval = CreateTrigger()
        public static unit eventUnit = null
         
        integer slot
        integer slotAlt
        integer equipAbility
        integer reqLevel
        integer reqUnitType
        integer reqAbility
        string class
        boolexpr equipCondition
        string equipConditionStr
        string equipConditionStrPrefix
        
        static if (LIBRARY_BonusMod) then
            integer bonuses
            
            public static key KeyBonusType
            public static key KeyBonusAmount
            public static key KeyBonusMin
            public static key KeyBonusMax
            public static key KeyBonusRand
            
            public static integer KEY_BONUS_TYPE    = INVENTORY_KEY_START + KeyBonusType
            public static integer KEY_BONUS_AMOUNT  = INVENTORY_KEY_START + KeyBonusAmount
            public static integer KEY_BONUS_MIN     = INVENTORY_KEY_START + KeyBonusMin
            public static integer KEY_BONUS_MAX     = INVENTORY_KEY_START + KeyBonusMax
            public static integer KEY_BONUS_RND     = INVENTORY_KEY_START + KeyBonusRand
            
            method addBonusRange takes Bonus bonusType, integer base, integer min, integer max returns nothing
                call SaveInteger(Inventory.Hashtable, KEY_BONUS_TYPE,(this*.MAX_BONUSES)+this.bonuses, bonusType)
                call SaveInteger(Inventory.Hashtable, KEY_BONUS_AMOUNT,(this*.MAX_BONUSES)+this.bonuses, base)
                call SaveInteger(Inventory.Hashtable, KEY_BONUS_MIN,(this*.MAX_BONUSES)+this.bonuses, min)
                call SaveInteger(Inventory.Hashtable, KEY_BONUS_MAX,(this*.MAX_BONUSES)+this.bonuses, max)
                set this.bonuses = this.bonuses + 1
            endmethod
            
            method addBonus takes Bonus bonusType, integer amount returns nothing
                call SaveInteger(Inventory.Hashtable, KEY_BONUS_TYPE,(this*.MAX_BONUSES)+this.bonuses, bonusType)
                call SaveInteger(Inventory.Hashtable, KEY_BONUS_AMOUNT,(this*.MAX_BONUSES)+this.bonuses, amount)
                set this.bonuses = this.bonuses + 1
            endmethod
            
            method getBonus takes integer index returns Bonus
                return LoadInteger(Inventory.Hashtable, KEY_BONUS_TYPE, (this*.MAX_BONUSES)+index)
            endmethod
            
            method getBonusAmount takes integer index returns integer
                return LoadInteger(Inventory.Hashtable, KEY_BONUS_AMOUNT, (this*.MAX_BONUSES)+index)
            endmethod
            
            method getBonusMin takes integer index returns integer
                return LoadInteger(Inventory.Hashtable, KEY_BONUS_MIN, (this*.MAX_BONUSES)+index)
            endmethod
            
            method getBonusMax takes integer index returns integer
                return LoadInteger(Inventory.Hashtable, KEY_BONUS_MAX, (this*.MAX_BONUSES)+index)
            endmethod
            
            static method Bonus2S takes Bonus b returns string
                return BonusString[b]
            endmethod
            
            method getBonusTotal takes integer index returns integer
                local integer total = getBonusAmount(index)
                set bj_cineModeSavedSeed = GetRandomInt(0, 1000000)
                call SetRandomSeed(InvCustomItem(this.tempCustomId).seed())
                set total = total + (GetRandomInt(this.getBonusMin(index), this.getBonusMax(index)))
                call SetRandomSeed(bj_cineModeSavedSeed)
                return total
            endmethod
            
            method addBonusesMultiplier takes unit u, integer m returns nothing
                local integer i = 0
                local integer n = 0
                local integer total
                local InvItem itm
                
                loop
                    exitwhen i >= this.bonuses
                    
                    call BonusModStruct.addBonus(u, this.getBonus(i), this.getBonusTotal(i)*m)
                    
                    set i = i + 1
                endloop

                set i = 0
                
                loop
                    exitwhen i >= this.sockets
                    
                    set itm = this.getSocket(i)
                    set itm.tempCustomId = this.socketId(i)
                    
                    set n = 0
                    
                    loop
                        exitwhen n == itm.bonuses
                        
                        call BonusModStruct.addBonus(u, itm.getBonus(n), itm.getBonusTotal(n)*m)
                        
                        set n = n + 1
                    endloop
                    
                    set i = i + 1
                endloop
            endmethod
            
            method applyBonuses takes unit u returns nothing
                call addBonusesMultiplier(u, 1)
            endmethod
            
            method removeBonuses takes unit u returns nothing
                call addBonusesMultiplier(u, -1)
            endmethod
        endif
        
        static method GearSlotName takes integer slot returns string
            if (slot == 1) then
                return "Head"
            elseif (slot == 2) then
                return "Shoulder"
            elseif (slot == 8) then
                return "Earring"
            elseif (slot == 3) then
                return "Chest"
            elseif (slot == 4) then
                return "Belt"
            elseif (slot == 5) then
                return "Pants"
            elseif (slot == 6 or slot == 12) then
                return "Ring"
            elseif (slot == 7) then
                return "Amulet"
            elseif (slot == 9) then
                return "Gloves"
            elseif (slot == 10) then
                return "Bracers"
            elseif (slot == 11) then
                return "Boots"
            elseif (slot == 13) then
                return "Weapon"
            elseif (slot == 14) then
                return "Offhand"
            endif
            
            return ""
        endmethod

        method buildDescription takes unit forUnit returns string
            local integer i = 0
            local integer n = 0
            local string out = ""
            local string bonusName
            local integer lines = 0
            local integer pid = GetPlayerId(GetOwningPlayer(forUnit))
            local integer total
            local InvItem itm
            
            call EquipmentItem_Init.execute()
            
            call Inventory.clearLines(pid)
            
            // slot type
            set out = GearSlotName(this.slot)
            
            if (out != "") then
                set out = "|cffffcc00Slot:|r " + out

                call Inventory.setTooltipSlot(pid, lines, out)
                call Inventory.ItemInfoTags[pid][Inventory.TOOLTIP_LINES_MAX].show(true, Inventory.PlayerCurrent[pid].camera)
            endif
            
            // item description
            set lines = this.buildDescriptionLines(pid, 0)
            
            if (lines != 0) then
                set lines = lines + 1
            endif
            
            // item ability
            if (this.ability > 0) then
                set out = "|cfffedaac" + GetObjectName(this.ability) + "|r (Does not stack)\n"
                
                call Inventory.setTooltipLine(pid, lines, out)
                call Inventory.ItemInfoTags[pid][lines].show(true, Inventory.PlayerCurrent[pid].camera)
                
                set lines = lines + 1
            endif
            
            // equip ability
            if (this.equipAbility > 0) then
                set out = "|cfffedaac" + GetObjectName(this.equipAbility) + "|r\n"
                
                call Inventory.setTooltipLine(pid, lines, out)
                call Inventory.ItemInfoTags[pid][lines].show(true, Inventory.PlayerCurrent[pid].camera)
                
                set lines = lines + 1
            endif
            
            // equip bonuses
            static if (LIBRARY_BonusMod) then
                loop
                    exitwhen i >= this.bonuses
                    
                    set bonusName =  .Bonus2S(this.getBonus(i))
  
                    if (bonusName != null and bonusName != "") then
                        
                        set total = this.getBonusTotal(i)
                        
                        if (total > 0) then
                            set out = "|cfffedaac+" + I2S(total) + " to " + bonusName + "|r"
                            
                            call Inventory.setTooltipLine(pid, lines, out)
                            call Inventory.ItemInfoTags[pid][lines].show(true, Inventory.PlayerCurrent[pid].camera)
                            set lines = lines + 1
                        endif

                    endif
                    
                    set i = i + 1
                endloop
            endif
            
            set Inventory.RightSideStart[pid] = lines
            
            // level requirement
            if (this.reqLevel > 0) then
                if (GetHeroLevel(forUnit) < this.reqLevel and GetUnitLevel(forUnit) < this.reqLevel) then
                    set out = "|cffffcc00Level Req:|r |cffff0000" + I2S(this.reqLevel) + "|r"
                else
                    set out = "|cffffcc00Level Req:|r " + I2S(this.reqLevel)
                endif
                
                call Inventory.setTooltipLine(pid, lines, out)
                call Inventory.ItemInfoTags[pid][lines].show(true, Inventory.PlayerCurrent[pid].camera)
                
                set lines = lines + 1
            endif
            
            // unit type requirement
            if (this.reqUnitType > 0) then
                if (GetUnitTypeId(forUnit) != this.reqUnitType) then
                    set out = "|cffffcc00Usable:|r |cffff0000" + GetObjectName(this.reqUnitType) + "|r"
                else
                    set out = "|cffffcc00Usable:|r |cff2eb82e" + GetObjectName(this.reqUnitType) + "|r"
                endif
                
                call Inventory.setTooltipLine(pid, lines, out)
                call Inventory.ItemInfoTags[pid][lines].show(true, Inventory.PlayerCurrent[pid].camera)
                
                set lines = lines + 1
            endif
            
            // ability requirement
            if (this.reqAbility > 0) then
                if (GetUnitAbilityLevel(forUnit, this.reqAbility) < 0) then
                    set out = "|cffff0000Requires:|r |cffff0000" + GetObjectName(this.reqAbility) + "|r"
                else    
                    set out = "|cffffcc00Requires:|r " + GetObjectName(this.reqAbility)
                endif
                
                call Inventory.setTooltipLine(pid, lines, out)
                call Inventory.ItemInfoTags[pid][lines].show(true, Inventory.PlayerCurrent[pid].camera)
                
                set lines = lines + 1
            endif
            
            // custom
            if (this.equipCondition != null and this.equipConditionStr != null and this.equipConditionStr != "") then
                call TriggerClearConditions(InvItem.equipEval)
                call TriggerAddCondition(InvItem.equipEval, this.equipCondition)
                set InvItem.eventUnit = forUnit
                if (not TriggerEvaluate(InvItem.equipEval)) then
                    set out = "|cffffcc00" + this.equipConditionStrPrefix + ":|r " + this.equipConditionStr
                else
                    set out = "|cffffcc00" + this.equipConditionStrPrefix + ":|r " + this.equipConditionStr
                endif
                
                call Inventory.setTooltipLine(pid, lines, out)
                call Inventory.ItemInfoTags[pid][lines].show(true, Inventory.PlayerCurrent[pid].camera)
                
                set lines = lines + 1
            endif
            
            // sockets
            set i = 0
            
            if (this.maxSockets > 0) then
                if (Inventory.RightSideStart[pid] != lines) then
                    call Inventory.setTooltipLine(pid, lines, "")
                    call Inventory.ItemInfoTags[pid][lines].show(true, Inventory.PlayerCurrent[pid].camera)
                    set lines = lines + 1
                endif
                call Inventory.setTooltipLine(pid, lines, "Sockets: " + I2S(this.sockets) + "/" + I2S(this.maxSockets))
                call Inventory.ItemInfoTags[pid][lines].show(true, Inventory.PlayerCurrent[pid].camera)
                set lines = lines + 1
            endif
            
            loop
                exitwhen i >= this.maxSockets
                
                set itm = this.getSocket(i)
                
                if (itm > 0) then
                
                    set itm.tempCustomId = this.socketId(i)
                    
                    set n = 0
                    
                    loop
                        exitwhen n >= itm.bonuses
                    
                        set bonusName =  .Bonus2S(itm.getBonus(n))
   
                        if (bonusName != null and bonusName != "") then
                            
                            set total = itm.getBonusTotal(n)
                            
                            if (total > 0) then
                                set out = "|cff5566bb+" + I2S(total) + " to " + bonusName + "|r\n"
                                
                                call Inventory.setTooltipLine(pid, lines, out)
                                call Inventory.ItemInfoTags[pid][lines].show(true, Inventory.PlayerCurrent[pid].camera)
                                
                                set lines = lines + 1
                            endif
                        endif
                        
                        set n = n + 1
                    endloop
                endif
                
                set i = i + 1
            endloop

            return out
        endmethod
        
    endmodule
    
    function SetEquipItemStats takes integer slot, integer s2, integer ab, integer lvl, integer utype, integer rab, integer dmg, integer def, integer str, integer agi, integer it, integer as, integer sight, integer lreg, integer mreg, InvItem itm returns InvItem
        set itm.slot = slot
        set itm.slotAlt = s2
        set itm.reqUnitType = utype
        set itm.equipAbility = ab
        set itm.reqLevel = lvl
        set itm.reqUnitType = utype
        set itm.reqAbility = rab
        
        if (dmg != 0) then
            call itm.addBonus(BONUS_DAMAGE, dmg)
        endif
        
        if (def != 0) then
            call itm.addBonus(BONUS_ARMOR, def)
        endif
        
        if (str != 0) then
            call itm.addBonus(BONUS_STRENGTH, str)
        endif
        
        if (agi != 0) then
            call itm.addBonus(BONUS_AGILITY, agi)
        endif
        
        if (it != 0) then
            call itm.addBonus(BONUS_INTELLIGENCE, it)
        endif

        if (as != 0) then
            call itm.addBonus(BONUS_ATTACK_SPEED, as)
        endif
        
        if (sight != 0) then
            call itm.addBonus(BONUS_SIGHT_RANGE, sight)
        endif
        
        if (lreg != 0) then
            call itm.addBonus(BONUS_LIFE_REGEN, lreg)
        endif
        
        if (mreg != 0) then
            call itm.addBonus(BONUS_MANA_REGEN_PERCENT, lreg)
        endif
        
        return itm
    endfunction

    
endlibrary
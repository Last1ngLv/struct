library EquipItemParser requires EquipmentItem
    
    //
    // configuration
    //
    public function ParseTypeToSlot takes InvItem itm, string t returns nothing
        if (t == "weapon") then
            set itm.slot = 13
        elseif(t == "shield") then
            set itm.slot = 14
        elseif(t == "armor") then
            set itm.slot = 3
        elseif(t == "boots") then
            set itm.slot = 11
        elseif(t == "bracers") then
            set itm.slot = 10
        elseif(t == "gloves") then
            set itm.slot = 9
        elseif(t == "belt") then
            set itm.slot = 4
        elseif(t == "helm") then
            set itm.slot = 1
        elseif(t == "pauldron") then
            set itm.slot = 2
            set itm.slotAlt = 9
        elseif(t == "amulet") then
            set itm.slot = 7
        elseif(t == "pants") then
            set itm.slot = 5
        elseif(t == "ring") then
            set itm.slot = 6
            set itm.slotAlt = 12
        elseif(t == "shield") then
            set itm.slot = 14
        elseif(t == "socket" or t == "gem") then
            set itm.isSocket = true
        endif
    endfunction

    public function ParseClass takes InvItem itm, string c returns nothing
        if (c == "1h") then
            set itm.slotAlt = 14
        endif
    endfunction
    
    public function ParseBonusParam takes InvItem itm, string param, string value, string min, string max returns nothing
        if (param == "dmg") then
            call itm.addBonusRange(BONUS_DAMAGE, S2I(value), S2I(min), S2I(max))
        elseif (param == "def") then
            call itm.addBonusRange(BONUS_ARMOR, S2I(value), S2I(min), S2I(max))
        elseif (param == "str") then
            call itm.addBonusRange(BONUS_STRENGTH, S2I(value), S2I(min), S2I(max))
        elseif (param == "agi") then
            call itm.addBonusRange(BONUS_AGILITY, S2I(value), S2I(min), S2I(max))
        elseif (param == "int") then
            call itm.addBonusRange(BONUS_INTELLIGENCE, S2I(value), S2I(min), S2I(max))
        elseif (param == "ias") then
            call itm.addBonusRange(BONUS_ATTACK_SPEED, S2I(value), S2I(min), S2I(max))
        elseif (param == "hp" or param == "life") then
            call itm.addBonusRange(BONUS_LIFE, S2I(value), S2I(min), S2I(max))
        elseif (param == "mp" or param == "mana") then
            call itm.addBonusRange(BONUS_MANA, S2I(value), S2I(min), S2I(max))
        elseif (param == "manareg") then
            call itm.addBonusRange(BONUS_MANA_REGEN, S2I(value), S2I(min), S2I(max))
        elseif (param == "sight") then
            call itm.addBonusRange(BONUS_SIGHT_RANGE, S2I(value), S2I(min), S2I(max))
        elseif (param == "ms" or param == "move") then
            call itm.addBonusRange(BONUS_MOVEMENT_SPEED, S2I(value), S2I(min), S2I(max))
        elseif (param == "lifereg") then
            call itm.addBonusRange(BONUS_LIFE_REGEN, S2I(value), S2I(min), S2I(max))
        endif
    endfunction
    //
    // end
    //
    
    // String2Rawcode:
    public function Char2Id takes string c returns integer
        local integer i = 0
        local string abc = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        local string t

        loop
            set t = SubString(abc,i,i + 1)
            exitwhen t == null or t == c
            set i = i + 1
        endloop
        if i < 10 then
            return i + 48
        elseif i < 36 then
            return i + 65 - 10
        endif
        return i + 97 - 36
    endfunction

    public function String2Id takes string s returns integer
        return ((Char2Id(SubString(s,0,1)) * 256 + Char2Id(SubString(s,1,2))) * 256 + Char2Id(SubString(s,2,3))) * 256 + Char2Id(SubString(s,3,4))
    endfunction

    public function Id2Char takes integer i returns string
        local string abc = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

        if i >= 97 then
            return SubString(abc,i - 97 + 36,i - 96 + 36)
        elseif i >= 65 then
            return SubString(abc,i - 65 + 10,i - 64 + 10)
        endif
        return SubString(abc,i - 48,i - 47)
    endfunction

    public function Id2String takes integer id returns string
        local integer t = id / 256
        local string r = Id2Char(id - 256 * t)
        set id = t / 256
        set r = Id2Char(t - 256 * id) + r
        set t = id / 256
        return Id2Char(t) + Id2Char(id - 256 * t) + r
    endfunction
    // end
    
    public function ParseRawCodeStr takes string value returns integer
        local integer l = StringLength(value)
        
        if (l == 4 or l == 1 or l == 3 or l == 6) then
            
            if (SubString(value, 0, 1) == "'") then
                set value = SubString(value, 1, 9999)
                set l = l - 1
            endif
        
            if (SubString(value, l-1, l) == "'") then
                set value = SubString(value, 0, l-1)
            endif
            
            return String2Id(value)
        endif
        
        return S2I(value)
    endfunction
    
    private function ParseParam takes InvItem itm, string param, string value returns nothing
        if (param == "lvl") then
            set itm.reqLevel = S2I(value)
        elseif (param == "class") then
            call ParseClass(itm, value)
        elseif(param == "icon") then
            set itm.icon = ParseRawCodeStr(value)
        elseif(param == "utype") then
            set itm.reqUnitType = ParseRawCodeStr(value)
        elseif(param == "abil") then
            set itm.reqAbility = ParseRawCodeStr(value)
        elseif(param == "cost") then
            set itm.cost = S2I(value)
        elseif(param == "type") then
            call ParseTypeToSlot(itm, value)
        elseif(param == "maxsock") then
            set itm.maxSockets = S2I(value)
        endif
    endfunction
    
    globals
        public string TypeSlot
    endglobals
    
    function InitEquipItem takes integer itemId, string data returns InvItem
        local InvItem itm = InvItem.create()
        local integer len = StringLength(data)
        local integer i = 0
        local string desc = ""
        local string param = ""
        local string array value
        local integer curVal = 0
        
        local string s = ""
        local integer step = 0

        set itm.id = itemId
        set InvItem.Table[itm.id] = itm

        loop
            exitwhen i >= len
            
            set s = SubString(data, i, i + 1)
            
            if (step > 0 and s == " ") then
                // do nothing
            elseif (step == 0) then
                
                if (s == "^") then
                    set step = 1
                else
                    set desc = desc + s
                endif
            
            elseif (step == 1) then
            
                if (s == "^") then
                    set step = 3
                    set param = ""
                elseif (s == "=") then
                    set step = 2
                else
                    set param = param + s
                endif
                
            elseif (step == 2) then
            
                if (s == ";") then
                    call ParseParam(itm, StringCase(param, false), value[0])
                    
                    set param = ""
                    set value[0] = ""
                    set step = 1
                else
                    set value[0] = value[0] + s
                endif
                
            elseif (step == 3) then
            
                if (s == "=") then
                    set step = 4
                else
                    set param = param + s
                endif
                
            elseif (step == 4) then
            
                if (s == ";") then
                    set curVal = curVal + 1
                    
                    if (curVal >= 3) then
                        if (value[0] == "") then
                            set value[0] = "0"
                        elseif (value[1] == "") then
                            set value[0] = "0"
                      elseif (value[2] == "") then
                            set value[0] = "0"
                        endif
                        
                        call ParseBonusParam(itm, param, value[0], value[1], value[2])
                        
                        set step = 3
                        set curVal = 0
                        set value[0]=""
                        set value[1]=""
                        set value[2]=""
                        set param=""
                    endif
                    
                else
                    set value[curVal] = value[curVal] + s
                endif
                
            endif
                        
            set i = i + 1
        endloop
        
        set itm.info = desc
        
        return itm
    endfunction
    
endlibrary
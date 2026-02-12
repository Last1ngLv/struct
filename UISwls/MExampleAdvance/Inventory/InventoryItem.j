library InventoryItem uses Table, optional InventoryBonus
    
    globals
        public constant integer SEED_START = 0
        public constant integer SEED_END   = 999
    endglobals
    
    struct InvItem
        readonly static Table Table
        
        integer id
        integer icon
        integer cost
        integer ability
        string info
        integer tempCustomId
        
        implement InvItemPlugins
        
        static if not thistype.buildDescriptionLines.exists then
            method buildDescriptionLines takes integer pid, integer startLine returns integer
                return buildDescriptionLines(GetPlayerId(GetOwningPlayer(forUnit)), 0)
            endmethod
        endif
        
        static if not thistype.buildDescription.exists then
            method buildDescription takes unit forUnit returns string
                return buildDescriptionLines(GetPlayerId(GetOwningPlayer(forUnit)), 0)
            endmethod
        endif
        
        private static method onInit takes nothing returns nothing
            set InvItem.Table = Table.create()
        endmethod
    endstruct
    
    function GetInvItem takes integer id returns InvItem
        return InvItem(InvItem.Table[id])
    endfunction
    
    function GetItemInfo takes integer id returns string
        return InvItem(InvItem.Table[id]).info
    endfunction
    
    function GetItemDescription takes integer id returns string
        return InvItem(InvItem.Table[id]).info
    endfunction
    
    function GetItemIcon takes integer id returns integer
        local integer icon = InvItem(InvItem.Table[id]).icon
        if (icon == 0) then
            return Inventory.ICON_EMPTY
        endif
        return icon
    endfunction
    
    function CreateInvItem takes integer id, integer icon, integer cost, integer abil, string info returns InvItem
        local InvItem itm = InvItem.create()
        set itm.id   = id
        set itm.icon = icon
        set itm.cost = cost
        set itm.info = info
        set itm.ability = abil
        set InvItem.Table[itm.id] = itm
        return itm
    endfunction
    
    struct InvCustomItem extends array
        static integer Counter = 1
        static Table SeedTable
        
        static method create takes nothing returns thistype
            local thistype this = Counter
            set SeedTable[this] = GetRandomInt(SEED_START, SEED_END)
            set Counter = Counter + 1
            return this
        endmethod
        
        method seed takes nothing returns integer
            return SeedTable[this]
        endmethod
        
        static method onInit takes nothing returns nothing
            set SeedTable = SeedTable.create()
        endmethod
    endstruct

endlibrary
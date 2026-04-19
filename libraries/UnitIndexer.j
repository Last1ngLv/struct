library UnitIndexer requires UnitDex
  
    struct UnitIndexer
        readonly static integer INDEX   = EVENT_UNIT_INDEX
        readonly static integer DEINDEX = EVENT_UNIT_DEINDEX
      
        static method operator enabled= takes boolean b returns nothing
            set UnitDex.Enabled=b
        endmethod
      
        static method operator enabled takes nothing returns boolean
            return UnitDex.Enabled
        endmethod
    endstruct
  
    module UnitIndexStructMethods
        static method operator [] takes unit u returns thistype
            return GetUnitUserData(u)
        endmethod
      
        method operator unit takes nothing returns unit
            return UnitDex.Unit[this]
        endmethod
    endmodule
  
    module UnitIndexStruct
        implement UnitIndexStructMethods
      
        method operator allocated takes nothing returns boolean
            return this==GetUnitUserData(UnitDex.Unit[this])
        endmethod
    endmodule

    function IsUnitDeindexing takes unit u returns boolean
        return IsUnitIndexed(u) and 0==GetUnitAbilityLevel(u, UnitDex.DETECT_LEAVE_ABILITY)
    endfunction
  
    struct UnitIndex extends array
        method lock takes nothing returns nothing
        endmethod
      
        method unlock takes nothing returns nothing
        endmethod
      
        method operator unit takes nothing returns unit
            return UnitDex.Unit[this]
        endmethod
      
        static method operator [] takes unit whichUnit returns thistype
            return GetUnitUserData(whichUnit)
        endmethod
    endstruct
  
endlibrary
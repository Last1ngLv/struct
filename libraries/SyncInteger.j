//TESH.scrollpos=0
//TESH.alwaysfold=0
library SyncInteger initializer Init uses optional UnitDex /*or any unit indexer*/, optional GroupUtils, optional xebasic, optional PlayerUtils
/***************************************************************
*
*   v1.1.0, by TriggerHappy
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*
*   This library allows you to send integers to all other players.
*
*   _________________________________________________________________________
*   1. Installation
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*   Copy the script to your map and save it (requires JassHelper *or* JNGP)
*   _________________________________________________________________________
*   2. How it works
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       1. Creates {DUMMY_COUNT} units and assigns {BASE} of them an integer from 0-{BASE}.
*          The 2nd to last dummy is used to signal when the sequence of numbers is over and
*          the last dummy signifies a negative number.
*
*       2. Breaks down the number you want to sync to one or more {BASE} integers,
*          then selects each dummy unit assoicated with that integer.
*
*       4. The selection event fires for all players when the selection has been sycned
*
*       5. The ID of the selected unit is one of the {BASE} numbers. The current
*          total (starts at 0) is multiplied by {BASE} and the latest synced integer is
*          added to that. The process will repeat until it selects the 2nd to last dummy,
*          and the total is our result.
*   _________________________________________________________________________
*   3. Proper Usage
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       - Avoid the SyncSelections native. It may cause the thread to hang or
*         make some units un-able to move.
*
*       - Dummies must be select-able (no locust)
*
*       - Run the script in debug mode while testing
*   _________________________________________________________________________
*   4. Function API
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       function SyncInteger takes integer playerId, integer number returns boolean
*
*       function GetSyncedInteger takes nothing returns integer
*       function GetSyncedPlayer takes nothing returns player
*       function GetSyncedPlayerId takes nothing returns integer
*       function IsPlayerSyncing takes player p returns boolean
*       function IsSyncEnabled takes nothing returns boolean
*       function SyncIntegerToggle takes boolean flag returns nothing
*       function SyncIntegerEnable takes nothing returns nothing
*       function SyncIntegerDisable takes nothing returns nothing
*
*       function OnSyncInteger takes code func returns triggercondition
*       function RemoveSyncEvent takes triggercondition action returns nothing
*       function TriggerRegisterSyncEvent takes trigger t, integer eventtype returns nothing
*
*       function SyncInitialize takes nothing returns nothing
*       function SyncTerminate takes boolean destroyEvent returns nothing
*
*       function SyncNotify takes integer pid, unit dummy returns nothing
*       function SyncNotifyAddUnit takes unit dummy returns nothing
*
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*   -http://www.hiveworkshop.com/threads/syncinteger.278674/
*
*/
        globals
            // calls SyncInitialize automatically
            public constant boolean AUTO_INIT          = true
     
            // owner of the dummy units
            public constant player DUMMY_PLAYER        = Player(PLAYER_NEUTRAL_PASSIVE)
     
            // dummy can *not* have locust (must be selectabe)
            // basically anything should work (like 'hfoo')
            public constant integer DUMMY_ID           = 'hfoo' // XE_DUMMY_UNITID
     
            // dummy ghost ability
            public constant integer DUMMY_ABILITY      = 'Aeth'

            // debug mode
            public constant boolean ALLOW_DEBUGGING    = true
     
            // higher == more dummies but faster
            public constant integer BASE               = 10

            // don't need to change this
            public constant integer DUMMY_COUNT        = BASE+2
     
            // endconfig
            constant integer EVENT_SYNC_INTEGER = 1
     
            private trigger OnSelectTrigger = CreateTrigger()
            private trigger EventTrig       = CreateTrigger()
            private trigger NotifyTrig      = CreateTrigger()
            private real FireEvent          = 0
     
            private group SelectionGroup

            private integer array SyncedInt
            private integer LastPlayer
            private integer LastSync
            private unit array SyncIntegerDummy
            private integer array AttachedInteger
            private player LocalPlayer
            private unit array NotifyUnit
            private integer NotifyCount = 0
            private integer array NotifyIndex
            private real DUMMY_X = 0
            private real DUMMY_Y = 0
        endglobals
 
        function GetSyncedInteger takes nothing returns integer
            return LastSync
        endfunction
 
        function GetSyncedPlayer takes nothing returns player
            return Player(LastPlayer)
        endfunction
       
        function GetSyncedPlayerId takes nothing returns integer
            return LastPlayer
        endfunction
 
        function IsPlayerSyncing takes player p returns boolean
            return (SyncedInt[GetPlayerId(p)] != -1)
        endfunction
 
        function IsPlayerIdSyncing takes integer pid returns boolean
            return (SyncedInt[pid] != -1)
        endfunction

        function IsSyncEnabled takes nothing returns boolean
            return IsTriggerEnabled(OnSelectTrigger)
        endfunction
 
        function SyncIntegerEnable takes nothing returns nothing
            call EnableTrigger(OnSelectTrigger)
        endfunction
 
        function SyncIntegerDisable takes nothing returns nothing
            call DisableTrigger(OnSelectTrigger)
        endfunction
 
        function SyncIntegerToggle takes boolean flag returns nothing
            if (flag) then
                call EnableTrigger(OnSelectTrigger)
            else
                call DisableTrigger(OnSelectTrigger)
            endif
        endfunction
 
        function OnSyncInteger takes filterfunc func returns triggercondition
            return TriggerAddCondition(EventTrig, func)
        endfunction

        function RemoveSyncEvent takes triggercondition action returns nothing
           call TriggerRemoveCondition(EventTrig, action)
        endfunction
 
        function TriggerRegisterSyncEvent takes trigger t, integer eventtype returns nothing
            call TriggerRegisterVariableEvent(t, SCOPE_PREFIX + "FireEvent", EQUAL, eventtype)
        endfunction
 
        function OnSyncNotify takes filterfunc func returns nothing
            call TriggerAddCondition(NotifyTrig, func)
        endfunction
       
        function RemoveNotifyEvent takes triggercondition action returns nothing
           call TriggerRemoveCondition(NotifyTrig, action)
        endfunction
       
        function SyncNotify takes player p, integer notifyId returns nothing
            local player p2
           
            static if (LIBRARY_PlayerUtils) then
                set p2 = User.Local
            else
                set p2 = GetLocalPlayer()
            endif
           
            if (p == p2) then
                call SelectUnit(NotifyUnit[notifyId], true)
                call SelectUnit(NotifyUnit[notifyId], false)
            endif
        endfunction
       
        public function FireEvents takes real eventtype returns nothing
            set FireEvent = eventtype
            set FireEvent = 0
        endfunction
       
        private function Debug takes boolean b, string s returns nothing
            static if (ALLOW_DEBUGGING and DEBUG_MODE) then
                if (b) then
                    call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, "|c00FF0000" + SCOPE_PREFIX + s + "|r")
                endif
            endif
        endfunction
       
        function SyncNotifyCreate takes nothing returns integer
            local unit u = CreateUnit(DUMMY_PLAYER, DUMMY_ID, DUMMY_X, DUMMY_Y, 270)
            local integer uid = GetUnitUserData(u)
           
            set NotifyCount = NotifyCount + 1
           
            if (uid == 0) then
                call SetUnitUserData(u, NotifyCount)
                set uid = NotifyCount
            endif
           
            call Debug(uid == 0, "No unit indexer found.")
           
            set NotifyUnit[NotifyCount] = u
            set NotifyIndex[uid] = NotifyCount
           
            return NotifyCount
        endfunction
       
        function SyncInteger takes player p, integer number returns boolean
            local integer x = number
            local integer i = 0
            local integer d = BASE
            local integer j = 0
            local integer n = 0
            local integer l = 0
            local integer playerId = GetPlayerId(p)
            local unit u
            local unit last

            call Debug(OnSelectTrigger == null, "SyncInteger: OnSelectTrigger is destroyed.")
            call Debug(IsSyncEnabled() == false, "SyncInteger: OnSelectTrigger is disabled.")
     
            if (not IsSyncEnabled()) then
                return false
            endif
     
            // check if the number is negative
            if (number < 0) then
                set d = DUMMY_COUNT-1
                set number = number * -1
            endif
 
            loop
                set x = x/(BASE)
                exitwhen x==0
                set i=i+1
            endloop
     
            // Count how many units are selected
            call GroupEnumUnitsSelected(SelectionGroup, p, null)
            set bj_groupCountUnits = 0

            set u = FirstOfGroup(SelectionGroup)
            loop
                exitwhen u == null
                set last = u
                call GroupRemoveUnit(SelectionGroup, u)
                set bj_groupCountUnits = bj_groupCountUnits + 1
                set u = FirstOfGroup(SelectionGroup)
            endloop
         
            // If the queue is full, de-select the last unit which
            // will allow us to select a dummy, and hopefully
            // avoid a flickering effect.
            if (bj_groupCountUnits >= 12 and LocalPlayer == p) then
                call SelectUnit(last, false)
            endif

            set j=R2I(Pow(BASE, i))

            loop
                set n = j
                set x = number/n
                set j = j / BASE
             
                if (LocalPlayer == p) then
                    call SelectUnit(SyncIntegerDummy[x], true)
                    call SelectUnit(SyncIntegerDummy[x], false)
                endif
         
                set number = number-x*n

                exitwhen i == 0
         
                set i = i - 1
            endloop
 
            if (LocalPlayer == p) then
                call SelectUnit(SyncIntegerDummy[d], true)
                call SelectUnit(SyncIntegerDummy[d], false)
               
                if (bj_groupCountUnits >= 12) then
                    call SelectUnit(last, true)
                endif
            endif

            set u = null
            set last = null

            return true
        endfunction
 
        //this cleans up all dummies and triggers created by the system
        function SyncTerminate takes boolean destroyEvents returns nothing
            local integer i = 0
     
            if (destroyEvents) then
                call DestroyTrigger(OnSelectTrigger)
                call DestroyTrigger(EventTrig)
                call DestroyTrigger(NotifyTrig)
                set OnSelectTrigger = null
                set EventTrig = null
                set NotifyTrig = null
               
                static if not LIBRARY_GroupUtils then
                    call DestroyGroup(SelectionGroup)
                    set SelectionGroup = null
                endif
            else
                call SyncIntegerDisable()
            endif
     
            loop
                exitwhen i >= DUMMY_COUNT
                call RemoveUnit(SyncIntegerDummy[i])
                set SyncIntegerDummy[i] = null
                set i = i + 1
            endloop
           
            set i = 0
           
            loop
                exitwhen i >= NotifyCount
                call RemoveUnit(NotifyUnit[i])
                set NotifyUnit[i] = null
                set i = i + 1
            endloop
        endfunction
 
        function SyncInitialize takes nothing returns nothing
            local integer i = 0
            local integer uid
           
            call Debug(OnSelectTrigger == null, "SyncInitialize: OnSelectTrigger is null and has no events attached to it.")
            call Debug(SyncIntegerDummy[i] != null, "SyncInitialize: Already initialized.")

            loop
                exitwhen i >= DUMMY_COUNT
                set SyncIntegerDummy[i]=CreateUnit(DUMMY_PLAYER, DUMMY_ID, DUMMY_X, DUMMY_Y, i)
         
                set uid = GetUnitUserData(SyncIntegerDummy[i])
               
                if (uid == 0) then
                    call SetUnitUserData(SyncIntegerDummy[i], i + 1)
                    set uid = i + 1
                endif
               
                call Debug((i == 0) and (SyncIntegerDummy[i] == null), "SyncInitialize: Dummy unit is null (check DUMMY_ID).")
                call Debug((i == 0) and (GetUnitAbilityLevel(SyncIntegerDummy[i], 'Aloc') > 0), "SyncInitialize: Dummy units must be selectable (detected locust).")
                call Debug((i == 0) and (uid == 0), "No unit indexer found.")
               
                //call BJDebugMsg(I2S(uid))
               
                set AttachedInteger[uid] = i + 1

                call UnitAddAbility(SyncIntegerDummy[i], DUMMY_ABILITY)
                call PauseUnit(SyncIntegerDummy[i], true)
               
                set i = i + 1
            endloop
        endfunction

        private function OnSelect takes nothing returns boolean
            local unit u        = GetTriggerUnit()
            local player p      = GetTriggerPlayer()
            local integer id    = GetPlayerId(p)
            local boolean isNeg = (SyncIntegerDummy[DUMMY_COUNT-1] == u)
            local integer udata = GetUnitUserData(u)
            local integer index = AttachedInteger[udata] - 1

            // check for notifications
            if (NotifyUnit[NotifyIndex[udata]] == u) then
               
                set LastPlayer = id
                set LastSync = NotifyIndex[udata]
           
                call TriggerEvaluate(NotifyTrig)
               
                return false
            endif
           
            if (index == -1 or SyncIntegerDummy[index] != u) then
                set u = null
                return false
            endif
           
            call Debug(OnSelectTrigger == null, "SyncInteger: OnSelectTrigger is null.")
     
            if (isNeg) then
                set SyncedInt[id] = SyncedInt[id]*-1
            endif

            if (isNeg or SyncIntegerDummy[DUMMY_COUNT-2] == u) then
                // fire events
                set LastPlayer = id
                set LastSync = SyncedInt[id]

                set FireEvent = EVENT_SYNC_INTEGER
                call TriggerEvaluate(EventTrig)
                set FireEvent = 0
           
                set SyncedInt[id] = -1
            else
                if (SyncedInt[id]==-1)then
                    set SyncedInt[id]=0
                endif
                set SyncedInt[id] = SyncedInt[id] * BASE + index
            endif
     
            set u = null
     
            return false
        endfunction
       
        private function OnMapStart takes nothing returns nothing
            call DestroyTimer(GetExpiredTimer())
            call SyncInitialize()
        endfunction

        //===========================================================================
        private function Init takes nothing returns nothing
            local integer i = 0
            local integer j
     
            loop
                call TriggerRegisterPlayerUnitEvent(OnSelectTrigger, Player(i), EVENT_PLAYER_UNIT_SELECTED, null)
         
                set SyncedInt[i] = -1
         
                set i = i + 1
                exitwhen i==bj_MAX_PLAYER_SLOTS
            endloop

            call TriggerAddCondition(OnSelectTrigger, Filter(function OnSelect))
     
            static if (AUTO_INIT) then
                call TimerStart(CreateTimer(), 0., false, function OnMapStart)
            endif
     
            static if (LIBRARY_GroupUtils) then
                set SelectionGroup=ENUM_GROUP
            else
                set SelectionGroup=CreateGroup()
            endif

            static if (LIBRARY_PlayerUtils) then
                set LocalPlayer=User.Local
            else
                set LocalPlayer=GetLocalPlayer()
            endif
           
            set DUMMY_X = GetCameraBoundMaxX() + 500
            set DUMMY_Y = GetCameraBoundMaxY() + 500
        endfunction

endlibrary
//TESH.scrollpos=0
//TESH.alwaysfold=0
library SpacebarDetect initializer Init requires UnitDex, SyncInteger, PlayerUtils
/***************************************************************
*
*   v1.0.1 by TriggerHappy
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*
*   Allows detection of when the spacebar is pressed. This library does not
*   work with a locked camera. You must also use SetCameraQuickPositionEx 
*   if you want to set a custom spacebar point.
*   _________________________________________________________________________
*   1. Installation
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*   Copy the script and it's requirements to your map and save it (requires JassHelper *or* JNGP)
*   _________________________________________________________________________
*   2. API
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       function TriggerRegisterSpacebarEvent takes trigger t returns nothing
*       function OnSpacebarPress takes filterfunc func returns triggercondition
*       function SpacebarRemoveEvent takes triggercondition func returns nothing
*
*       function SetCameraQuickPositionEx takes real x, real y returns nothing
*
***************************************************************/
    globals 
        // config
        private constant real CHECK_INTERVAL = 0.05
        
        private constant real DETECT_X = 0.142 // random
        private constant real DETECT_Y = 0.241
        private constant real DETECT_EPSILON = 8.00
        // end
        
        private real FireEvent = 0
        private trigger EventTrig = CreateTrigger()
        
        private integer NotifyID = 0
        private real QP_X = DETECT_X + 0.1
        private real QP_Y = DETECT_Y + 0.1
    endglobals
    
    function OnSpacebarPress takes filterfunc func returns triggercondition
        return TriggerAddCondition(EventTrig, func)
    endfunction

    function SpacebarRemoveEvent takes triggercondition func returns nothing
        call TriggerRemoveCondition(EventTrig, func)
    endfunction
    
    function TriggerRegisterSpacebarEvent takes trigger t returns nothing
        call TriggerRegisterVariableEvent(t, SCOPE_PRIVATE + "FireEvent", EQUAL, 1)
    endfunction
    
    function SetCameraQuickPositionEx takes real x, real y returns nothing
        set QP_X = x
        set QP_Y = y
    endfunction
    
    private function FireEvents takes nothing returns nothing
        set FireEvent = 1
        set FireEvent = 0.0
        call TriggerEvaluate(EventTrig)
    endfunction
    
    private function OnSync takes nothing returns boolean
        local integer notifyId = GetSyncedInteger()
        local player p = GetSyncedPlayer()
        
        static if (DEBUG_MODE) then
            if (NotifyID == 0) then
                call BJDebugMsg("SpacebarDetect: No unit indexer found.")
            endif
        endif
        
        if (notifyId != NotifyID) then
            return false
        endif
        
        call FireEvents()
        
        return false
    endfunction
    
    private function IsDetectCameraTarget takes real x, real y returns boolean
        local real dx = x - DETECT_X
        local real dy = y - DETECT_Y
        return dx*dx + dy*dy <= DETECT_EPSILON*DETECT_EPSILON
    endfunction

    private function OnMapStart takes nothing returns nothing
        local real x = GetCameraTargetPositionX()
        local real y = GetCameraTargetPositionY()

        call SetCameraQuickPosition(DETECT_X, DETECT_Y)

        if IsDetectCameraTarget(x, y) then
            call SetCameraPosition(QP_X, QP_Y)
            call SyncNotify(User.Local, NotifyID)
        endif

    endfunction
    
    private function Init takes nothing returns nothing
        set NotifyID = SyncNotifyCreate()
        
        static if (LIBRARY_TimerUtils) then
            call TimerStart(NewTimer(), CHECK_INTERVAL, true, function OnMapStart)
        else
            call TimerStart(CreateTimer(), CHECK_INTERVAL, true, function OnMapStart)
        endif
        
        call OnSyncNotify(Filter(function OnSync))
    endfunction
    
endlibrary
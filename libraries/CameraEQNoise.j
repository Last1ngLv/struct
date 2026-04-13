//TESH.scrollpos=39
//TESH.alwaysfold=0
library CameraEQNoise /* v1.0
*************************************************************************************
*
*   Create timed "cameraEQnoise".
*
*   The code is not 100% local traffic safe. Do not use
*   the listed API in a GetLocalPlayer block!
*
*************************************************************************************
*
*   */ requires /*
*
*       */ TimerUtils /*
*
************************************************************************************
*
*   1. Import instruction
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       Copy CameraEQNoise and TimerUtils into to your map.
*       If you are using TimerUtilsEx, change the requirement
*       from TimerUtils to TimerUtilsEx.
**  
*   2. API
*   ¯¯¯¯¯¯
*
*   function CameraSetEQNoise takes player whichPlayer, real magnitude, real duration returns nothing
*       - Equal to the blizzard bj CameraSetEQNoiseForPlayer, but includes a timer callback.
*       - Do not use this function in a local traffic ( GetLocalPlayer() ) block.
*   
*   function StopCameraEQNoise takes player whichPlayer returns nothing
*       - Equal to the blizzard bj CameraClearNoiseForPlayer, but releases a running timer.
*            
************************************************************************************************
*/
    globals
        private timer array clock
    endglobals

    function StopCameraEQNoise takes player whichPlayer returns nothing
        local integer id = GetPlayerId(whichPlayer)
        if (clock[id] != null) then
            call ReleaseTimer(clock[id])
            set clock[id] = null
        endif
        if (GetLocalPlayer() == whichPlayer) then
            call CameraSetSourceNoise(0, 0)
            call CameraSetTargetNoise(0, 0)
        endif
    endfunction
    
    private function TimerExpire takes nothing returns nothing
        call StopCameraEQNoise(Player(GetTimerData(GetExpiredTimer())))
    endfunction
    
    function CameraSetEQNoise takes player whichPlayer, real magnitude, real duration returns nothing
        local real richter = magnitude
        local integer id   = GetPlayerId(whichPlayer)
        local real pow 
        if (richter > 5.) then
            set richter = 5.
        elseif (richter < 2.) then
            set richter = 2.
        endif
        call StopCameraEQNoise(whichPlayer)
        set clock[id] = NewTimerEx(id)
        call SetTimerDebugTag(clock[id], TIMER_DEBUG_TAG_OTHER)
        call TimerStart(clock[id], duration, false, function TimerExpire)
        set pow = magnitude*Pow(10, richter)
        if (GetLocalPlayer() == whichPlayer) then
            call CameraSetTargetNoiseEx(magnitude*2., pow, true)
            call CameraSetSourceNoiseEx(magnitude*2., pow, true)                
        endif
    endfunction

endlibrary

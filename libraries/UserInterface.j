library UserInterface initializer Init requires optional UnitDex/*or any unit indexer*/, Camera, TextTagDebug
/***************************************************************
*
*   v1.0.6, by TriggerHappy
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*
*   - Create UI elements based on dummy units. 
*
*   - Elements are overlay onto the current camera keeping you in gameplay. 
*
*   - The camera can be modified to any view including third person, however
*     it must be locked.
*
*   - Dynamic textures are applied to dummies through an ability based off
*     off War Clib, using destructables with their replaceable texture field 
*     set to the desired texture. (more: http://www.wc3c.net/showthread.php?p=1043980)
*
*   - Detect left and right clicks.
*
*   - Works in multiplayer (and single) without lag.
*   _________________________________________________________________________
*   1. Installation
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       1. Copy the script to your map and save it (requires JassHelper *or* JNGP)
*       2. Copy the object editor data and paste the correct raw codes into the configuration.
*   _________________________________________________________________________
*   2. API
*   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
*       struct UIButton
*
*           static method create takes real minx, real maxy, real W, real H, real z, integer texture returns thistype
*           static method updateAll takes nothing returns nothing
*           static method click takes unit u, boolean isLeft returns boolean
*           static method clickEx takes real x, real y, boolean isLeft returns boolean
*           static method clickPeriodicSelect takes player p, boolean isLeft returns boolean
*
*           method destroy takes nothing returns nothing
*           method update takes nothing returns nothing
*           method show takes boolean flag, Camera Cam returns nothing
*           method showPlayer takes player p, boolean flag, Camera cam returns nothing
*           method isClicked takes real x, real y returns boolean
*           method clickL takes nothing returns nothing
*           method clickR takes nothing returns nothing
*           method setPosition takes real minx, real maxy returns nothing
*           method setTexture takes integer texture returns nothing
*
*           -----------------------
*
*           integer customValue
*           integer animIndex
*           trigger triggerL
*           trigger triggerR
*           filterfunc onLeftClick
*           filterfunc onRightClick
*
*
*       struct UIPicture
*
*           static method create takes real minx, real maxy, real w, real h, real z, integer texture returns thistype
*           static method createEx takes real minx, real maxy, real z, real scale, integer unitId, real modelWidth, real modelHeight, integer texture returns thistype
*           static method updateAll takes nothing returns nothing

*           method destroy takes nothing returns nothing
*           method update takes nothing returns nothing
*           method show takes boolean show, Camera Cam returns nothing
*           method showPlayer takes player p, boolean flag, Camera cam returns nothing
*           method setPosition takes real minx, real maxy returns nothing
*           method setTexture takes integer texture returns nothing
*
*           -----------------------
*
*           integer customValue
*           integer animIndex
*
*       struct UIText
*   
*           static method create takes real minx, real maxy, real z returns thistype
*           static method updateAll takes nothing returns nothing
*
*           method destroy takes nothing returns nothing
*           method update takes nothing returns nothing
*           method setPosition takes real minx, real maxy returns nothing
*           method show takes boolean show, Camera Cam returns nothing
*
*           -----------------------
*
*           integer customValue
*
*       function GetTriggerButton takes nothing returns UIButton
*       function GetClickingPlayer takes nothing returns player
*       function GetCameraDeltaZ takes nothing returns real
*       function CreateWindow takes real x, real y, real size, real width, real height, race playerRace returns UIPicture
*
*       public function ApplySkin takes unit u, integer texture returns boolean
*
***************************************************************/

    // configuration
    private module InterfaceConfig
    
        // dummy unit with pitch angle animations
        static constant integer DUMMY_TYPE          = 'uidm'
        
        // model used in CreateWindow function
        static constant integer WINDOW_DUMMY        = 'uiwn'
        
        // destructable ID of the human border texture. the
        // rest of the races should have consecutive ids.
        static constant integer RACE_BORDERS_START  = 'D201'
        
        // run a timer to check for unit selections.
        // faster but more cpu intensive.
        static constant boolean LEFT_CLICK_TIMER    = true

            // really low timer intervals remove the flicker
            // effect, most of the time.
            static constant real LEFT_CLICK_TIMER_RATE  = 0.01

            // in multiplayer, IsUnitSelected is synchronous
            // so it doesn't instantly return false when you use
            // SelectUnit(u, false). So we must disable the button
            // for the clicking player for a brief period or else
            // the event will be spammed.
            static constant real LEFT_CLICK_DELAY   = 0.6
        
        // ability id's
        static constant integer DESTROYER_FORM_ID   = 'Aave'
        static constant integer LOCUST_ID           = 'Aloc'
        
        // ability used to change dummy unit textures
        static constant integer SKIN_CHANGE_ABILITY = 'Skin'
        
        static constant integer GHOST_ABILITY       = 'Aeth'

        // dummy player
        static constant player PLAYER               = CAMERA_DUMMY_PLAYER // from Camera library
        
    endmodule
    // end configuration

    globals
        public destructable DummyTree = null
        private trigger Trig = CreateTrigger()
        private UIButton ClickedButton = 0
        private player ClickingPlayer = null
        private location DummyLoc = Location(0,0)
    endglobals

    function GetTriggerButton takes nothing returns UIButton
        return ClickedButton
    endfunction
    
    function GetClickingPlayer takes nothing returns player
        return ClickingPlayer
    endfunction

    public function Eval takes filterfunc func returns boolean
        call TriggerClearConditions(Trig)
        call TriggerAddCondition(Trig, func)
        return TriggerEvaluate(Trig)
    endfunction

    public function GetTerrainZ takes real x, real y returns real
        call MoveLocation(DummyLoc, x, y)
        return GetLocationZ(DummyLoc)
    endfunction
    
    // adjusts 
    public function FindModelAnimIndex takes real w, real h, real z returns integer
        local real W = w*SCREEN_WIDTH*z
        local real H = h*SCREEN_HEIGHT*z
        local real anim
        if (H<W) then
            set anim = 10*(W/H-1)
            return UIMath_R2I_N(anim)
        else
            set anim = 10*(H/W-1)
            if anim >= 0.5 then
                return 100+UIMath_R2I_N(anim)
            endif
        endif
        return 0
    endfunction

    public function FindModelSize takes real w, real h, real z returns real
        local real W = w*SCREEN_WIDTH*z
        local real H = h*SCREEN_HEIGHT*z
        if (H<W) then
            return 0.5*H
        endif
        return 0.5*W
    endfunction

    private function LocalReal takes player p, real forPlayer, real default returns real
        if (User.Local == p) then
            return forPlayer
        endif
        return default
    endfunction
    
    public function ApplySkin takes unit u, integer texture returns boolean
        local boolean out = false
        
        if (texture != 0) then
            
            call UnitAddAbility(u, Interface.SKIN_CHANGE_ABILITY)
            set DummyTree = CreateDestructable(texture,GetUnitX(u),GetUnitY(u),0,0,1)
            set out = IssueTargetOrder(u, "grabtree", DummyTree)
            call RemoveDestructable(DummyTree)
            set DummyTree = null
            call UnitRemoveAbility(u, Interface.SKIN_CHANGE_ABILITY)
        endif
        
        return out
    endfunction

    struct UIButton
        integer customValue
        integer animIndex
        trigger triggerL
        trigger triggerR
        filterfunc onLeftClick
        filterfunc onRightClick
        boolean disabled
        unit selectUnit

        static boolean useDelay = false

        readonly static thistype array AllShow
        readonly static integer CountShow = 0

        readonly integer index
        readonly Camera camera
        
        readonly real scale
        readonly real centerx
        readonly real centery
        readonly real minx
        readonly real maxx
        readonly real miny
        readonly real maxy
        readonly real width
        readonly real height
        readonly real z
        readonly unit picture
        readonly effect model
        
        readonly boolean displayed
        readonly integer texture 
        
        private integer unitId
        private static thistype array Unit2Button
        
        static method create takes real minx, real maxy, real W, real H, real z, integer texture returns thistype
            local thistype this = thistype.allocate()

            set .texture        = texture
            set .customValue    = 0
            set .camera         = 0
            set .width          = W
            set .height         = H
            set .minx           = minx
            set .maxx           = minx+W
            set .maxy           = maxy
            set .miny           = maxy-H
            set .z              = 100.2+z
            set .centerx        = minx+W/2.0
            set .centery        = maxy-H/2.0
            set .displayed      = false
            set .scale          = FindModelSize(W, H, .z)
            set .triggerL       = null
            set .triggerR       = null
            set .onLeftClick    = null
            set .onRightClick   = null
            set .selectUnit     = null
            set .picture        = CreateUnit(Interface.PLAYER, Interface.DUMMY_TYPE, 0, 0, 0)
            
            // apply texture
            call ApplySkin(.picture, texture)
            
            set .animIndex = FindModelAnimIndex(W, H, .z)
            call SetUnitAnimationByIndex(.picture, .animIndex)
            call UnitAddAbility(.picture, Interface.DESTROYER_FORM_ID)
            call UnitRemoveAbility(.picture, Interface.DESTROYER_FORM_ID)
            call UnitAddAbility(.picture, Interface.SKIN_CHANGE_ABILITY)
            call UnitAddAbility(.picture, Interface.GHOST_ABILITY)
            
            set this.unitId = GetUnitUserData(.picture)
            set Unit2Button[this.unitId] = this
            
            call SetUnitScale(.picture, 0, 0, 0)
            
            return this
        endmethod
        
        method destroy takes nothing returns nothing
            call RemoveUnit(.picture)
            
            if .displayed then
                set .AllShow[.index] = .AllShow[.CountShow]
                set .AllShow[.index].index = .index
                set .CountShow = .CountShow - 1
            endif
        endmethod

        method update takes nothing returns nothing
            local VECTOR3 Pos
            
            if (.displayed) then
                set Pos = .camera.win2World(.centerx, .centery, .z)
                call SetUnitX(.picture, Pos.x)
                call SetUnitY(.picture, Pos.y)
                call SetUnitFlyHeight(.picture, Pos.z-GetTerrainZ(Pos.x, Pos.y), 0)
                call Pos.destroy()
            endif
        endmethod
        
        method show takes boolean flag, Camera Cam returns nothing
            if Cam != -1 then
                set .camera = Cam
            endif
            
            if flag != .displayed then
                if flag then
                    set .AllShow[.CountShow] = this
                    set .index = .CountShow
                    set .CountShow = .CountShow + 1
                    call .update()
                    call SetUnitAnimationByIndex(.picture, .animIndex)
                    
                    call SetUnitScale(.picture, .scale, 0, 0)
                else
                    set .CountShow = .CountShow - 1
                    set .AllShow[.index] = .AllShow[.CountShow]
                    set .AllShow[.index].index = .index
                    
                    call SetUnitX(.picture, 0)
                    call SetUnitY(.picture, 0)
                    
                    call SetUnitScale(.picture, 0, 0, 0)
                endif
            endif
            
            set .displayed = flag
        endmethod
        
        method showPlayer takes player p, boolean flag, Camera cam returns nothing
            call .show(flag, cam)
            
            if (flag) then
                call SetUnitScale(.picture, LocalReal(p, .scale, 0), 0, 0)
            endif
        endmethod

        method isClicked takes real x, real y returns boolean
            return .minx < x and x < .maxx and .miny < y  and y < .maxy
        endmethod
        
        method clickL takes nothing returns nothing
            set ClickedButton = this

            if (.triggerL != null and TriggerEvaluate(.triggerL)) then
                call TriggerExecute(.triggerL)
            endif

            if (.onLeftClick != null) then
                 call Eval(.onLeftClick)
            endif
        endmethod
        
        method clickR takes nothing returns nothing
            set ClickedButton = this

            if (.triggerR != null and TriggerEvaluate(.triggerR)) then
                call TriggerExecute(.triggerR)
            endif
            
            if (.onRightClick != null) then
                 call Eval(.onRightClick)
            endif
        endmethod
        
        method setPosition takes real minx, real maxy returns nothing
            set .minx = minx
            set .maxx = minx+.width
            set .maxy = maxy
            set .miny = maxy-.height
            set .centerx = minx+.width/2.0
            set .centery = maxy-.height/2.0
            
            if .displayed then
                call .update()
            endif
        endmethod
        
        method setTexture takes integer texture returns nothing
            call SetUnitX(.picture, 0)
            call SetUnitY(.picture, 0)
            call ApplySkin(.picture, texture)
            
            if .displayed then
                call .update()
            endif
            
            set .texture = texture
        endmethod
        
        static method updateAll takes nothing returns nothing
            local integer i = .CountShow
            loop
                exitwhen i < 0
                call .AllShow[i].update()
                set i = i - 1
            endloop
        endmethod
        
        static method click takes unit u, boolean isLeft returns boolean
            local thistype b
            
            if GetUnitTypeId(u) == Interface.DUMMY_TYPE then
                set b = Unit2Button[GetUnitUserData(u)]

                if b > 0 and b.displayed then
                    call SelectUnit(u, false)

                    if isLeft then
                        call b.clickL()
                    else
                        call b.clickR()
                    endif
                    
                    return true
                endif
            endif
            
            return false
        endmethod
        
        static method clickEx takes real x, real y, boolean isLeft returns boolean
            local integer i = .CountShow
            
            loop
                exitwhen i < 0

                if .AllShow[i].isClicked(x, y) then
                    if isLeft then
                        call .AllShow[i].clickL()
                    else
                        call .AllShow[i].clickR()
                    endif
                    
                    return true
                endif
                
                set i = i - 1
            endloop
            
            return false
        endmethod
        
        private static method enableButtonCallback takes nothing returns nothing
            local timer t = GetExpiredTimer()

            static if (LIBRARY_TimerUtils) then
                local thistype btn = thistype(GetTimerData(t))
            else
                local thistype btn = thistype(R2I(TimerGetRemaining(t) + 0.5))
            endif

            set btn.disabled = false
            static if (LIBRARY_TimerUtils) then
                call ReleaseTimer(t)
            else
                call DestroyTimer(t)
            endif
            set t = null
        endmethod

        static method clickPeriodicSelect takes player p, boolean isLeft returns boolean
            local integer i = .CountShow
            local timer t
            
            loop
                exitwhen i < 0

                if (IsUnitSelected(.AllShow[i].picture, p)) then
                    
                    if (not .AllShow[i].disabled) then

                        if isLeft then
                            call .AllShow[i].clickL()
                        else
                            call .AllShow[i].clickR()
                        endif

                        
                        if (thistype.useDelay) then // static if doesn't work..
                            set .AllShow[i].disabled = true

                            static if (LIBRARY_TimerUtils) then
                                set t = NewTimerEx(.AllShow[i])
                                call SetTimerDebugTag(t, TIMER_DEBUG_TAG_OTHER)
                                call TimerStart(t, Interface.LEFT_CLICK_DELAY, false, function thistype.enableButtonCallback)
                            else
                                set t = CreateTimer()
                                call TimerStart(t, .AllShow[i], false, null)
                                call PauseTimer(t)
                                call TimerStart(t, Interface.LEFT_CLICK_DELAY, false, function thistype.enableButtonCallback)
                                set t = null
                            endif
                        endif
                        
                        return true
                    endif

                    call SelectUnit(.AllShow[i].picture, false)

                    if (.AllShow[i].selectUnit != null and User.Local == p) then
                        call SelectUnit(.AllShow[i].selectUnit, true)
                    endif

                endif
                
                set i = i - 1
            endloop
            
            return false
        endmethod

    endstruct

    struct UIPicture
        integer customValue
        integer animIndex
        
        readonly static thistype array AllShow
        readonly static integer CountShow = 0
        
        readonly integer index
        readonly Camera camera
        
        readonly real scale
        readonly real centerx
        readonly real centery
        readonly real width
        readonly real height
        readonly real z
        readonly unit picture
        readonly boolean displayed
        readonly integer texture 

        static method create takes real minx, real maxy, real w, real h, real z, integer texture returns thistype
            local thistype this = thistype.allocate()

            set .texture        = texture
            set .customValue    = 0
            set .camera         = 0
            set .width          = w
            set .height         = h
            set .centerx        = minx+w/2.0
            set .centery        = maxy-h/2.0
            set .z              = 100.2+z
            set .displayed      = false
            set .picture        = CreateUnit(Interface.PLAYER, Interface.DUMMY_TYPE, 0, 0, 0)
            set .animIndex      = FindModelAnimIndex(w, h, .z)
            set .scale          = FindModelSize(w, h, .z)
            
            call ApplySkin(.picture, texture)
            
            call SetUnitAnimationByIndex(.picture, .animIndex)
            
            call UnitAddAbility(.picture, Interface.DESTROYER_FORM_ID)
            call UnitRemoveAbility(.picture, Interface.DESTROYER_FORM_ID)
            call UnitAddAbility(.picture, Interface.LOCUST_ID)
            call UnitRemoveAbility(.picture, Interface.LOCUST_ID)
            
            // hide unit
            call SetUnitScale(.picture, 0, 0, 0)
            
            return this
        endmethod
        
        static method createEx takes real minx, real maxy, real z, real scale, integer unitId, real modelWidth, real modelHeight, integer texture returns thistype
            local thistype this = thistype.allocate()

            set .customValue    = 0
            set .camera         = 0
            set .z              = 100.2 + z
            set .width          = (modelWidth*scale) / (SCREEN_WIDTH*.z)
            set .height         = (modelHeight*scale) / (SCREEN_HEIGHT*.z)
            set .scale          = scale
            set .centerx        = minx+.width/2.0
            set .centery        = maxy-.height/2.0
            set .displayed      = false
            set .picture        = CreateUnit(Interface.PLAYER, unitId, 0, 0, 270)
            
            call ApplySkin(.picture, texture)
            
            call UnitAddAbility(.picture, Interface.DESTROYER_FORM_ID)
            call UnitRemoveAbility(.picture, Interface.DESTROYER_FORM_ID)
            call UnitAddAbility(.picture, Interface.LOCUST_ID)
            call UnitRemoveAbility(.picture, Interface.LOCUST_ID)
            
            // hide unit
            call SetUnitScale(.picture, 0, 0, 0)
            
            return this
        endmethod
        
        method destroy takes nothing returns nothing
            call RemoveUnit(.picture)
            
            if .displayed then
                set .AllShow[.index] = .AllShow[.CountShow]
                set .AllShow[.index].index = .index
                set .CountShow = .CountShow - 1
            endif
        endmethod

        method update takes nothing returns nothing
            local VECTOR3 Pos

            if (this.displayed) then
                set Pos = this.camera.win2World(.centerx, .centery, .z)
                call SetUnitX(.picture, Pos.x)
                call SetUnitY(.picture, Pos.y)
                call SetUnitFlyHeight(.picture, Pos.z - GetTerrainZ(Pos.x, Pos.y), 0)
                call Pos.destroy()
            endif
        endmethod
        
        method show takes boolean show, Camera Cam returns nothing
            if Cam != -1 then
                set this.camera = Cam
            endif

            if show != .displayed then
                if show then
                    set .AllShow[.CountShow] = this
                    set .index = .CountShow
                    set .CountShow = .CountShow + 1
                    call .update()
                    call SetUnitAnimationByIndex(.picture, .animIndex)
                    call SetUnitScale(.picture, .scale, 0, 0)
                else
                    set .CountShow = .CountShow - 1
                    set .AllShow[.index] = .AllShow[.CountShow]
                    set .AllShow[.index].index = .index
                    call SetUnitX(.picture, 0)
                    call SetUnitY(.picture, 0)
                    call SetUnitScale(.picture, 0, 0, 0)
                endif
            endif
            
            set .displayed = show
        endmethod
        
        method showPlayer takes player p, boolean flag, Camera cam returns nothing
            call .show(flag, cam)
            
            if (flag) then
                call SetUnitScale(.picture, LocalReal(p, .scale, 0), 0, 0)
            endif
        endmethod
        
        method setPosition takes real minx, real maxy returns nothing
            set .centerx = minx+.width/2.0
            set .centery = maxy-.height/2.0
            if .displayed then
                call .update()
            endif
        endmethod
        
        method setTexture takes integer texture returns nothing
            call SetUnitX(.picture, 0)
            call SetUnitY(.picture, 0)
            call ApplySkin(.picture, texture)
            
            if .displayed then
                call .update()
            endif
            
            set .texture = texture
        endmethod
        
        static method updateAll takes nothing returns nothing
            local integer i = .CountShow

            loop
                exitwhen i < 0
                call .AllShow[i].update()
                set i = i - 1
            endloop
        endmethod

    endstruct

    struct UIText
        integer customValue
        
        readonly unit dummy
        readonly static thistype array AllShow
        readonly static integer CountShow = 0
        readonly integer index
        readonly Camera camera
        readonly real minx
        readonly real maxy
        readonly real z
        readonly texttag text
        readonly boolean displayed
        
        static method create takes real minx, real maxy, real z returns thistype
            local thistype this = thistype.allocate()
            
            set .customValue    = 0
            set .camera         = 0
            set .minx           = minx
            set .maxy           = maxy
            set .z              = 100 + z
            set .displayed      = false
            set .text           = CreateTrackedTextTag(TEXTTAG_DEBUG_UI)
            set .dummy          = CreateUnit(Interface.PLAYER, Interface.DUMMY_TYPE, 0, 0, 0)

            call SetUnitScale(.dummy, 0, 0, 0)

            call UnitAddAbility(.dummy, Interface.LOCUST_ID)
            call UnitRemoveAbility(.dummy, Interface.LOCUST_ID)
            
            call SetTextTagVisibility(.text, false)
            call SetTextTagPosUnit(.text, .dummy, 0)
            
            return this
        endmethod
        
        static method createEx takes player p, real minx, real maxy, real z returns thistype
            local thistype this = thistype.allocate()
            
            set .customValue    = 0
            set .camera         = 0
            set .minx           = minx
            set .maxy           = maxy
            set .z              = 100 + z
            set .displayed      = false
            set .dummy          = CreateUnit(Interface.PLAYER, Interface.DUMMY_TYPE, 0, 0, 0)

            if (User.Local == p) then
                set .text = CreateTrackedTextTag(TEXTTAG_DEBUG_UI)
            endif
            
            call SetUnitScale(.dummy, 0, 0, 0)

            call UnitAddAbility(.dummy, Interface.LOCUST_ID)
            call UnitRemoveAbility(.dummy, Interface.LOCUST_ID)
            
            call SetTextTagVisibility(.text, false)
            call SetTextTagPosUnit(.text, .dummy, 0)
            
            return this
        endmethod
        
        method destroy takes nothing returns nothing
            if .text != null then
                call DestroyTrackedTextTag(.text, TEXTTAG_DEBUG_UI)
            endif
            
            if .displayed then
                set .AllShow[.index] = .AllShow[.CountShow]
                set .AllShow[.index].index = .index
                set .CountShow = .CountShow - 1
            endif
        endmethod
        
        method update takes nothing returns nothing
            local VECTOR3 Pos = .camera.win2World(.minx, .maxy, .z)
            call SetUnitX(.dummy, Pos.x)
            call SetUnitY(.dummy, Pos.y)
            call SetTextTagPosUnit(.text, .dummy, (Pos.z-GetTerrainZ(Pos.x,Pos.y))-14.8)
            call Pos.destroy()
        endmethod
        
        method setPosition takes real minx, real maxy returns nothing
            set .minx = minx
            set .maxy = maxy
            
            if .displayed then
                call .update()
            endif
        endmethod
        
        method show takes boolean show, Camera Cam returns nothing
            if Cam != -1 then
                set .camera = Cam
            endif
            
            call SetTextTagVisibility(.text, show)
            
            if show != .displayed then
                if show then
                    set .AllShow[.CountShow] = this
                    set .index = .CountShow
                    set .CountShow = .CountShow + 1
                    call .update()
                else
                    set .CountShow = .CountShow - 1
                    set .AllShow[.index] = .AllShow[.CountShow]
                    set .AllShow[.index].index = .index
                endif
            endif
            
            set .displayed = show
        endmethod
        
        static method updateAll takes nothing returns nothing
            local integer i = .CountShow
            loop
                exitwhen i < 0
                call .AllShow[i].update()
                set i = i - 1
            endloop
        endmethod

    endstruct

    struct Interface extends array
        
        implement InterfaceConfig
        
       static method getRaceBorders takes race r returns integer
            return RACE_BORDERS_START + (GetHandleId(r)-1)
        endmethod
        
        static method updateAll takes boolean but, boolean pic, boolean tex returns nothing
            if but then
                call UIButton.updateAll()
            endif
            if pic then
                call UIPicture.updateAll()
            endif
            if tex then
                call UIText.updateAll()
            endif
        endmethod

    endstruct

    function CreateWindow takes real x, real y, real size, real width, real height, race playerRace returns UIPicture
        return UIPicture.createEx(x, y, /*z=*/2, size, Interface.WINDOW_DUMMY, width, height, Interface.getRaceBorders(playerRace))
    endfunction
    
    private function InterfaceClickR takes nothing returns nothing
        local unit clicker = GetTriggerUnit()
        local unit btnUnit = GetOrderTargetUnit()
        
        set ClickingPlayer = GetOwningPlayer(clicker)
        
        if (UIButton.click(btnUnit, false)) then
            call PauseUnit(clicker, true)
            call IssueImmediateOrderById(clicker, 851973)
            call PauseUnit(clicker, false)
        endif
        
        set clicker = null
    endfunction
    
    private function InterfaceClickL takes nothing returns nothing
        set ClickingPlayer = GetTriggerPlayer()
        call UIButton.click(GetTriggerUnit(), true)
    endfunction

    private function InterfaceClickL_Timer takes nothing returns nothing
        local integer i = 0
        local integer c = UIButton.CountShow
        local User user = User.first
        
        loop
            exitwhen user == User.NULL
  
            set ClickingPlayer = user.handle
            
            call UIButton.clickPeriodicSelect(user.handle, true)

            set user = user.next
        endloop
    endfunction
    
    private function Init takes nothing returns nothing
         local trigger t = CreateTrigger()
         local trigger t2 = CreateTrigger()
         local integer i = 0
         local User user = User.first
        
         loop
            exitwhen user == User.NULL
            
            call TriggerRegisterPlayerUnitEvent(t, user.handle, EVENT_PLAYER_UNIT_ISSUED_UNIT_ORDER, null)
            
            static if (not Interface.LEFT_CLICK_TIMER) then
                call TriggerRegisterPlayerUnitEvent(t2, user.handle, EVENT_PLAYER_UNIT_SELECTED, null)
            endif
            
            set user = user.next
        endloop

        call TriggerAddAction(t, function InterfaceClickR)
        
        static if (Interface.LEFT_CLICK_TIMER) then
            call TimerStart(CreateTimer(), Interface.LEFT_CLICK_TIMER_RATE, true, function InterfaceClickL_Timer)
        else
            call TriggerAddAction(t2, function InterfaceClickL)
        endif

        set UIButton.useDelay = Interface.LEFT_CLICK_TIMER
    endfunction
    
endlibrary

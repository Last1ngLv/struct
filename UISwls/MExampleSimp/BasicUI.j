library Example initializer CreateInterfaces requires StartGame
    
    globals
        // configuration
        private constant real BACKGROUND_X = 0.32
        private constant real BACKGROUND_Y = 0.32
        private constant real BACKGROUND_W = 140.
        private constant real BACKGROUND_H = 70.
        private constant real BACKGROUND_SIZE = 0.26
        // end config
        
        BasicWindow array PlayerWindow
        
        private UIPicture array Background
        private UIButton array Buttons[15][20]
        private UIButton array DoubleClickButton
        private UIText array Text
        
        private constant real BUTTON_W = .1
        private constant real BUTTON_H = .1 * SCREEN_ASPECT_RATIO
        
        private boolean array Displayed
        private UIButton array LastButton
    endglobals
    
    private function OnLeftClick takes nothing returns boolean
        local UIButton btn = GetTriggerButton()
        local integer pid = btn.customValue
        local player p = GetClickingPlayer()
        
        if (User.Local == p) then
            call SelectUnit(PlayerHero[pid], true)
        endif
        
        if (btn == DoubleClickButton[pid] and LastButton[pid] != 0) then
            call BJDebugMsg("[" + User[p].nameColored + "] Double-Click: Button #" + I2S(LastButton[pid]))
            set LastButton[pid] = 0
        else
            call BJDebugMsg("[" + User[p].nameColored + "] Left-Click: Button #" + I2S(btn))
        endif
        
        set LastButton[pid] = btn
        
        return false
    endfunction
    
    private function OnRightClick takes nothing returns boolean
        local UIButton btn = GetTriggerButton()
        local integer pid = btn.customValue
        local player p = GetClickingPlayer()

        call BJDebugMsg("[" + User[p].nameColored + "] Right-Click: Button #" + I2S(btn))
        
        return false
    endfunction
    
    struct BasicWindow
        
        // we use an array instead of struct members
        // to create for each player only once
        static UIPicture array Background
        static UIButton array Buttons[15][20] // size for 15 players, 20 buttons
        static UIText array Text
        
        readonly boolean displayed
        readonly User user
        readonly Camera camera
        readonly thistype next
        readonly thistype prev
        readonly integer buttons

        method addButton takes real x, real y, integer texture returns UIButton
            set Buttons[user.id][.buttons]              = UIButton.create(x, y, BUTTON_W, BUTTON_H, 0.5, texture)
            //set Buttons[user.id][.buttons].onLeftClick  = Filter(function OnLeftClick)
            set Buttons[user.id][.buttons].onRightClick = Filter(function OnRightClick)
            set Buttons[user.id][.buttons].customValue  = .user.id
            set Buttons[user.id][.buttons].selectUnit   = PlayerHero[.user.id] // unit to re-select when selecting dummy
            
            set .buttons = .buttons + 1
            
            return Buttons[user.id][.buttons-1]
        endmethod

        static method create takes User user, Camera cam returns thistype
            local thistype this = thistype.allocate()
            local integer i = 0
            
            set this.camera = cam
            set this.user = user
            set this.buttons = 0

            // create only once per player
            if (Background[user.id] == 0) then
            
                // create background
                set Background[user.id] = CreateWindow(BACKGROUND_X, BACKGROUND_Y, BACKGROUND_SIZE, BACKGROUND_W, BACKGROUND_H, GetPlayerRace(user.handle))

                // create title
                set Text[user.id] = UIText.createEx(user.handle, BACKGROUND_X + 0.15, BACKGROUND_Y, 1)
                call SetTextTagText(Text[user.id].text, "Custom User Interface v1.0", 12 * 0.0023)
                
                // create double click detector (not officially supported)
                set DoubleClickButton[user.id] = this.addButton(BACKGROUND_X + 0.28, 0.24, 'B002')
                
                // create top button
                call this.addButton(BACKGROUND_X + 0.28, 0.06, 'B000')
                
                // create bottom button
                call this.addButton(BACKGROUND_X + 0.28, -0.12, 'B001')
   
            endif
            
            return this
        endmethod
        
        method show takes boolean flag returns nothing
            local integer i = this.user.id
            local integer n = 0
            local player p = this.user.handle
            
            // show only to one player for performance
            call Background[i].showPlayer(p, flag, PlayerCamera[i])
            call Text[i].show(flag, PlayerCamera[i])
            
            loop
                exitwhen n == .buttons
                call Buttons[i][n].showPlayer(p, flag, PlayerCamera[i])
                set n = n + 1
            endloop
        endmethod
        
        method update takes nothing returns nothing
            local integer i = this.user.id
            local integer n = 0
            
            // update only the elements we need
            call Background[i].update()
            call Text[i].update()
            
            loop
                exitwhen n == .buttons
                call Buttons[i][n].update()
                set n = n + 1
            endloop
        endmethod
        
    endstruct

    private function OnUpdate takes nothing returns nothing
        local User user = User(User.LocalId)
        local integer id = user.id
        local Camera cam = PlayerCamera[id]
        local real x = GetUnitX(PlayerHero[id])
        local real y = GetUnitY(PlayerHero[id])
        local BasicWindow window = PlayerWindow[id]

        call cam.setPosition(x, y, UserInterface_GetTerrainZ(x, y))
        
        if (cam.applyCameraForPlayer(user.handle, false)) then
            //call Interface.updateAll(true, true, true)
            call window.update()
        endif
    endfunction
    
    private function CreateInterfaces takes nothing returns nothing
        local User user = User.first
        local BasicWindow window
        
        loop
            exitwhen user == User.NULL

            // create a basic window for all playing players
            set window = BasicWindow.create(user, PlayerCamera[user.id])
            
            set PlayerWindow[user.id] = window
            
            call window.show(true)

            set user = user.next
        endloop

        call TimerStart(CreateTimer(), 0.01, true, function OnUpdate)
    endfunction

endlibrary
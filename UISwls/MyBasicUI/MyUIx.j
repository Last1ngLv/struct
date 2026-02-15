library MyUIExample initializer CreateInterfaces requires StartMy
    
    globals
        // configuration
        private constant real BACKGROUND_X = -0.33 //center???
        private constant real BACKGROUND_Y = 0.70
        private constant real BACKGROUND_W = 140.
        private constant real BACKGROUND_H = 70.
        private constant real BACKGROUND_SIZE = 0.26
        // end config
        
        BasicWindow array PlayerWindow
        
        private UIPicture array Backgrounds[15][5]
        private UIButton array Buttons[15][20]
        private UIButton array DoubleClickButton
        private UIText array Texts[15][20]
        
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
        static UIPicture array Backgrounds[15][5]
        static UIButton array Buttons[15][20] // size for 15 players, 20 buttons
        static UIText array Texts[15][20]
        
        readonly boolean displayed
        readonly User user
        readonly Camera camera
        readonly thistype next
        readonly thistype prev
        readonly integer buttons
        readonly integer backgrounds
        readonly integer texts

        method addButton takes real x, real y, integer texture returns UIButton
            set Buttons[user.id][.buttons]              = UIButton.create(x, y, BUTTON_W, BUTTON_H, 0.5, texture)
            //set Buttons[user.id][.buttons].onLeftClick  = Filter(function OnLeftClick)
            set Buttons[user.id][.buttons].onRightClick = Filter(function OnRightClick)
            set Buttons[user.id][.buttons].customValue  = .user.id
            set Buttons[user.id][.buttons].selectUnit   = PlayerHero[.user.id] // unit to re-select when selecting dummy
            
            set .buttons = .buttons + 1
            
            return Buttons[user.id][.buttons-1]
        endmethod

        method addBackground takes real x, real y, real sz, real w, real h, integer dumm /*integer texture :to personaliz texture:*/ returns UIPicture  
            //set Backgrounds[user.id][.backgrounds] = CreateWindow(BACKGROUND_X + x, BACKGROUND_Y + y, BACKGROUND_SIZE + sz, BACKGROUND_W + w, BACKGROUND_H + h, GetPlayerRace(user.handle))
            set Backgrounds[user.id][.backgrounds] = UIPicture.createEx(BACKGROUND_X + x, BACKGROUND_Y+ y , 2.00, BACKGROUND_SIZE + sz, dumm, BACKGROUND_W + w, BACKGROUND_H + h, Interface.getRaceBorders(RACE_NIGHTELF))

            set .backgrounds = .backgrounds + 1
            
            return Backgrounds[user.id][.backgrounds-1]
        endmethod

        method addText takes real x, real y, real z, string s, real size returns UIText
            set Texts[user.id][.texts] = UIText.createEx(.user.handle, x, y, z)
            call SetTextTagText(Texts[.user.id][.texts].text, s, size * 0.0023)

            set .texts = .texts + 1
            return Texts[user.id][.texts - 1]
        endmethod

        static method create takes User user, Camera cam returns thistype
            local thistype this = thistype.allocate()
            local integer i = 0
            
            set this.camera = cam
            set this.user = user
            set this.buttons = 0
            set this.backgrounds = 0
            set this.texts = 0

            // create only once per player 
            if (Backgrounds[user.id][0] == 0) then
            
                // create background
                //moved to addBackgroun, why? because was adding 2D array xD

                // create top background
                call this.addBackground(0.00, 0.00, 0.00, 0.00, 0.00, 'dwen')
                // create buttom background
                call this.addBackground(0.00, -1.00, 0.00, 0.00, 0.00, 'diag') 
                
                // create title
                //set Text[user.id] = UIText.createEx(user.handle, BACKGROUND_X + 0.15, BACKGROUND_Y, 1)
                //call SetTextTagText(Text[user.id].text, "Senior Rock Mercader ", 12 * 0.0023)
                //moved to addText AnymayxD
                call this.addText(BACKGROUND_X + 0.15, BACKGROUND_Y , 1.15, "Senior Rock Mercader", 11) 
                call this.addText(BACKGROUND_X + 0.20, BACKGROUND_Y - 1.05, 1.15, "Mensaje Del Dia", 10) 
                call this.addText(BACKGROUND_X + 0.02, BACKGROUND_Y - 1.35, 1.15, "Traes alguna botella de Tubby-Cola?\nMe encerre aqui y olvide de traer algunas...", 9) 

                
                // create double click detector (not officially supported)
                set DoubleClickButton[user.id] = this.addButton(BACKGROUND_X + 0.28, 0.24, 'B002')
                
                // create top button
                call this.addButton(BACKGROUND_X + 0.42, -0.55 + BACKGROUND_Y, 'B000') //(BACKGROUND_X + 0.28, 0.05, 'B000')
                
                // create bottom button
                call this.addButton(BACKGROUND_X + 0.13, -0.55 + BACKGROUND_Y, 'B001') //(BACKGROUND_X + 0.28, -0.15, 'B001')
   
            endif
            
            return this
        endmethod
        
        method show takes boolean flag returns nothing
            local integer i = this.user.id
            local integer n = 0
            local player p = this.user.handle
            
            // show only to one player for performance
            loop
                exitwhen n == .backgrounds
                call Backgrounds[i][n].showPlayer(p, flag, PlayerCamera[i])
                set n = n + 1
            endloop

            set n = 0
            loop
                exitwhen n == .texts
                call Texts[i][n].show(flag, PlayerCamera[i])
                set n = n + 1
            endloop

            set n = 0
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
            loop
                exitwhen n == .backgrounds
                call Backgrounds[i][n].update()
                set n = n + 1
            endloop

            set n = 0
            loop
                exitwhen n == .texts
                call Texts[i][n].update()
                set n = n + 1
            endloop 
            
            set n = 0
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
        
        //firs window
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
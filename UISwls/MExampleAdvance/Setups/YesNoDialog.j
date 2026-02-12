library YesNoDialog requires UserInterface

    globals
        dialog array Dialog
        private button array YesBtn
        private filterfunc array YesCallback
        player YesNoPlayer
    endglobals
    
    private function OnClick takes nothing returns nothing
        local User user = User.first
        local button btn = GetClickedButton()

        loop
            exitwhen user == User.NULL
            
            if (YesCallback[user.id] != null and YesBtn[user.id] == btn) then
                set YesNoPlayer = user.toPlayer()
                call UserInterface_Eval(YesCallback[user.id])
            endif
            
            set user = user.next 
        endloop
    endfunction
    
    private keyword INITS
    
    struct YesNoDialog extends array
        implement INITS
    endstruct
    
    function ShowYesNoDialog takes string title, User user, filterfunc callback returns nothing
        set YesCallback[user.id] = callback
        call DialogSetMessage(Dialog[user.id], title)
        call DialogDisplay(user.toPlayer(), Dialog[user.id], true)
    endfunction
    
    private module INITS
        private static method onInit takes nothing returns nothing
            local User user = User.first
            local trigger t = CreateTrigger()
            
            loop
                exitwhen user == User.NULL
                
                set YesCallback[user.id] = null
                set Dialog[user.id] = DialogCreate()
                set YesBtn[user.id] = DialogAddButton(Dialog[user.id], "Yes", 89)
                call DialogAddButton(Dialog[user.id], "No", 0)
                call TriggerRegisterDialogEvent(t, Dialog[user.id])
                set user = user.next 
            endloop
            
            call TriggerAddAction(t, function OnClick)
        endmethod
    endmodule
endlibrary

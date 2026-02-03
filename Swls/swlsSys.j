library Swls initializer Init /*

    */requires Table,/*
    */TimerUtils 

    struct Wave
        integer unitId
        integer count
        player owner

        static method create takes integer uId, integer amount, player p returns Wave
            local Wave this = Wave.allocate()

            set this.unitId = uId
            set this.count  = amount
            set this.owner  = p

            call this.spawn()

            return this
        endmethod

        method spawn takes nothing returns nothing
            local integer i = 0

            loop
                exitwhen i >= this.count
                call CreateUnit(this.owner, this.unitId, 0.0, 0.0, 270.0)
                set i = i + 1
            endloop
        endmethod
    endstruct

    private function Init takes nothing returns nothing
        // Ejemplo: 5 footmen para Player 1
        call Wave.create('hfoo', 5, Player(0))
    endfunction

endlibrary

library EquipmentCoreDesignCopy
/*
    Copia enfocada en DISENO (layout/UI) de EquipmentCore.
    - Se dejaron coordenadas, creacion de botones/pictures/texto y show visual.
    - Se comento la logica de gameplay (equipar/desequipar, validaciones, hooks de inventario, eventos).
    Motivo: separar "maquetado UI" de "reglas del sistema" para estudiar solo diseno.
*/

    globals
        /*
            LOGICA (comentada):
            Estos callbacks conectan clicks con acciones de inventario/equipamiento.
            No son necesarios para estudiar posicion y composicion visual.
        */
        // public filterfunc FuncLClickSlot = null
        // public filterfunc FuncRClickSlot = null
        // public integer array PlayerLastSlot

        // Config copiada de InventoryCore para evitar dependencia de Inventory.*
        private constant integer DESIGN_ICON_EMPTY       = 'dbnk'
        private constant integer DESIGN_ICON_TRANSPARENT = 'B00S'
        private constant integer DESIGN_RACE_BORDERS_START = 'D201'
    endglobals

    /*
        PERSONALIZACION:
        Dejo este callback base de click izquierdo para que agregues tus acciones.
        Se conecta a cada slot en create().
    */
    private function OnLeftClickCustom takes nothing returns boolean
        local UIButton btn = GetTriggerButton()
        local integer slot = btn.customValue
        local player p = GetClickingPlayer()

        // TODO: agrega aqui tu logica (abrir panel, tooltip, sonido, etc.)
        // Ejemplo: call BJDebugMsg("Click L slot " + I2S(slot) + " por " + GetPlayerName(p))

        set p = null
        return false
    endfunction

    // Version local de Inventory.localInt para mostrar solo al jugador local.
    private function DesignLocalInt takes integer pid, integer value, integer other returns integer
        if (User.Local != User(pid).handle) then
            set value = other
        endif
        return value
    endfunction

    // VISUAL: titulo que se pinta en la ventana del heroe
    public /*constant*/ function HERO_WINDOW_NAME takes unit u returns string
        return User[GetOwningPlayer(u)].nameColored
    endfunction

    struct EquipmentDesign
        //
        // DISENO (coordenadas y tamanos UI)
        //
        static constant real X = 0.425
        static constant real Y = .93

        static constant real WINDOW_SIZE = 0.28

        static constant real SLOT_OFFSET_Y          = 0.065
        static constant real SLOT_OFFSET_ROWRIGHT_X = 0.460
        static constant real SLOT_OFFSET_ROWLEFT_X  = 0.105

        static constant real HERO_NAME_Y = 0.9

        static constant real CHARMODEL_OFFSET_X  = X + 0.32
        static constant real CHARMODEL_OFFSET_Y  = 0.200

        static constant integer MAX_SLOTS = 14
        static constant real SLOT_WIDTH   = 0.090
        static constant real SLOT_HEIGHT  = 0.090 * SCREEN_ASPECT_RATIO

        static constant integer MODEL_DUMMY  = 'e000'
        static constant integer WINDOW_DUMMY = 'ewin'
        //
        // fin diseno
        //

        // VISUAL: componentes UI cacheados por jugador
        static UIButton array buttons[.MAX_SLOTS]
        static UIPicture array slotButton[.MAX_SLOTS]
        static UIPicture array pictures[.MAX_SLOTS]
        static UIPicture array selector
        static UIText array title

        /*
            GAMEPLAY (comentado):
            Estado de items, ids, eventos, lista activa y sincronizacion de sistemas.
            Todo esto controla reglas, no layout.
        */
        // InvItem array item[.MAX_SLOTS]
        // integer array itemId[.MAX_SLOTS]
        // static trigger onSocket
        // readonly static integer DisplayCount = 0
        // readonly static timer UpdateTimer
        // readonly static unit array PlayerCurrentUnit
        // readonly static thistype array UnitsIndex

        UIPicture charModel
        Camera camera
        unit unit
        player player
        User user

        method getButton takes integer index returns UIButton
            return this.buttons[(this.user.id * .MAX_SLOTS) + index]
        endmethod

        method setButton takes integer index, UIButton value returns nothing
            set this.buttons[(this.user.id * .MAX_SLOTS) + index] = value
        endmethod

        static method create takes unit u returns thistype
            local thistype this = thistype.allocate()
            local real x1 = X + SLOT_OFFSET_ROWLEFT_X
            local real x2 = X + SLOT_OFFSET_ROWRIGHT_X
            local real y1 = Y - SLOT_OFFSET_Y
            local integer i = 0

            set this.unit = u
            set this.player = GetOwningPlayer(u)
            set this.user = User[this.player]

            // VISUAL: crea slots y fondo solo una vez por jugador
            if (this.getButton(0) == 0) then
                set selector[this.user.id] = UIPicture.createEx(X - 0.15, (Y + SLOT_OFFSET_Y) - .250, 0, .70, 'e000', 1, 1, 0)
                set selector[this.user.id].animIndex = 56
                call selector[this.user.id].show(false, this.camera)
                call AddSpecialEffectTarget("UI\\TRSHerolevel.mdx", selector[this.user.id].picture, "origin")

                // centro
                call this.setButton(12, UIButton.create(x1 + (.SLOT_WIDTH*1.5), y1 - (.SLOT_HEIGHT*5), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B005'))
                call this.setButton(13, UIButton.create(x2 - (.SLOT_WIDTH*1.5), y1 - (.SLOT_HEIGHT*5), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B00B'))

                // izquierda
                call this.setButton(0, UIButton.create(x1, y1, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B003'))
                call this.setButton(1, UIButton.create(x1, y1 - (.SLOT_HEIGHT*1), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B004'))
                call this.setButton(2, UIButton.create(x1, y1 - (.SLOT_HEIGHT*2), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B006'))
                call this.setButton(3, UIButton.create(x1, y1 - (.SLOT_HEIGHT*3), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B007'))
                call this.setButton(4, UIButton.create(x1, y1 - (.SLOT_HEIGHT*4), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B008'))
                call this.setButton(5, UIButton.create(x1, y1 - (.SLOT_HEIGHT*5), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'D05W'))

                // derecha
                call this.setButton(6, UIButton.create(x2, y1, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B009'))
                call this.setButton(7, UIButton.create(x2, y1 - (.SLOT_HEIGHT*1), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B00A'))
                call this.setButton(8, UIButton.create(x2, y1 - (.SLOT_HEIGHT*2), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B00C'))
                call this.setButton(9, UIButton.create(x2, y1 - (.SLOT_HEIGHT*3), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B00D'))
                call this.setButton(10, UIButton.create(x2, y1 - (.SLOT_HEIGHT*4), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B00E'))
                call this.setButton(11, UIButton.create(x2, y1 - (.SLOT_HEIGHT*5), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'B00F'))

                loop
                    exitwhen i == 14

                    // VISUAL: icono superpuesto del slot (empty por defecto)
                    set this.slotButton[(this.user.id * MAX_SLOTS) + i] = UIPicture.create(this.getButton(i).minx + (.SLOT_WIDTH/6.3), this.getButton(i).maxy - 0.022, .SLOT_WIDTH * .7, .SLOT_HEIGHT * .7, 9, DESIGN_ICON_EMPTY)
                    set this.slotButton[(this.user.id * MAX_SLOTS) + i].customValue = i

                    /*
                        LOGICA (comentada):
                        selectUnit/onRightClick siguen comentados porque son gameplay.
                    */
                    set this.getButton(i).customValue = i
                    set this.getButton(i).onLeftClick = Filter(function OnLeftClickCustom)
                    // set this.getButton(i).selectUnit = this.unit
                    // set this.getButton(i).onRightClick = FuncRClickSlot

                    set i = i + 1
                endloop

                // VISUAL: marco principal de equipo
                set .pictures[(this.user.id * MAX_SLOTS) + 0] = UIPicture.createEx(X, Y, 11, WINDOW_SIZE, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, DESIGN_RACE_BORDERS_START + (GetHandleId(GetPlayerRace(this.player)) - 1), DESIGN_ICON_TRANSPARENT))
            endif

            // VISUAL: retrato/modelo del personaje
            set i = EquipGetHeroModel(GetUnitTypeId(this.unit))
            set .charModel = UIPicture.createEx(CHARMODEL_OFFSET_X, .CHARMODEL_OFFSET_Y, 5, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charModel.animIndex = 140
            call SetUnitColor(.charModel.picture, this.user.color)
            call AddSpecialEffectTarget(HeroModelData(i).path, .charModel.picture, "origin")

            // VISUAL: texto del nombre
            set .title[this.user.id] = UIText.createEx(this.user.toPlayer(), X/1.4, 0.1, 1)

            return this
        endmethod

        method show takes boolean flag, Camera cam returns nothing
            local integer i = 0

            set this.camera = cam

            call this.charModel.showPlayer(this.user.toPlayer(), flag, this.camera)
            call SetUnitColor(.charModel.picture, this.user.color)
            call .title[this.user.id].setPosition(X + 0.10, HERO_NAME_Y)
            call SetTextTagText(.title[this.user.id].text, HERO_WINDOW_NAME(this.unit), 8 * 0.0023)
            call this.title[this.user.id].show(flag, this.camera)

            loop
                exitwhen i == thistype.MAX_SLOTS

                if (.getButton(i) != 0) then
                    call .getButton(i).showPlayer(this.user.handle, flag, this.camera)
                endif

                if (this.pictures[(this.user.id * .MAX_SLOTS) + i] != 0) then
                    call .pictures[(this.user.id * .MAX_SLOTS) + i].showPlayer(this.user.handle, flag, this.camera)
                endif

                /*
                    LOGICA (comentada):
                    En original se muestran iconos solo si hay item equipado.
                    Aqui podria mostrarse siempre para estudiar solo composicion.
                */
                if (this.slotButton[(this.user.id * .MAX_SLOTS) + i] != 0) then
                    call slotButton[(this.user.id * .MAX_SLOTS) + i].showPlayer(this.user.handle, flag, this.camera)
                endif

                set i = i + 1
            endloop
        endmethod

        /*
            GAMEPLAY (comentado intencionalmente):
            - equip
            - unequip
            - onDisplay (timer/camera runtime)
            - destroy/listas enlazadas
            Todo eso pertenece a logica de inventario/equipo y eventos.
        */
    endstruct

    private function Init takes nothing returns nothing
        /*
            LOGICA (comentada):
            Hooks entre Inventory y Equipment para clicks y acciones.
            No son necesarios para practicar diseno de UI.
        */
        // set FuncLClickSlot = Filter(function LClickItemSlot)
        // set FuncRClickSlot = Filter(function RClickItemSlot)
        // call Inventory.addLeftClickHook(function OnInventoryItemClick)
        // call Inventory.addRightClickHook(function OnInventoryItemRightClick)
    endfunction

endlibrary

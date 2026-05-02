library MenuClient initializer Init requires UserInterface,EquipHeroModels,PlayerMissileLoadout,WeaponProfileConfig,WeaponSelectionSystem,TimerUtils,WaveTest,TenderSystem,PreConfi,EnemyPreviewConfig,PlayerHeroState // requires InventoryCore, EquipmentItem

globals
    public filterfunc FuncLClickSlot = null
    public filterfunc FuncRClickSlot = null
    public integer array PlayerLastSlot
    public UIButton array PlayerLastButton
    private string array WaveStatusText
    private effect array WaveEnemyPreviewFx
    private integer array WaveEnemyPreviewWaveId
    private string array WaveEnemyPreviewModelPath
    private real array PlayerMenuCameraHeight
    private real array PlayerMenuCameraOffset
    private real array PlayerMenuFogAppliedHeight
    private integer array PlayerMenuSelectedShopWeapon
    private integer array PlayerMenuRenderedShopWeapon
    private string array PlayerMenuClickText
    public boolean array PlayerMenuShowShop
    public boolean array PlayerMenuShowTree
    public boolean array PlayerMenuShowEnemies
endglobals

    public /*constant*/ function HERO_WINDOW_NAME takes unit u returns string
        return User[GetOwningPlayer(u)].nameColored
        // return GetHeroProperName(u)
    endfunction

    // Version local de Inventory.localInt para mostrar solo al jugador local.
    private function DesignLocalInt takes integer pid, integer value, integer other returns integer
        if (User.Local != User(pid).handle) then
            set value = other
        endif
        return value
    endfunction

    private function GetDefaultMenuCameraHeight takes nothing returns real
        return 500.
    endfunction

    private function GetDefaultMenuCameraOffset takes nothing returns real
        return 467.
    endfunction

    private function GetMinMenuCameraHeight takes nothing returns real
        return 500.
    endfunction

    private function GetMaxMenuCameraHeight takes nothing returns real
        return 4000.
    endfunction

    private function GetMenuCameraHeightStep takes nothing returns real
        return 500.
    endfunction

    private function GetMenuCameraOffsetForHeight takes real height returns real
        return GetDefaultMenuCameraOffset() + ((height - GetDefaultMenuCameraHeight())/1000.)*667.
    endfunction

    private function GetMenuCameraFogEnd takes real height returns real
        return 3500. + (height - GetDefaultMenuCameraHeight())*1.75
    endfunction

    private function ApplyMenuCameraFog takes player p, real height returns nothing
        if User.Local == p then
            call SetTerrainFogExBJ(0, 0.00, GetMenuCameraFogEnd(height), 0.00, 24.00, 24.00, 24.00)
        endif
    endfunction

    private function ResetMenuCameraFog takes player p returns nothing
        if User.Local == p then
            call ResetTerrainFogBJ()
        endif
    endfunction

    private function EnsureMenuCameraSettings takes integer pid returns nothing
        if PlayerMenuCameraHeight[pid] < GetMinMenuCameraHeight() then
            set PlayerMenuCameraHeight[pid] = GetDefaultMenuCameraHeight()
            set PlayerMenuCameraOffset[pid] = GetDefaultMenuCameraOffset()
        endif
    endfunction

    private function StepMenuCameraHeight takes integer pid, real delta returns nothing
        local real nextHeight
        call EnsureMenuCameraSettings(pid)
        set nextHeight = PlayerMenuCameraHeight[pid] + delta
        if nextHeight > GetMaxMenuCameraHeight() then
            set nextHeight = GetMinMenuCameraHeight()
        elseif nextHeight < GetMinMenuCameraHeight() then
            set nextHeight = GetMaxMenuCameraHeight()
        endif
        set PlayerMenuCameraHeight[pid] = nextHeight
        set PlayerMenuCameraOffset[pid] = GetMenuCameraOffsetForHeight(nextHeight)
    endfunction

    struct Client
        //
        // configuration
        //
        static constant real X = -0.32//0.425
        static constant real Y = .99

        static constant real WINDOW_SIZE = 0.21

        static constant real SLOT_OFFSET_Y          = 0.065
        static constant real SLOT_OFFSET_ROWRIGHT_X = 0.460
        static constant real SLOT_OFFSET_ROWLEFT_X  = 0.105

        static constant real HERO_NAME_Y = 0.86
        static constant real HERO_NAME_X = 0.28

        static constant real CHARMODEL_OFFSET_X  = X + 0.32
        static constant real CHARMODEL_OFFSET_Y  = 0.200

        static constant integer MAX_SLOTS = 50
        static constant integer MUTATION_SLOT_INSTANCE = 0
        static constant integer MUTATION_SLOT_CAMERA_UP = 2
        static constant integer MUTATION_SLOT_DAMAGE = 3
        static constant integer MUTATION_SLOT_REGEN = 4
        static constant integer MUTATION_SLOT_SMART_RECAST = 5
        static constant integer MUTATION_SLOT_ORB_LEVEL = 6
        static constant integer MUTATION_SLOT_CAMERA_DOWN = 7
        static constant integer MUTATION_SLOT_UNUSED = 8
        static constant integer SHOP_SLOT_PISTOL = 9
        static constant integer SHOP_SLOT_SHOTGUN = 10
        static constant integer HUB_SLOT_SHOP = 11
        static constant integer HUB_SLOT_UPGRADES = 12
        static constant integer HUB_SLOT_INTEL = 13
        static constant integer SHOP_SLOT_ASSAULT = 14
        static constant integer SHOP_SLOT_RIFLE = 15
        static constant integer SHOP_SLOT_PLASMA = 16
        static constant integer SHOP_SLOT_TRACKER = 17
        static constant integer SHOP_DETAIL_TITLE_TEXT = 14
        static constant integer SHOP_DETAIL_BODY_TEXT = 15
        static constant integer SHOP_DETAIL_BUY_TEXT = 16
        static constant integer SHOP_DETAIL_TREE_TEXT = 17
        static constant integer SHOP_DETAIL_ICON_PICTURE = 17
        static constant integer SHOP_DETAIL_BUY_BUTTON = 18
        static constant integer SHOP_DETAIL_TREE_BUTTON = 19
        static constant integer SHOP_SLOT_ANKH = 20
        static constant integer SHOP_SLOT_WATER = 21
        static constant integer SHOP_SLOT_WIND = 22
        static constant integer SHOP_SLOT_BLOOD = 23
        static constant integer SHOP_SLOT_POISON = 24
        static constant integer SHOP_SLOT_FIRE = 25
        static constant integer SHOP_SLOT_FROST = 26
        static constant integer SHOP_SLOT_RAY = 27
        static constant integer SHOP_SLOT_DARK = 28
        static constant integer SHOP_SLOT_HEAD = 29
        static constant integer SHOP_SLOT_ARMS = 30
        static constant integer SHOP_SLOT_CHEST = 31
        static constant integer SHOP_SLOT_LEGS = 32
        static constant integer SHOP_ITEM_NONE = 0
        static constant integer SHOP_ITEM_PISTOL = 1
        static constant integer SHOP_ITEM_SHOTGUN = 2
        static constant integer SHOP_ITEM_ASSAULT = 3
        static constant integer SHOP_ITEM_RIFLE = 4
        static constant integer SHOP_ITEM_PLASMA = 5
        static constant integer SHOP_ITEM_TRACKER = 6
        static constant integer SHOP_ITEM_ANKH = 7
        static constant integer SHOP_ITEM_WATER = 8
        static constant integer SHOP_ITEM_WIND = 9
        static constant integer SHOP_ITEM_BLOOD = 10
        static constant integer SHOP_ITEM_POISON = 11
        static constant integer SHOP_ITEM_FIRE = 12
        static constant integer SHOP_ITEM_FROST = 13
        static constant integer SHOP_ITEM_RAY = 14
        static constant integer SHOP_ITEM_DARK = 15
        static constant integer SHOP_ITEM_HEAD = 16
        static constant integer SHOP_ITEM_ARMS = 17
        static constant integer SHOP_ITEM_CHEST = 18
        static constant integer SHOP_ITEM_LEGS = 19
        static constant integer PANEL_HEADER_TEXT = 0
        static constant integer LEGACY_MESSAGE_TEXT = 1
        static constant integer LEGACY_SOURCE_TEXT = 2
        static constant integer MUTATION_INSTANCE_TEXT = 3
        static constant integer LEGACY_LOGO_TEXT = 4
        static constant integer MUTATION_REGEN_TEXT = 5
        static constant integer MUTATION_DAMAGE_TEXT = 6
        static constant integer MUTATION_ENEMY_DETAIL_TEXT = 7
        static constant integer MUTATION_ORB_TEXT = 8
        static constant integer HUB_WELCOME_TEXT = 9
        static constant integer HUB_WAVE_STATUS_TEXT = 10
        static constant integer HUB_LABEL_SHOP_TEXT = 11
        static constant integer HUB_LABEL_UPGRADES_TEXT = 12
        static constant integer HUB_LABEL_INTEL_TEXT = 13
        static constant integer SHOP_LABEL_PISTOL_TEXT = 21
        static constant integer SHOP_LABEL_SHOTGUN_TEXT = 22
        static constant integer SHOP_LABEL_ASSAULT_TEXT = 23
        static constant integer SHOP_LABEL_RIFLE_TEXT = 24
        static constant integer SHOP_LABEL_PLASMA_TEXT = 25
        static constant integer SHOP_LABEL_TRACKER_TEXT = 26
        static constant integer SHOP_LABEL_ANKH_TEXT = 27
        static constant integer SHOP_LABEL_WATER_TEXT = 28
        static constant integer SHOP_LABEL_WIND_TEXT = 29
        static constant integer SHOP_LABEL_BLOOD_TEXT = 30
        static constant integer SHOP_LABEL_POISON_TEXT = 31
        static constant integer SHOP_LABEL_FIRE_TEXT = 32
        static constant integer SHOP_LABEL_FROST_TEXT = 33
        static constant integer SHOP_LABEL_RAY_TEXT = 34
        static constant integer SHOP_LABEL_DARK_TEXT = 35
        static constant integer SHOP_LABEL_HEAD_TEXT = 36
        static constant integer SHOP_LABEL_ARMS_TEXT = 37
        static constant integer SHOP_LABEL_CHEST_TEXT = 38
        static constant integer SHOP_LABEL_LEGS_TEXT = 39
        static constant integer MUTATION_PICTURE_FIRST = 0
        static constant integer MUTATION_PICTURE_LAST = 7
        static constant integer MUTATION_BACKGROUND_PICTURE = 0
        static constant integer MUTATION_SOURCE_PICTURE = 1
        static constant integer MUTATION_CENTER_PANEL_PICTURE = 2
        static constant integer MUTATION_CENTER_FRAME_PICTURE = 3
        static constant integer MUTATION_LEFT_PANEL_PICTURE = 4
        static constant integer MUTATION_FAR_LEFT_PANEL_PICTURE = 5
        static constant integer MUTATION_RIGHT_PANEL_PICTURE = 6
        static constant integer MUTATION_FAR_RIGHT_PANEL_PICTURE = 7
        static constant integer HUB_BACKGROUND_PICTURE = 8
        static constant integer SHOP_PANEL_GRID_PICTURE = 9
        static constant integer SHOP_PANEL_DETAIL_PICTURE = 10
        static constant integer SHOP_PANEL_FIRST_PICTURE = SHOP_PANEL_GRID_PICTURE
        static constant integer SHOP_PANEL_LAST_PICTURE = SHOP_DETAIL_ICON_PICTURE
        static constant integer MUTATION_ORB_MODEL_COUNT = 4
        static constant real HUB_Y_OFFSET = -0.22
        static constant integer HUB_TOOLTIP_PICTURE = 40
        static constant integer HUB_TOOLTIP_TEXT = 40
        static constant integer HUB_TOOLTIP_BACKGROUND = 'ttip'
        static constant integer HUB_TOOLTIP_TEXTURE = 'B014'
        static constant real HUB_TOOLTIP_X = X + HERO_NAME_X + 0.90
        static constant real HUB_TOOLTIP_Y = HERO_NAME_Y - 1.35 + HUB_Y_OFFSET
        static constant real SLOT_WIDTH   = 0.095
        static constant real SLOT_HEIGHT  = 0.095 * SCREEN_ASPECT_RATIO

        static constant integer MODEL_DUMMY  = 'e000' // for character model
        static constant integer WINDOW_DUMMY = 'ewin'
        //
        // end config
        //

        readonly static boolean Initialized = false
        readonly static integer DisplayCount = 0
        readonly static hashtable Hashtable
        readonly static timer UpdateTimer
        readonly static unit array PlayerCurrentUnit
        readonly static thistype array UnitsIndex

        static UIButton array buttons[.MAX_SLOTS] //
        static UIPicture array slotButton[.MAX_SLOTS] //
        //InvItem array item[.MAX_SLOTS]
        integer array itemId[.MAX_SLOTS]
        static UIPicture array pictures[.MAX_SLOTS] //
        static UIPicture array selector //
        static UIText array title[.MAX_SLOTS] //
        static trigger onSocket

        UIPicture charModel
        UIPicture charModel2
        UIPicture array charMOrb[.MAX_SLOTS]
        effect array chain[.MAX_SLOTS]
        Camera camera

        unit unit
        player player
        User user

        readonly boolean displayed
        readonly thistype next
        readonly thistype prev

        static method operator [] takes unit u returns thistype
            return .UnitsIndex[GetUnitUserData(u)]
        endmethod

        method getButton takes integer index returns UIButton
            return this.buttons[(this.user.id * .MAX_SLOTS) + index]
        endmethod

        method getPicture takes integer index returns UIButton
            return this.pictures[(this.user.id * .MAX_SLOTS) + index]
        endmethod

        method setButton takes integer index, UIButton value returns nothing
            set this.buttons[(this.user.id * .MAX_SLOTS) + index] = value
        endmethod

        static method getShopItemIndexFromSlot takes integer slot returns integer
            if slot == thistype.SHOP_SLOT_PISTOL then
                return thistype.SHOP_ITEM_PISTOL
            elseif slot == thistype.SHOP_SLOT_SHOTGUN then
                return thistype.SHOP_ITEM_SHOTGUN
            elseif slot == thistype.SHOP_SLOT_ASSAULT then
                return thistype.SHOP_ITEM_ASSAULT
            elseif slot == thistype.SHOP_SLOT_RIFLE then
                return thistype.SHOP_ITEM_RIFLE
            elseif slot == thistype.SHOP_SLOT_PLASMA then
                return thistype.SHOP_ITEM_PLASMA
            elseif slot == thistype.SHOP_SLOT_TRACKER then
                return thistype.SHOP_ITEM_TRACKER
            elseif slot == thistype.SHOP_SLOT_ANKH then
                return thistype.SHOP_ITEM_ANKH
            elseif slot == thistype.SHOP_SLOT_WATER then
                return thistype.SHOP_ITEM_WATER
            elseif slot == thistype.SHOP_SLOT_WIND then
                return thistype.SHOP_ITEM_WIND
            elseif slot == thistype.SHOP_SLOT_BLOOD then
                return thistype.SHOP_ITEM_BLOOD
            elseif slot == thistype.SHOP_SLOT_POISON then
                return thistype.SHOP_ITEM_POISON
            elseif slot == thistype.SHOP_SLOT_FIRE then
                return thistype.SHOP_ITEM_FIRE
            elseif slot == thistype.SHOP_SLOT_FROST then
                return thistype.SHOP_ITEM_FROST
            elseif slot == thistype.SHOP_SLOT_RAY then
                return thistype.SHOP_ITEM_RAY
            elseif slot == thistype.SHOP_SLOT_DARK then
                return thistype.SHOP_ITEM_DARK
            elseif slot == thistype.SHOP_SLOT_HEAD then
                return thistype.SHOP_ITEM_HEAD
            elseif slot == thistype.SHOP_SLOT_ARMS then
                return thistype.SHOP_ITEM_ARMS
            elseif slot == thistype.SHOP_SLOT_CHEST then
                return thistype.SHOP_ITEM_CHEST
            elseif slot == thistype.SHOP_SLOT_LEGS then
                return thistype.SHOP_ITEM_LEGS
            endif
            return thistype.SHOP_ITEM_NONE
        endmethod

        static method getShopItemTexture takes integer itemIndex returns integer
            if WeaponProfileIsWeapon(itemIndex) then
                return WeaponProfileGetTexture(itemIndex)
            elseif itemIndex == thistype.SHOP_ITEM_ANKH then
                return 'MI01'
            elseif itemIndex == thistype.SHOP_ITEM_WATER then
                return 'MO01'
            elseif itemIndex == thistype.SHOP_ITEM_WIND then
                return 'MO02'
            elseif itemIndex == thistype.SHOP_ITEM_BLOOD then
                return 'MO03'
            elseif itemIndex == thistype.SHOP_ITEM_POISON then
                return 'MO04'
            elseif itemIndex == thistype.SHOP_ITEM_FIRE then
                return 'MO05'
            elseif itemIndex == thistype.SHOP_ITEM_FROST then
                return 'MO06'
            elseif itemIndex == thistype.SHOP_ITEM_RAY then
                return 'MO07'
            elseif itemIndex == thistype.SHOP_ITEM_DARK then
                return 'MO08'
            elseif itemIndex == thistype.SHOP_ITEM_HEAD then
                return 'MAR1'
            elseif itemIndex == thistype.SHOP_ITEM_ARMS then
                return 'MAR2'
            elseif itemIndex == thistype.SHOP_ITEM_CHEST then
                return 'MAR3'
            elseif itemIndex == thistype.SHOP_ITEM_LEGS then
                return 'MAR4'
            endif
            return 'MA01'
        endmethod

        static method getShopItemName takes integer itemIndex returns string
            if WeaponProfileIsWeapon(itemIndex) then
                return WeaponProfileGetName(itemIndex)
            elseif itemIndex == thistype.SHOP_ITEM_ANKH then
                return "Ankh de vida"
            elseif itemIndex == thistype.SHOP_ITEM_WATER then
                return "Orbe Water"
            elseif itemIndex == thistype.SHOP_ITEM_WIND then
                return "Orbe Wind"
            elseif itemIndex == thistype.SHOP_ITEM_BLOOD then
                return "Orbe Blood"
            elseif itemIndex == thistype.SHOP_ITEM_POISON then
                return "Orbe Poison"
            elseif itemIndex == thistype.SHOP_ITEM_FIRE then
                return "Orbe Fire"
            elseif itemIndex == thistype.SHOP_ITEM_FROST then
                return "Orbe Frost"
            elseif itemIndex == thistype.SHOP_ITEM_RAY then
                return "Orbe Rayo"
            elseif itemIndex == thistype.SHOP_ITEM_DARK then
                return "Orbe Dark"
            elseif itemIndex == thistype.SHOP_ITEM_HEAD then
                return "Mejora Head"
            elseif itemIndex == thistype.SHOP_ITEM_ARMS then
                return "Mejora Arms"
            elseif itemIndex == thistype.SHOP_ITEM_CHEST then
                return "Mejora Chest"
            elseif itemIndex == thistype.SHOP_ITEM_LEGS then
                return "Mejora Legs"
            endif
            return "Item de tienda"
        endmethod

        private static method getShopItemDetail takes integer itemIndex returns string
            if WeaponProfileIsWeapon(itemIndex) then
                return WeaponProfileGetDetailText(itemIndex)
            elseif itemIndex == thistype.SHOP_ITEM_ANKH then
                return "|cff99ccffTipo: Supervivencia|r\nEfecto: |cffffcc00+1 vida|r\nCosto: |cffffcc00Pendiente|r\n\nAl comprarlo aumenta en 1\nla vida disponible del\njugador que lo compra."
            elseif itemIndex == thistype.SHOP_ITEM_WATER then
                return "|cff99ccffTipo: Orbe Water|r\nEfecto: |cffffcc00Rebote|r\nEscala: por instancia\n\nPermite que el proyectil\nrebote contra unidades,\ncolisiones y cliffs."
            elseif itemIndex == thistype.SHOP_ITEM_WIND then
                return "|cff99ccffTipo: Orbe Wind|r\nEfecto: |cffffcc00Area mayor|r\nEscala: por instancia\n\nAmplia el impacto y ayuda\na limpiar grupos compactos.\nControl de oleadas puro."
            elseif itemIndex == thistype.SHOP_ITEM_BLOOD then
                return "|cff99ccffTipo: Orbe Blood|r\nEfecto: |cffffcc00Critico/ejecucion|r\nEscala: por instancia\n\nCastiga enemigos heridos\ny premia focusear objetivos\ncon poca vida."
            elseif itemIndex == thistype.SHOP_ITEM_POISON then
                return "|cff99ccffTipo: Orbe Poison|r\nEfecto: |cffffcc00Dano periodico|r\nEscala: por instancia\n\nAplica veneno despues del\nimpacto. Muy fuerte contra\nenemigos resistentes."
            elseif itemIndex == thistype.SHOP_ITEM_FIRE then
                return "|cff99ccffTipo: Orbe Fire|r\nEfecto: |cffffcc00Dano extra|r\nEscala: por instancia\n\nPotencia el impacto directo\ny mantiene identidad de\nproyectil agresivo."
            elseif itemIndex == thistype.SHOP_ITEM_FROST then
                return "|cff99ccffTipo: Orbe Frost|r\nEfecto: |cffffcc00Debilidad|r\nEscala: porcentaje por instancia\n\nLa unidad afectada recibe\nmas dano de cualquier\nfuente de misil."
            elseif itemIndex == thistype.SHOP_ITEM_RAY then
                return "|cff99ccffTipo: Orbe Rayo|r\nEfecto: |cffffcc00Perforacion/cadena|r\nEscala: por instancia\n\nPermite extender impactos\ny presionar varias unidades\nen una misma linea."
            elseif itemIndex == thistype.SHOP_ITEM_DARK then
                return "|cff99ccffTipo: Orbe Dark|r\nEfecto: |cffffcc00Dano faltante|r\nEscala: por instancia\n\nAumenta castigo contra\nobjetivos debilitados.\nIdeal para rematar."
            elseif itemIndex == thistype.SHOP_ITEM_HEAD then
                return "|cff99ccffParte: Head|r\nRuta: |cffffcc00Vision / sensor|r\n\nMejoras orientadas a lectura\nde combate: informacion,\ndeteccion y control tactico."
            elseif itemIndex == thistype.SHOP_ITEM_ARMS then
                return "|cff99ccffParte: Arms|r\nRuta: |cffffcc00Armas / manejo|r\n\nMejoras para dano, cadencia,\nprecision y eficiencia de\narmas equipadas."
            elseif itemIndex == thistype.SHOP_ITEM_CHEST then
                return "|cff99ccffParte: Chest|r\nRuta: |cffffcc00Defensa / nucleo|r\n\nReduce dano recibido, mejora\nresistencia y sostiene al\nheroe en waves largas."
            elseif itemIndex == thistype.SHOP_ITEM_LEGS then
                return "|cff99ccffParte: Legs|r\nRuta: |cffffcc00Movimiento|r\n\nMejora movilidad, move cast,\nreposicionamiento y control\ndel espacio."
            endif
            return "|cff999999Selecciona un item para ver sus datos.|r"
        endmethod

        private static method getWaveStatusText takes integer userId returns string
            if WaveStatusText[userId] == null or WaveStatusText[userId] == "" then
                return "Wave"
            endif
            return WaveStatusText[userId]
        endmethod

        private method destroyEnemyPreviewFx takes nothing returns nothing
            if WaveEnemyPreviewFx[this.user.id] != null then
                call DestroyEffect(WaveEnemyPreviewFx[this.user.id])
                set WaveEnemyPreviewFx[this.user.id] = null
            endif
            set WaveEnemyPreviewWaveId[this.user.id] = 0
            set WaveEnemyPreviewModelPath[this.user.id] = ""
        endmethod

        method setEnemyPreviewWave takes integer waveId returns nothing
            local string modelPath
            local string previewText
            local real previewScale
            local boolean createFx
            set modelPath = EnemyPreviewGetModelPath(waveId)
            set previewText = EnemyPreviewGetText(waveId)
            set previewScale = EnemyPreviewGetModelScale(waveId)
            if this.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_ENEMY_DETAIL_TEXT] != 0 then
                call SetTextTagText(this.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_ENEMY_DETAIL_TEXT].text, previewText, 8 * 0.0020)
            endif
            if this.charModel != 0 then
                call SetUnitScale(this.charModel.picture, previewScale, previewScale, previewScale)
                set createFx = false
                if modelPath == "" then
                    call this.destroyEnemyPreviewFx()
                elseif WaveEnemyPreviewFx[this.user.id] == null then
                    set createFx = true
                elseif WaveEnemyPreviewWaveId[this.user.id] != waveId then
                    call this.destroyEnemyPreviewFx()
                    set createFx = true
                elseif WaveEnemyPreviewModelPath[this.user.id] != modelPath then
                    call this.destroyEnemyPreviewFx()
                    set createFx = true
                endif
                if createFx then
                    set WaveEnemyPreviewFx[this.user.id] = AddSpecialEffectTarget(modelPath, this.charModel.picture, "origin")
                    set WaveEnemyPreviewWaveId[this.user.id] = waveId
                    set WaveEnemyPreviewModelPath[this.user.id] = modelPath
                endif
            endif
        endmethod

        method clearEnemyPreview takes nothing returns nothing
            call this.destroyEnemyPreviewFx()
        endmethod

        method setWaveStatusTitle takes string value returns nothing
            if value == null or value == "" then
                set WaveStatusText[this.user.id] = "Wave"
            else
                set WaveStatusText[this.user.id] = value
            endif
            if this.title[(this.user.id * MAX_SLOTS) + thistype.HUB_WAVE_STATUS_TEXT] != 0 then
                call SetTextTagText(this.title[(this.user.id * MAX_SLOTS) + thistype.HUB_WAVE_STATUS_TEXT].text, thistype.getWaveStatusText(this.user.id), 8 * 0.0027)
            endif
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
            if WaveStatusText[this.user.id] == null or WaveStatusText[this.user.id] == "" then
                set WaveStatusText[this.user.id] = "Wave"
            endif

            set .UnitsIndex[GetUnitUserData(u)] = this

            //
            // GEAR SLOTS
            //

            if (this.getButton(thistype.MUTATION_SLOT_INSTANCE) == 0) then

                set selector[this.user.id] = UIPicture.createEx(X - 0.15, (Y + SLOT_OFFSET_Y) - .250, 0, .70, 'e000', 1, 1, 0)
                set selector[this.user.id].animIndex = 56
                call selector[this.user.id].show(false, this.camera)

                call AddSpecialEffectTarget("UI\\TRSHerolevel.mdx", selector[this.user.id].picture, "origin")

                // middle
                call this.setButton(thistype.MUTATION_SLOT_INSTANCE, UIButton.create(x1 + (.SLOT_WIDTH*0.75)+1.00+0.1, y1 - (.SLOT_HEIGHT*5)-0.15, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00D'))

                // Slot 1 era el boton viejo para abrir/cerrar Tender.
                // Ahora el Tender se abre con ESC desde TenderEscInteraction.

                call this.setButton(thistype.MUTATION_SLOT_CAMERA_UP, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.00, y1 - (.SLOT_HEIGHT*5)+1.05, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00G'))

                call this.setButton(thistype.MUTATION_SLOT_DAMAGE, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.00+0.1, y1 - (.SLOT_HEIGHT*5)-0.15, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00D')) // intev shot

                call this.setButton(thistype.MUTATION_SLOT_REGEN, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.50+0.1, y1 - (.SLOT_HEIGHT*5)-0.15, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00D')) // intev large

                call this.setButton(thistype.MUTATION_SLOT_SMART_RECAST, UIButton.create(x1 + (.SLOT_WIDTH*0.75)+0.00+0.1, y1 - (.SLOT_HEIGHT*5)-0.15, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00D')) // grade shot

                call this.setButton(thistype.MUTATION_SLOT_ORB_LEVEL, UIButton.create(x1 + (.SLOT_WIDTH*0.75)+0.50+0.1, y1 - (.SLOT_HEIGHT*5)-0.15, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00D')) // lvlup orb

                call this.setButton(thistype.MUTATION_SLOT_CAMERA_DOWN, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.10, y1 - (.SLOT_HEIGHT*5)+1.05, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00H'))

                call this.setButton(thistype.MUTATION_SLOT_UNUSED, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.90, y1 - (.SLOT_HEIGHT*5)+1.05, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00I'))
                call this.setButton(thistype.HUB_SLOT_SHOP, UIButton.create(X + HERO_NAME_X - 0.34, HERO_NAME_Y - 1.33 + thistype.HUB_Y_OFFSET, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00B'))
                call this.setButton(thistype.HUB_SLOT_UPGRADES, UIButton.create(X + HERO_NAME_X - 0.02, HERO_NAME_Y - 1.33 + thistype.HUB_Y_OFFSET, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00H'))
                call this.setButton(thistype.HUB_SLOT_INTEL, UIButton.create(X + HERO_NAME_X + 0.30, HERO_NAME_Y - 1.33 + thistype.HUB_Y_OFFSET, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00G'))
                //call this.setButton(thistype.MUTATION_SLOT_CAMERA_DOWN, UIButton.create(x1 + (.SLOT_WIDTH*0.75)+1.00, y1 - (.SLOT_HEIGHT*5)-0.20, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00F')) // int
                call this.setButton(thistype.SHOP_SLOT_PISTOL, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.00+.10, y1 - (.SLOT_HEIGHT*5)+0.95-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MA01'))
                call this.setButton(thistype.SHOP_SLOT_SHOTGUN, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.80+.10, y1 - (.SLOT_HEIGHT*5)+0.95-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MA02'))
                call this.setButton(thistype.SHOP_SLOT_ASSAULT, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.60+.10, y1 - (.SLOT_HEIGHT*5)+0.95-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MA03'))
                call this.setButton(thistype.SHOP_SLOT_RIFLE, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.40+.10, y1 - (.SLOT_HEIGHT*5)+0.95-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MA04'))
                call this.setButton(thistype.SHOP_SLOT_PLASMA, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.20+.10, y1 - (.SLOT_HEIGHT*5)+0.95-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MA06'))
                call this.setButton(thistype.SHOP_SLOT_TRACKER, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.00+.10, y1 - (.SLOT_HEIGHT*5)+0.95-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MA05'))
                call this.setButton(thistype.SHOP_DETAIL_BUY_BUTTON, UIButton.create(X + HERO_NAME_X + 0.82, HERO_NAME_Y - 1.09, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00B'))
                call this.setButton(thistype.SHOP_DETAIL_TREE_BUTTON, UIButton.create(X + HERO_NAME_X + 1.14, HERO_NAME_Y - 1.09, .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00H'))

                call this.setButton(thistype.SHOP_SLOT_ANKH, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.00+.10, y1 - (.SLOT_HEIGHT*5)+0.15-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MI01')) //Ankh

                call this.setButton(thistype.SHOP_SLOT_WATER, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.00+.10, y1 - (.SLOT_HEIGHT*5)+0.55-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MO01')) //water
                call this.setButton(thistype.SHOP_SLOT_WIND, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.85+.10, y1 - (.SLOT_HEIGHT*5)+0.55-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MO02')) //wind
                call this.setButton(thistype.SHOP_SLOT_BLOOD, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.70+.10, y1 - (.SLOT_HEIGHT*5)+0.55-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MO03')) //blood
                call this.setButton(thistype.SHOP_SLOT_POISON, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.55+.10, y1 - (.SLOT_HEIGHT*5)+0.55-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MO04')) //poison
                call this.setButton(thistype.SHOP_SLOT_FIRE, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.40+.10, y1 - (.SLOT_HEIGHT*5)+0.55-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MO05')) //fire
                call this.setButton(thistype.SHOP_SLOT_FROST, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.25+.10, y1 - (.SLOT_HEIGHT*5)+0.55-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MO06')) //frost
                call this.setButton(thistype.SHOP_SLOT_RAY, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.10+.10, y1 - (.SLOT_HEIGHT*5)+0.55-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MO07')) //lightning
                call this.setButton(thistype.SHOP_SLOT_DARK, UIButton.create(x1 + (.SLOT_WIDTH*0.75)+0.05+.10, y1 - (.SLOT_HEIGHT*5)+0.55-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MO08')) //darkness

                call this.setButton(thistype.SHOP_SLOT_HEAD, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-1.00+.10, y1 - (.SLOT_HEIGHT*5)-0.25-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MAR1')) //head
                call this.setButton(thistype.SHOP_SLOT_ARMS, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.85+.10, y1 - (.SLOT_HEIGHT*5)-0.25-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MAR2')) //arms
                call this.setButton(thistype.SHOP_SLOT_CHEST, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.70+.10, y1 - (.SLOT_HEIGHT*5)-0.25-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MAR3')) //chest
                call this.setButton(thistype.SHOP_SLOT_LEGS, UIButton.create(x1 + (.SLOT_WIDTH*0.75)-0.55+.10, y1 - (.SLOT_HEIGHT*5)-0.25-.1, .SLOT_WIDTH, .SLOT_HEIGHT, 2, 'MAR4')) //legs
                /*
                call this.setButton(thistype.MUTATION_SLOT_CAMERA_UP, UIButton.create(x2 - (.SLOT_WIDTH*2.00), y1 - (.SLOT_HEIGHT*5), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))

                call this.setButton(thistype.MUTATION_SLOT_DAMAGE, UIButton.create(x2 - (.SLOT_WIDTH*12), y1 + (.SLOT_HEIGHT*0.4), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(thistype.MUTATION_SLOT_REGEN, UIButton.create(x2 + (.SLOT_WIDTH*8), y1 + (.SLOT_HEIGHT*0.4), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(thistype.MUTATION_SLOT_SMART_RECAST, UIButton.create(x2 - (.SLOT_WIDTH*12), y1 - (.SLOT_HEIGHT*5.1), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(thistype.MUTATION_SLOT_ORB_LEVEL, UIButton.create(x2 + (.SLOT_WIDTH*8), y1 - (.SLOT_HEIGHT*5.1), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))

                call this.setButton(thistype.MUTATION_SLOT_CAMERA_DOWN, UIButton.create(x2 - (.SLOT_WIDTH*12), y1 + (.SLOT_HEIGHT*-4), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(thistype.MUTATION_SLOT_UNUSED, UIButton.create(x2 + (.SLOT_WIDTH*8), y1 + (.SLOT_HEIGHT*-4), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(thistype.SHOP_SLOT_PISTOL, UIButton.create(x2 - (.SLOT_WIDTH*12), y1 - (.SLOT_HEIGHT*9.6), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                call this.setButton(thistype.SHOP_SLOT_SHOTGUN, UIButton.create(x2 + (.SLOT_WIDTH*8), y1 - (.SLOT_HEIGHT*9.6), .SLOT_WIDTH, .SLOT_HEIGHT, 10, 'M00A'))
                */

                loop
                    exitwhen i == thistype.MAX_SLOTS // numero de botones siempre + 1, and charge too Max_SLOTS
                    if this.getButton(i) != 0 then
                        set this.getButton(i).customValue = i
                        set this.getButton(i).selectUnit = this.unit
                        set this.getButton(i).onLeftClick = FuncLClickSlot
                        set this.getButton(i).onRightClick = FuncRClickSlot
                        set this.slotButton[(this.user.id * MAX_SLOTS) + i] = UIPicture.create(this.getButton(i).minx + (.SLOT_WIDTH/6.3), this.getButton(i).maxy - 0.022, .SLOT_WIDTH * .7, .SLOT_HEIGHT * .7, 9, 'dbnk')
                        set this.slotButton[(this.user.id * MAX_SLOTS) + i].customValue = i
                    endif

                    set i = i + 1
                endloop

                set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_BACKGROUND_PICTURE] = UIPicture.createEx(X+0.03, Y-0.30, 11, WINDOW_SIZE+0.04, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))

                set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_SOURCE_PICTURE] = UIPicture.createEx(X+0.15, Y - 1.46, 11, WINDOW_SIZE-0.04, 'lewn', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))

                /*
     /*left*/   set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_CENTER_PANEL_PICTURE] = UIPicture.createEx(X - 0.90, Y + 0.10, 11, WINDOW_SIZE, 'bwn2', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
    /*right*/   set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_CENTER_FRAME_PICTURE] = UIPicture.createEx(X + 0.90, Y + 0.10, 11, WINDOW_SIZE, 'bwn2', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
   /*left*/     set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_LEFT_PANEL_PICTURE] = UIPicture.createEx(X - 0.90, Y - 0.80, 11, WINDOW_SIZE, 'bwn2', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
  /*right*/     set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_FAR_LEFT_PANEL_PICTURE] = UIPicture.createEx(X + 0.90, Y - 0.80, 11, WINDOW_SIZE, 'bwn2', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                */
                set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_CENTER_PANEL_PICTURE] = UIPicture.createEx(X - 0.23 , Y - 0.98-.46, 2, WINDOW_SIZE-0.05, 'pwin', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_CENTER_FRAME_PICTURE] = UIPicture.createEx(X - 0.24 , Y - 0.98-.46, 11, WINDOW_SIZE + .03-.06, 'pwif', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))

                set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_LEFT_PANEL_PICTURE] = UIPicture.createEx(X-.5+.03, Y-0.30, 11, WINDOW_SIZE+0.04, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_FAR_LEFT_PANEL_PICTURE] = UIPicture.createEx(X-1.+.03, Y-0.30, 11, WINDOW_SIZE+0.04, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_RIGHT_PANEL_PICTURE] = UIPicture.createEx(X+.5+.03, Y-0.30, 11, WINDOW_SIZE+0.04, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                set .pictures[(this.user.id * MAX_SLOTS) + thistype.MUTATION_FAR_RIGHT_PANEL_PICTURE] = UIPicture.createEx(X+1.+.03, Y-0.30, 11, WINDOW_SIZE+0.04, .WINDOW_DUMMY, 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                set .pictures[(this.user.id * MAX_SLOTS) + thistype.HUB_BACKGROUND_PICTURE] = UIPicture.createEx(X + HERO_NAME_X - 0.10, HERO_NAME_Y - 1.15 + thistype.HUB_Y_OFFSET, 11, WINDOW_SIZE-0.06, 'lewn', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))

                set .pictures[(this.user.id * MAX_SLOTS) + thistype.SHOP_PANEL_GRID_PICTURE] = UIPicture.createEx(X + HERO_NAME_X - 1.00, HERO_NAME_Y + 0.55, 11, 0.60, 'lwin', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))
                set .pictures[(this.user.id * MAX_SLOTS) + thistype.SHOP_PANEL_DETAIL_PICTURE] = UIPicture.createEx(X + HERO_NAME_X + 0.50, HERO_NAME_Y + 0.15, 11, 0.40, 'ewin', 140., 130., DesignLocalInt(this.user.id, 'D201' +(GetHandleId(GetPlayerRace(this.player))-1), 'B00S'))

                set .pictures[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_ICON_PICTURE] = UIPicture.create(X + HERO_NAME_X + 0.91, HERO_NAME_Y - 0.08, .SLOT_WIDTH * 1.45, .SLOT_HEIGHT * 1.45, 2, 'MA01')
                set .pictures[(this.user.id * MAX_SLOTS) + thistype.HUB_TOOLTIP_PICTURE] = UIPicture.createEx(thistype.HUB_TOOLTIP_X+.015, thistype.HUB_TOOLTIP_Y+.07, 11, 0.065, thistype.HUB_TOOLTIP_BACKGROUND, 140., 130., DesignLocalInt(this.user.id, thistype.HUB_TOOLTIP_TEXTURE, 'B00S'))
            endif

            // enemy preview model slot (reused from the old charModel slot)
            set .charModel = UIPicture.createEx(CHARMODEL_OFFSET_X+0.00, .CHARMODEL_OFFSET_Y-0.15, 5, 0.11, MODEL_DUMMY, 1, 1, 0)
            set .charModel.animIndex = 140
            call SetUnitColor(.charModel.picture, this.user.color)
            //2
            set i = EquipGetHeroModel('hhou')
            set .charModel2 = UIPicture.createEx(CHARMODEL_OFFSET_X+0.03-1.117+0.744, .CHARMODEL_OFFSET_Y - 0.97-.063, 6, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charModel2.animIndex = 140
            call SetUnitColor(.charModel2.picture, this.user.color) //0.03-1.117+0.734

            call AddSpecialEffectTarget(HeroModelData(i).path, .charModel2.picture, "origin")

            set i = EquipGetHeroModel(GetPlayerMissileAbilityChoice(.player))
            set .charMOrb[0] = UIPicture.createEx(CHARMODEL_OFFSET_X-.5+.0, .CHARMODEL_OFFSET_Y - 0.20, 6, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charMOrb[0].animIndex = 140
            call SetUnitColor(.charMOrb[0].picture, this.user.color)
            call AddSpecialEffectTarget(HeroModelData(i).path, .charMOrb[0].picture, "origin")

            set .charMOrb[1] = UIPicture.createEx(CHARMODEL_OFFSET_X-1.+.0, .CHARMODEL_OFFSET_Y - 0.20, 6, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charMOrb[1].animIndex = 140
            call SetUnitColor(.charMOrb[1].picture, this.user.color)
            call AddSpecialEffectTarget(HeroModelData(i).path, .charMOrb[1].picture, "origin")

            set .charMOrb[2] = UIPicture.createEx(CHARMODEL_OFFSET_X+.5+.0, .CHARMODEL_OFFSET_Y - 0.20, 6, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charMOrb[2].animIndex = 140
            call SetUnitColor(.charMOrb[2].picture, this.user.color)
            call AddSpecialEffectTarget(HeroModelData(i).path, .charMOrb[2].picture, "origin")

            set .charMOrb[3] = UIPicture.createEx(CHARMODEL_OFFSET_X+1.+.0, .CHARMODEL_OFFSET_Y - 0.20, 6, HeroModelData(i).scale, MODEL_DUMMY, 1, 1, 0)
            set .charMOrb[3].animIndex = 140
            call SetUnitColor(.charMOrb[3].picture, this.user.color)
            call AddSpecialEffectTarget(HeroModelData(i).path, .charMOrb[3].picture, "origin")

            /*
            call .pictures[(this.user.id * .MAX_SLOTS) + thistype.LEGACY_MESSAGE_TEXT].showPlayer(this.user.handle, true, this.camera)
            call .pictures[(this.user.id * .MAX_SLOTS) + thistype.LEGACY_SOURCE_TEXT].showPlayer(this.user.handle, true, this.camera)
            call .pictures[(this.user.id * .MAX_SLOTS) + thistype.MUTATION_INSTANCE_TEXT].showPlayer(this.user.handle, true, this.camera)
            */
            call this.charMOrb[0].showPlayer(this.user.toPlayer(), false, this.camera)
            call this.charMOrb[1].showPlayer(this.user.toPlayer(), false, this.camera)
            call this.charMOrb[2].showPlayer(this.user.toPlayer(), false, this.camera)
            call this.charMOrb[3].showPlayer(this.user.toPlayer(), false, this.camera)
            call this.charModel.showPlayer(this.user.toPlayer(), false, this.camera)


            /*
            set i = 0
            loop
                exitwhen i == 3 // numero de botones siempre + 1, and charge too Max_SLOTS

                set i = i + 1
            endloop
            */
            //set .title[this.user.id] = UIText.createEx(this.user.toPlayer(), X/1.4, 0.1, 1)

            set .title[(this.user.id * MAX_SLOTS) + thistype.PANEL_HEADER_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.4, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_MESSAGE_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.9, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_SOURCE_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.9, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_INSTANCE_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_LOGO_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            //set .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_REGEN_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_REGEN_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_DAMAGE_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_ENEMY_DETAIL_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_ORB_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.HUB_WELCOME_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.HUB_WAVE_STATUS_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_SHOP_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_UPGRADES_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_INTEL_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_TITLE_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_BODY_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_BUY_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_TREE_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_PISTOL_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_SHOTGUN_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ASSAULT_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_RIFLE_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_PLASMA_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_TRACKER_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ANKH_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_WATER_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_WIND_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_BLOOD_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_POISON_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_FIRE_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_FROST_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_RAY_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_DARK_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_HEAD_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ARMS_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_CHEST_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_LEGS_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)
            set .title[(this.user.id * MAX_SLOTS) + thistype.HUB_TOOLTIP_TEXT] = UIText.createEx(this.user.toPlayer(), X/1.7, 0.1, 1)


            set thistype(0).next.prev = this
            set this.next = thistype(0).next
            set thistype(0).next = this

            set this.prev = 0

            return this
        endmethod

        /* Solo logica de equipamiento jeje guardadita
        method equip takes InvItem itm, integer equipSlot returns boolean
            local integer slot = itm.slot - 1

            if (slot < 0) then
                return false
            endif

            if (this.item[equipSlot] != 0) then
                return false
            endif

            if (itm.slotAlt - 1 > 0) then
                if (equipSlot != slot and equipSlot != itm.slotAlt -1) then
                    call Inventory.err(this.player, "The item doesn't belong in that slot.")
                    return false
                endif
            else
                if (equipSlot != slot) then
                    call Inventory.err(this.player, "The item doesn't belong in that slot.")
                    return false
                endif
            endif

            if (itm.reqUnitType > 0 and GetUnitTypeId(this.unit) != itm.reqUnitType) then
                call Inventory.err(this.player, "Your unit type cannot equip this item.")
                return false
            endif

            if (itm.reqAbility > 0 and GetUnitAbilityLevel(this.unit, itm.reqAbility) < 0) then
                call Inventory.err(this.player, "Failed requirements.")
                return false
            endif

            if (GetHeroLevel(this.unit) < itm.reqLevel and GetUnitLevel(this.unit) < itm.reqLevel) then
                call Inventory.err(this.player, "Your level is too low to equip that item.")
                return false
            endif

            if (itm.equipCondition != null) then
                call TriggerClearConditions(InvItem.equipEval)
                call TriggerAddCondition(InvItem.equipEval, itm.equipCondition)
                set InvItem.eventUnit = this.unit
                if (not TriggerEvaluate(InvItem.equipEval)) then
                    return false
                endif
            endif

            set slot = equipSlot

            if (this.item[slot] != 0) then
                return false
            endif

            if (itm.equipAbility > 0) then
                call UnitAddAbility(this.unit, itm.equipAbility)
            endif

            set this.item[slot] = itm
            set this.itemId[slot] = itm.tempCustomId

            call this.slotButton[(this.user.id * .MAX_SLOTS) + slot].setTexture(Inventory.localInt(this.user.id, itm.icon, Inventory.ICON_TRANSPARENT))
            call this.slotButton[(this.user.id * .MAX_SLOTS) + slot].show(true, this.camera)

            set InvEventPlayer = this.player
            set InvEventItem = itm
            set InvEventSlot = equipSlot

            if (InvItem.onEquip != null and TriggerEvaluate(InvItem.onEquip)) then
                call TriggerExecute(InvItem.onEquip)
            endif

            // add bonuses
            call itm.applyBonuses(this.unit)

            set itm.tempCustomId = 0

            return true
        endmethod */

        /* EL par de la otra cosita dksalj
        method unequip takes InvItem itm, integer slot returns boolean
            local InvItem i2
            local integer i = 0
            local integer cid = itm.tempCustomId

            if (slot != itm.slot -1 and slot != itm.slotAlt - 1) then
                return false
            endif

            if (itm.equipAbility > 0) then
                call UnitRemoveAbility(this.unit, itm.equipAbility)
            endif

            // run unequip event
            set InvEventPlayer = this.player
            set InvEventItem = this.item[slot]
            set InvEventSlot = slot

            if (InvItem.onUnequip != null and TriggerEvaluate(InvItem.onUnequip)) then
                call TriggerExecute(InvItem.onUnequip)
            endif

            set this.item[slot] = 0

            call this.slotButton[(this.user.id * .MAX_SLOTS) + slot].setTexture(Inventory.ICON_EMPTY)
            call this.slotButton[(this.user.id * .MAX_SLOTS) + slot].show(false, this.camera)

            // remove bonuses
            call itm.removeBonuses(this.unit)

            return true
        endmethod */

        method destroy takes nothing returns nothing
            set this.next.prev = this.prev
            set this.prev.next = this.next

            call this.clearEnemyPreview()
            if this.charModel != 0 then
                call this.charModel.destroy()
            endif
            call this.charModel2.destroy()

            call this.deallocate()
        endmethod

        private static method onDisplay takes nothing returns nothing
            local User user = User(User.LocalId)
            local thistype equipment = Client[Client.PlayerCurrentUnit[user.id]]
            local real x
            local real y
            local real z
                                                            //para doble interfaz y evitar doble cam y sa wea xDD
            if (equipment == 0 or not equipment.displayed /*or Inventory.PlayerCurrent[equipment.user.id] > 0*/ or User.Local != user.handle) then
                return
            endif
            /*
            equipment == 0
            No hay instancia de equipo activa para ese jugador.

            not equipment.displayed
            La UI de equipo está oculta.

            Inventory.PlayerCurrent[equipment.user.id] > 0
            Hay inventario activo para ese jugador (evita conflicto entre paneles).

            User.Local != user.handle
            No es el cliente local que debe renderizar esa cámara/UI.
            */

            set x = GetUnitX(equipment.unit)
            set y = GetUnitY(equipment.unit)
            call EnsureMenuCameraSettings(user.id)
            if PlayerMenuFogAppliedHeight[user.id] != PlayerMenuCameraHeight[user.id] then
                call ApplyMenuCameraFog(user.handle, PlayerMenuCameraHeight[user.id])
                set PlayerMenuFogAppliedHeight[user.id] = PlayerMenuCameraHeight[user.id]
            endif
            set z = GetTerrainZ(x, y) + PlayerMenuCameraHeight[user.id] + GetUnitDefaultFlyHeight(equipment.unit)
            call equipment.camera.setPosition(x, y - PlayerMenuCameraOffset[user.id], z)

            if equipment.camera.applyCameraForPlayer(user.handle, false) then
                call Interface.updateAll(true, true, true)
            endif
        endmethod

        private method isTenderPanelVisible takes nothing returns boolean
            return this.displayed and isTender[this.user.id]
        endmethod

        private method isShopPanelVisible takes nothing returns boolean
            return this.displayed and isTender[this.user.id] and PlayerMenuShowShop[this.user.id]
        endmethod

        private method isMutationPanelVisible takes nothing returns boolean
            // La interfaz antigua de 5 cuadros/modelos queda reservada para Mutacion.
            // Se activara luego cuando exista su propio boton/flujo.
            return false
        endmethod

        private method isTreePanelVisible takes nothing returns boolean
            return this.displayed and isTender[this.user.id] and PlayerMenuShowTree[this.user.id]
        endmethod

        private method isEnemiesPanelVisible takes nothing returns boolean
            return this.displayed and isTender[this.user.id] and PlayerMenuShowEnemies[this.user.id]
        endmethod

        private static method isShopButtonSlot takes integer slot returns boolean
            return thistype.getShopItemIndexFromSlot(slot) > 0 or slot == thistype.SHOP_DETAIL_BUY_BUTTON or slot == thistype.SHOP_DETAIL_TREE_BUTTON
        endmethod

        private static method isHubButtonSlot takes integer slot returns boolean
            return slot == thistype.HUB_SLOT_SHOP or slot == thistype.HUB_SLOT_UPGRADES or slot == thistype.HUB_SLOT_INTEL
        endmethod

        private static method isAlwaysVisibleButtonSlot takes integer slot returns boolean
            return slot == thistype.MUTATION_SLOT_CAMERA_UP or slot == thistype.MUTATION_SLOT_CAMERA_DOWN
        endmethod

        private static method isMutationUpgradeButtonSlot takes integer slot returns boolean
            return slot == thistype.MUTATION_SLOT_INSTANCE or slot == thistype.MUTATION_SLOT_DAMAGE or slot == thistype.MUTATION_SLOT_REGEN or slot == thistype.MUTATION_SLOT_ORB_LEVEL
        endmethod

        private method shouldShowButton takes integer slot returns boolean
            if not this.displayed then
                return false
            endif

            if thistype.isAlwaysVisibleButtonSlot(slot) then
                return true
            endif

            if thistype.isHubButtonSlot(slot) then
                return isTender[this.user.id]
            endif

            if thistype.isMutationUpgradeButtonSlot(slot) then
                return this.isMutationPanelVisible()
            endif

            if thistype.isShopButtonSlot(slot) then
                return this.isShopPanelVisible()
            endif

            return false
        endmethod

        private method applyButtonVisibility takes nothing returns nothing
            local integer i = 0
            loop
                exitwhen i == thistype.MAX_SLOTS
                if this.getButton(i) != 0 then
                    call this.getButton(i).showPlayer(this.user.handle, this.shouldShowButton(i), this.camera)
                endif
                set i = i + 1
            endloop

        endmethod

        private method applyTitleLayout takes nothing returns nothing
            call .title[(this.user.id * MAX_SLOTS) + thistype.PANEL_HEADER_TEXT].setPosition(X + HERO_NAME_X-0.12, HERO_NAME_Y-.28)
            call .title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_MESSAGE_TEXT].setPosition(X + HERO_NAME_X-.27-0.12+.18, HERO_NAME_Y-1.73)
            call .title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_SOURCE_TEXT].setPosition(X + HERO_NAME_X+.01-0.54+.18, HERO_NAME_Y-1.80)
            call .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_INSTANCE_TEXT].setPosition(X + HERO_NAME_X+0.95, HERO_NAME_Y-0.85)
            call .title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_LOGO_TEXT].setPosition(X + HERO_NAME_X+1.4, HERO_NAME_Y-0.85)
            call .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_REGEN_TEXT].setPosition(X + HERO_NAME_X-0.55, HERO_NAME_Y-0.85)
            call .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_DAMAGE_TEXT].setPosition(X + HERO_NAME_X-1.05, HERO_NAME_Y-0.85)
            call .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_ENEMY_DETAIL_TEXT].setPosition(X + HERO_NAME_X-0.12, HERO_NAME_Y-1.05)
            call .title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_ORB_TEXT].setPosition(X + HERO_NAME_X+0.45, HERO_NAME_Y-0.85)
            call .title[(this.user.id * MAX_SLOTS) + thistype.HUB_WELCOME_TEXT].setPosition(X + HERO_NAME_X-0.14, HERO_NAME_Y+0.08)
            call .title[(this.user.id * MAX_SLOTS) + thistype.HUB_WAVE_STATUS_TEXT].setPosition(X + HERO_NAME_X-0.0, HERO_NAME_Y+0.22)
            call .title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_SHOP_TEXT].setPosition(this.getButton(thistype.HUB_SLOT_SHOP).centerx - 0.035, this.getButton(thistype.HUB_SLOT_SHOP).centery - 0.150)
            call .title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_UPGRADES_TEXT].setPosition(this.getButton(thistype.HUB_SLOT_UPGRADES).centerx - 0.055, this.getButton(thistype.HUB_SLOT_UPGRADES).centery - 0.150)
            call .title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_INTEL_TEXT].setPosition(this.getButton(thistype.HUB_SLOT_INTEL).centerx - 0.030, this.getButton(thistype.HUB_SLOT_INTEL).centery - 0.150)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_TITLE_TEXT].setPosition(X + HERO_NAME_X + 0.86, HERO_NAME_Y - 0.05)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_BODY_TEXT].setPosition(X + HERO_NAME_X + 0.68, HERO_NAME_Y - 0.80)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_BUY_TEXT].setPosition(this.getButton(thistype.SHOP_DETAIL_BUY_BUTTON).centerx - 0.045, this.getButton(thistype.SHOP_DETAIL_BUY_BUTTON).centery - 0.130)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_TREE_TEXT].setPosition(this.getButton(thistype.SHOP_DETAIL_TREE_BUTTON).centerx - 0.042, this.getButton(thistype.SHOP_DETAIL_TREE_BUTTON).centery - 0.130)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_PISTOL_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_PISTOL).centerx - 0.038, this.getButton(thistype.SHOP_SLOT_PISTOL).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_SHOTGUN_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_SHOTGUN).centerx - 0.045, this.getButton(thistype.SHOP_SLOT_SHOTGUN).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ASSAULT_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_ASSAULT).centerx - 0.065, this.getButton(thistype.SHOP_SLOT_ASSAULT).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_RIFLE_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_RIFLE).centerx - 0.028, this.getButton(thistype.SHOP_SLOT_RIFLE).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_PLASMA_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_PLASMA).centerx - 0.038, this.getButton(thistype.SHOP_SLOT_PLASMA).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_TRACKER_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_TRACKER).centerx - 0.035, this.getButton(thistype.SHOP_SLOT_TRACKER).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ANKH_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_ANKH).centerx - 0.028, this.getButton(thistype.SHOP_SLOT_ANKH).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_WATER_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_WATER).centerx - 0.030, this.getButton(thistype.SHOP_SLOT_WATER).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_WIND_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_WIND).centerx - 0.025, this.getButton(thistype.SHOP_SLOT_WIND).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_BLOOD_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_BLOOD).centerx - 0.028, this.getButton(thistype.SHOP_SLOT_BLOOD).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_POISON_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_POISON).centerx - 0.030, this.getButton(thistype.SHOP_SLOT_POISON).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_FIRE_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_FIRE).centerx - 0.022, this.getButton(thistype.SHOP_SLOT_FIRE).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_FROST_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_FROST).centerx - 0.026, this.getButton(thistype.SHOP_SLOT_FROST).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_RAY_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_RAY).centerx - 0.020, this.getButton(thistype.SHOP_SLOT_RAY).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_DARK_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_DARK).centerx - 0.024, this.getButton(thistype.SHOP_SLOT_DARK).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_HEAD_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_HEAD).centerx - 0.024, this.getButton(thistype.SHOP_SLOT_HEAD).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ARMS_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_ARMS).centerx - 0.024, this.getButton(thistype.SHOP_SLOT_ARMS).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_CHEST_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_CHEST).centerx - 0.028, this.getButton(thistype.SHOP_SLOT_CHEST).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_LEGS_TEXT].setPosition(this.getButton(thistype.SHOP_SLOT_LEGS).centerx - 0.022, this.getButton(thistype.SHOP_SLOT_LEGS).centery - 0.148)
            call .title[(this.user.id * MAX_SLOTS) + thistype.HUB_TOOLTIP_TEXT].setPosition(thistype.HUB_TOOLTIP_X - 0.135, thistype.HUB_TOOLTIP_Y - 0.125)
        endmethod

        private method applyTitleText takes nothing returns nothing
            local integer selectedItem = PlayerMenuSelectedShopWeapon[this.user.id]
            if selectedItem <= 0 then
                set selectedItem = thistype.SHOP_ITEM_PISTOL
            endif
            if PlayerMenuShowTree[this.user.id] then
                call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.PANEL_HEADER_TEXT].text, "|cff00ccffARBOL DE MEJORAS|r\nAqui vas a disenar nodos, ramas y upgrades.", 8 * 0.0020)
            elseif PlayerMenuShowEnemies[this.user.id] then
                call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.PANEL_HEADER_TEXT].text, "|cff99ff99INTEL DE ENEMIGOS|r\nAqui vas a disenar enemigos, bosses y detalles.", 8 * 0.0020)
            else
                call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.PANEL_HEADER_TEXT].text, "NextEnemyInformation", 8 * 0.0023)
            endif
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_MESSAGE_TEXT].text, Message, 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_SOURCE_TEXT].text, "Fuente", 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_INSTANCE_TEXT].text, "Improve Instance\nNumer instancia: "+ I2S(GetPlayerMissileInstanceCount(this.user.toPlayer())), 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_LOGO_TEXT].text, "|cffff6a00L|cffff7400O|cffff7e00R|cffff8800D|cffff9200S|cffff6a00 E|cffff7400N|cffff7e00G|cffff8800I|cffff9200N|cffff9c00E|cffffa600S|r", 8 * 0.0025)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_REGEN_TEXT].text, "Improve RegeShot\nReg impact en: "+ R2S(GetPlayerMissileHealOnHit(this.user.toPlayer())), 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_DAMAGE_TEXT].text, "Improve Damage\nBase Dmg en: "+ R2S(GetPlayerMissileDamageValue(this.user.toPlayer())), 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_ENEMY_DETAIL_TEXT].text, EnemyPreviewGetText(TargetWave), 8 * 0.0018)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_ORB_TEXT].text, "Improve OrbLevel\nMax4, OrbLevel: "+ I2S(GetPlayerOrbLevel(this.user.toPlayer())), 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.HUB_WELCOME_TEXT].text, "Welcome To LordsEngines", 8 * 0.0027)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.HUB_WAVE_STATUS_TEXT].text, thistype.getWaveStatusText(this.user.id), 8 * 0.0027)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_SHOP_TEXT].text, "|cffffcc00Tienda|r", 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_UPGRADES_TEXT].text, "|cff00ccffMejoras|r", 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_INTEL_TEXT].text, "|cff99ff99Intel|r", 8 * 0.0020)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_TITLE_TEXT].text, "|cffffcc00" + thistype.getShopItemName(selectedItem) + "|r", 8 * 0.0027)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_BODY_TEXT].text, thistype.getShopItemDetail(selectedItem), 8 * 0.00175)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_BUY_TEXT].text, "|cffffcc00Comprar|r", 8 * 0.0018)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_TREE_TEXT].text, "|cff00ccffMejorar|r", 8 * 0.0018)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_PISTOL_TEXT].text, "|cffffcc00Pistola|r", 8 * 0.00135)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_SHOTGUN_TEXT].text, "|cffffcc00Escopeta|r", 8 * 0.00135)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ASSAULT_TEXT].text, "|cffffcc00Asalto|r", 8 * 0.00135)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_RIFLE_TEXT].text, "|cffffcc00Rifle|r", 8 * 0.00135)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_PLASMA_TEXT].text, "|cffffcc00Plasma|r", 8 * 0.00135)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_TRACKER_TEXT].text, "|cffffcc00Misil|r", 8 * 0.00135)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ANKH_TEXT].text, "|cffffcc00Ankh|r", 8 * 0.00125)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_WATER_TEXT].text, "|cff66ccffWater|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_WIND_TEXT].text, "|cff99ff99Wind|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_BLOOD_TEXT].text, "|cffff6666Blood|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_POISON_TEXT].text, "|cff99ff66Venom|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_FIRE_TEXT].text, "|cffff9933Fire|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_FROST_TEXT].text, "|cff99ddffFrost|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_RAY_TEXT].text, "|cffccffffRayo|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_DARK_TEXT].text, "|cffcc99ffDark|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_HEAD_TEXT].text, "|cffffcc00Head|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ARMS_TEXT].text, "|cffffcc00Arms|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_CHEST_TEXT].text, "|cffffcc00Chest|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_LEGS_TEXT].text, "|cffffcc00Legs|r", 8 * 0.00120)
            call SetTextTagText(.title[(this.user.id * MAX_SLOTS) + thistype.HUB_TOOLTIP_TEXT].text, PlayerMenuClickText[this.user.id], 8 * 0.00165)
            if PlayerMenuRenderedShopWeapon[this.user.id] != selectedItem and .pictures[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_ICON_PICTURE] != 0 then
                call .pictures[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_ICON_PICTURE].setTexture(thistype.getShopItemTexture(selectedItem))
                set PlayerMenuRenderedShopWeapon[this.user.id] = selectedItem
            endif
        endmethod

        private method applyTitleVisibility takes nothing returns nothing
            local boolean tenderVisible = this.isTenderPanelVisible()
            local boolean mutationVisible = this.isMutationPanelVisible()
            local boolean shopVisible = this.isShopPanelVisible()
            local boolean treeVisible = this.isTreePanelVisible()
            local boolean enemiesVisible = this.isEnemiesPanelVisible()
            call this.title[(this.user.id * MAX_SLOTS) + thistype.PANEL_HEADER_TEXT].show(treeVisible or enemiesVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_MESSAGE_TEXT].show(false, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_SOURCE_TEXT].show(false, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_INSTANCE_TEXT].show(mutationVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.LEGACY_LOGO_TEXT].show(false, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_REGEN_TEXT].show(mutationVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_DAMAGE_TEXT].show(mutationVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_ENEMY_DETAIL_TEXT].show(false, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.MUTATION_ORB_TEXT].show(mutationVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.HUB_WELCOME_TEXT].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.HUB_WAVE_STATUS_TEXT].show(this.displayed, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_SHOP_TEXT].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_UPGRADES_TEXT].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.HUB_LABEL_INTEL_TEXT].show(tenderVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_TITLE_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_BODY_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_BUY_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_DETAIL_TREE_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_PISTOL_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_SHOTGUN_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ASSAULT_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_RIFLE_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_PLASMA_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_TRACKER_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ANKH_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_WATER_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_WIND_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_BLOOD_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_POISON_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_FIRE_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_FROST_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_RAY_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_DARK_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_HEAD_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_ARMS_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_CHEST_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.SHOP_LABEL_LEGS_TEXT].show(shopVisible, this.camera)
            call this.title[(this.user.id * MAX_SLOTS) + thistype.HUB_TOOLTIP_TEXT].show(tenderVisible, this.camera)
        endmethod

        private method applyPictureVisibility takes nothing returns nothing
            local integer i = 0
            local boolean mutationVisible = this.isMutationPanelVisible()
            local boolean tenderVisible = this.isTenderPanelVisible()
            local boolean shopVisible = this.isShopPanelVisible()
            loop
                exitwhen i > thistype.MUTATION_PICTURE_LAST
                if .pictures[(this.user.id * .MAX_SLOTS) + i] != 0 then
                    call .pictures[(this.user.id * .MAX_SLOTS) + i].showPlayer(this.user.handle, mutationVisible, this.camera)
                endif
                set i = i + 1
            endloop
            if .pictures[(this.user.id * .MAX_SLOTS) + thistype.HUB_BACKGROUND_PICTURE] != 0 then
                call .pictures[(this.user.id * .MAX_SLOTS) + thistype.HUB_BACKGROUND_PICTURE].showPlayer(this.user.handle, tenderVisible, this.camera)
            endif

            set i = thistype.SHOP_PANEL_FIRST_PICTURE
            loop
                exitwhen i > thistype.SHOP_PANEL_LAST_PICTURE
                if .pictures[(this.user.id * .MAX_SLOTS) + i] != 0 then
                    call .pictures[(this.user.id * .MAX_SLOTS) + i].showPlayer(this.user.handle, shopVisible, this.camera)
                endif
                set i = i + 1
            endloop
            if .pictures[(this.user.id * .MAX_SLOTS) + thistype.HUB_TOOLTIP_PICTURE] != 0 then
                call .pictures[(this.user.id * .MAX_SLOTS) + thistype.HUB_TOOLTIP_PICTURE].showPlayer(this.user.handle, tenderVisible, this.camera)
            endif
        endmethod

        private method applyModelVisibility takes nothing returns nothing
            local integer i = 0
            local boolean mutationVisible = this.isMutationPanelVisible()
            call SetUnitColor(.charModel.picture, this.user.color)
            call SetUnitColor(.charModel2.picture, this.user.color)
            call this.charModel2.showPlayer(this.user.toPlayer(), mutationVisible, this.camera)
            call this.charModel.showPlayer(this.user.toPlayer(), mutationVisible, this.camera)
            loop
                exitwhen i == thistype.MUTATION_ORB_MODEL_COUNT
                call this.charMOrb[i].showPlayer(this.user.toPlayer(), mutationVisible, this.camera)
                set i = i + 1
            endloop
        endmethod

        private method applyVisualState takes nothing returns nothing
            call this.applyTitleLayout()
            call this.applyTitleText()
            call this.applyTitleVisibility()
            call this.applyPictureVisibility()
            call this.applyModelVisibility()
            call this.applyButtonVisibility()
            if not this.displayed and selector[this.user.id] != 0 then
                call selector[this.user.id].showPlayer(this.user.handle, false, this.camera)
                set PlayerLastSlot[this.user.id] = 0
                set PlayerLastButton[this.user.id] = 0
            endif
        endmethod

        method show takes boolean flag, Camera cam returns nothing
            local thistype equip = 0
            local boolean wasDisplayed = this.displayed

            set this.camera = cam

            if (flag) then
                if not wasDisplayed then
                    set .DisplayCount = .DisplayCount + 1
                    if (DisplayCount >= 1) then
                        call PauseTimer(.UpdateTimer)
                        call TimerStart(.UpdateTimer, 0.01, true, function thistype.onDisplay)
                    endif
                endif

                if (.PlayerCurrentUnit[this.user.id] != null) then
                    set equip = Client[.PlayerCurrentUnit[this.user.id]]
                endif

                if (.PlayerCurrentUnit[this.user.id] != null and .PlayerCurrentUnit[this.user.id] != this.unit and equip != this) then
                    call equip.show(false, this.camera)
                endif

                set .PlayerCurrentUnit[this.user.id] = this.unit
            elseif wasDisplayed then
                if .DisplayCount > 0 then
                    set .DisplayCount = .DisplayCount - 1
                endif
                if .PlayerCurrentUnit[this.user.id] == this.unit then
                    set .PlayerCurrentUnit[this.user.id] = null
                endif

                if (DisplayCount == 0) then
                    call PauseTimer(.UpdateTimer)
                else
                    call PauseTimer(.UpdateTimer)
                    call TimerStart(.UpdateTimer, 0.03125, true, function thistype.onDisplay)
                endif
                if (User.Local == this.player) then
                    call ResetMenuCameraFog(this.player)
                    set PlayerMenuFogAppliedHeight[this.user.id] = -1.
                    call ResetToGameCamera(0)
                endif
            endif

            set this.displayed = flag
            call this.applyVisualState()
        endmethod

        private static method onInit takes nothing returns nothing
            set thistype.Hashtable = InitHashtable()
            set thistype.UpdateTimer = CreateTimer()
            set thistype.Initialized = true
        endmethod

    endstruct

    function MenuClientRefreshEnemyPreviewForActivePlayers takes nothing returns nothing
        local integer i = 0
        local User u
        local unit hero
        local Client client
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set hero = PlayerHero[u.id]
            if hero != null and GetUnitTypeId(hero) != 0 then
                set client = Client[hero]
                if client != 0 then
                    call client.setEnemyPreviewWave(TargetWave)
                endif
            endif
            set i = i + 1
        endloop
        set hero = null
    endfunction

    function MenuClientClearEnemyPreviewForActivePlayers takes nothing returns nothing
        local integer i = 0
        local User u
        local unit hero
        local Client client
        loop
            exitwhen i == User.AmountPlaying
            set u = User.fromPlaying(i)
            set hero = PlayerHero[u.id]
            if hero != null and GetUnitTypeId(hero) != 0 then
                set client = Client[hero]
                if client != 0 then
                    call client.clearEnemyPreview()
                endif
            endif
            set i = i + 1
        endloop
        set hero = null
    endfunction

    /*
    private function OnInventoryItemClick takes nothing returns nothing
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pid = GetPlayerId(p)
        local Inventory inv =  Inventory.PlayerCurrent[pid]
        local integer slot =  but.customValue
        local integer itemId = 0
        local integer last = InvPlayerLastSlot[inv.pid] - 1
        local integer lastItemId
        local UIButton lastButton = InvPlayerLastButton[inv.pid]
        local Equipment gear = Equipment[Equipment.PlayerCurrentUnit[inv.pid]]
        local integer gearSlot
        local InvItem itm

        call Equipment.selector[inv.pid].show(false, inv.camera)

        if (gear <= 0) then
            return
        endif

        if (PlayerLastSlot[inv.pid] > 0) then

            set gearSlot = PlayerLastSlot[inv.pid] - 1

            if (inv.getItem(slot) == 0) then
                set gear.item[gearSlot].tempCustomId = gear.itemId[gearSlot]
                call inv.setItem(slot, gear.item[gearSlot])

                set gear.item[gearSlot].tempCustomId = gear.itemId[gearSlot]
                call gear.unequip(gear.item[gearSlot], gearSlot)
            endif

            set PlayerLastSlot[inv.pid] = 0
        else
            set itm = inv.getItem(slot)

            if (itm > 0 and not itm.isSocket) then
                set but = gear.getButton(itm.slot - 1)

                call Equipment.selector[inv.pid].show(true, inv.camera)
                call Equipment.selector[inv.pid].setPosition(but.centerx - 0.007, but.centery + 0.0272)
                call Equipment.selector[inv.pid].showPlayer(Player(inv.pid), true, inv.camera)
            endif
        endif
    endfunction

    private function OnInventoryItemRightClick takes nothing returns nothing
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pid = GetPlayerId(p)
        local Inventory inv =  Inventory.PlayerCurrent[pid]
        local integer slot =  but.customValue
        local Equipment gear = Equipment[Equipment.PlayerCurrentUnit[inv.pid]]
        local InvItem itm = inv.getItem(slot)
        local integer gearSlot = itm.slot - 1
        local integer unequippedSlot = 0
        local InvItem unequipItem = 0
        local integer unequipId = 0

        if (gear <= 0 or itm <= 0) then
            return
        endif

        set itm.tempCustomId = inv.getItemId(slot)

        if (gear.item[gearSlot] > 0) then
            set unequipId = gear.itemId[gearSlot]
            set gear.item[gearSlot].tempCustomId = unequipId
            call gear.unequip(gear.item[gearSlot], gearSlot)
            set unequippedSlot = InvEventSlot
            set unequipItem = InvEventItem
        endif

        set itm.tempCustomId = inv.getItemId(slot)

        if (gear.equip(itm, itm.slot - 1)) then
            call inv.setItem(slot, 0)
            set unequipItem.tempCustomId = unequipId
            call inv.addItem(unequipItem)
        elseif (unequipItem > 0) then
            call gear.equip(unequipItem, unequippedSlot)
        endif
    endfunction */

    /* derecho, no por ahora
    private function RClickItemSlot takes nothing returns boolean
        local UIButton but   = GetTriggerButton()
        local unit u         = Equipment.PlayerCurrentUnit[GetPlayerId(GetClickingPlayer())]
        local Equipment gear = Equipment[u]
        local Inventory inv  = Inventory[u]
        local integer slot   = but.customValue
        local integer itemId
        local InvItem itm
        local integer cid

        if (GetClickingPlayer() != User(inv.pid).handle or gear.item[slot] <= 0) then
            return false
        endif

        // clear tooltip
        call inv.showLines(inv.pid, false, inv.camera)

        set itm = gear.item[slot]
        set itemId = itm.id
        set cid = gear.itemId[slot]

        set gear.item[slot].tempCustomId = cid

        if (gear.unequip(itm, slot)) then
            set itm.tempCustomId = cid
            if (not inv.addItem(itm)) then
                set gear.item[slot].tempCustomId = cid
                call gear.equip(itm, slot)
                return false
            endif
        else
            return false
        endif

        call Inventory.showTooltip(inv, false)

        return false
    endfunction */

    private function MenuClientGetSlotTooltip takes player p, integer slot returns string
        local integer pid = GetPlayerId(p)
        local integer itemIndex = Client.getShopItemIndexFromSlot(slot)
        if slot == Client.MUTATION_SLOT_INSTANCE then
            return "|cffffcc00Improve Instance|r\nCosto: 1 oro\nActual: " + I2S(GetPlayerMissileInstanceCount(p))
        elseif slot == Client.MUTATION_SLOT_CAMERA_UP then
            return "|cffffcc00Camara +|r\nSube la altura de camara.\nActual: " + I2S(R2I(PlayerMenuCameraHeight[pid]))
        elseif slot == Client.MUTATION_SLOT_DAMAGE then
            return "|cffffcc00Improve Damage|r\nCosto: 1 oro\nActual: " + R2S(GetPlayerMissileDamageValue(p))
        elseif slot == Client.MUTATION_SLOT_REGEN then
            return "|cffffcc00Improve RegeShot|r\nCosto: 1 oro\nActual: " + R2S(GetPlayerMissileHealOnHit(p))
        elseif slot == Client.MUTATION_SLOT_SMART_RECAST then
            if GetPlayerMissileUseSmartRecast(p) then
                return "|cffffcc00Smart Recast|r\nCosto: 10 oro\nEstado: ON"
            endif
            return "|cffffcc00Smart Recast|r\nCosto: 10 oro\nEstado: OFF"
        elseif slot == Client.MUTATION_SLOT_ORB_LEVEL then
            return "|cffffcc00Improve Orb Level|r\nCosto: 1 oro\nMax: 4\nActual: " + I2S(GetPlayerOrbLevel(p))
        elseif slot == Client.MUTATION_SLOT_CAMERA_DOWN then
            return "|cffffcc00Camara -|r\nBaja la altura de camara.\nActual: " + I2S(R2I(PlayerMenuCameraHeight[pid]))
        elseif slot == Client.HUB_SLOT_SHOP then
            return "|cffffcc00Tienda|r\nComprar armas, habilidades, recargas y consumibles.\n|cff999999Funcion pendiente.|r"
        elseif slot == Client.HUB_SLOT_UPGRADES then
            return "|cff00ccffMejoras|r\nEscalar armas, habilidades, orbe y partes del heroe por nodos.\n|cff999999Funcion pendiente.|r"
        elseif slot == Client.HUB_SLOT_INTEL then
            return "|cff99ff99Intel|r\nVer informacion detallada de enemigos, bosses y la proxima oleada.\n|cff999999Funcion pendiente.|r"
        elseif slot == Client.SHOP_DETAIL_BUY_BUTTON then
            return "|cffffcc00Comprar arma|r\nDesbloquea el boton selector U0B*.\nLuego presiona esa habilidad para equipar el disparo U0A*."
        elseif slot == Client.SHOP_DETAIL_TREE_BUTTON then
            return "|cff00ccffIr a mejoras|r\nAbre directo el arbol de mejoras del arma/habilidad seleccionada."
        elseif itemIndex > 0 then
            return "|cffffcc00" + Client.getShopItemName(itemIndex) + "|r\nClick izquierdo: ver ayuda.\nClick derecho dos veces: seleccionar y mostrar detalle."
        endif
        return "|cffffcc00Boton sin accion activa|r"
    endfunction

    private function MenuClientSetClickText takes Client equip, string text returns nothing
        if equip != 0 then
            set PlayerMenuClickText[equip.user.id] = text
        endif
    endfunction

    private function MenuClientShowSlotTooltip takes UIButton but, player p returns nothing
        local integer slot = but.customValue
        local Client equip = Client[Client.PlayerCurrentUnit[GetPlayerId(p)]]
        call MenuClientSetClickText(equip, MenuClientGetSlotTooltip(p, slot) + "\n|cff999999Click derecho: seleccionar / confirmar.|r")
        if equip != 0 then
            call equip.show(true, equip.camera)
        endif
    endfunction

    private function MenuClientSelectPanel takes Client equip, integer panelSlot returns nothing
        local integer pid = equip.user.id

        set PlayerMenuShowShop[pid] = false
        set PlayerMenuShowTree[pid] = false
        set PlayerMenuShowEnemies[pid] = false

        if panelSlot == Client.HUB_SLOT_SHOP then
            set PlayerMenuShowShop[pid] = true
            if PlayerMenuSelectedShopWeapon[pid] <= 0 then
                set PlayerMenuSelectedShopWeapon[pid] = Client.SHOP_ITEM_PISTOL
            endif
        elseif panelSlot == Client.HUB_SLOT_UPGRADES then
            set PlayerMenuShowTree[pid] = true
        elseif panelSlot == Client.HUB_SLOT_INTEL then
            set PlayerMenuShowEnemies[pid] = true
        endif

        set PlayerLastButton[pid] = 0
        set PlayerLastSlot[pid] = 0
        if Client.selector[pid] != 0 then
            call Client.selector[pid].showPlayer(equip.user.handle, false, equip.camera)
        endif
        call equip.show(true, equip.camera)
    endfunction

    private function ExecuteMenuSlotAction takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pdex = GetPlayerId(p)
        local Client equip = Client[Client.PlayerCurrentUnit[pdex]]
        //local Inventory inv = Inventory.PlayerCurrent[equip.user.id] //nventario activo asociado al mismo usuario del equip.
        local integer slot =  but.customValue
        //local integer last = InvPlayerLastSlot[inv.pid] - 1
        local integer itemId = 0
        local User u = User[GetClickingPlayer()]
        local integer i = 0
        local integer oro = GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD)
        local integer selectedWeapon = 0
        local integer selectedCost = 0


        //local UIButton lastButton = InvPlayerLastButton[equip.user.id]
        //local InvItem itm
        if equip == 0 then
            return false
        endif
        if (p != equip.user.handle) then
            return false
        endif
        if (User.Local == p) then
            call SelectUnit(but.picture, false)
            call SelectUnit(equip.unit, true)
        endif

        if slot == Client.HUB_SLOT_SHOP or slot == Client.HUB_SLOT_UPGRADES or slot == Client.HUB_SLOT_INTEL then
            call MenuClientSelectPanel(equip, slot)
            set p = null
            return false
        endif

        if slot == Client.SHOP_DETAIL_TREE_BUTTON then
            call MenuClientSelectPanel(equip, Client.HUB_SLOT_UPGRADES)
            set p = null
            return false
        endif

        if slot == Client.SHOP_DETAIL_BUY_BUTTON then
            set selectedWeapon = PlayerMenuSelectedShopWeapon[pdex]
            if not WeaponProfileIsWeapon(selectedWeapon) then
                call MenuClientSetClickText(equip, "|cffffcc00Selecciona un arma antes de comprar.|r")
            elseif not isTender[pdex] or not IsUnitNearTender(PlayerHero[pdex], 500.0) then
                call MenuClientSetClickText(equip, "|cffffcc00Lords Engines no activa o estas fuera de distancia.|r")
            elseif PlayerHasWeaponProfile(p, selectedWeapon) then
                call MenuClientSetClickText(equip, "|cffffcc00Ya tenes:|r " + WeaponProfileGetName(selectedWeapon) + "\n|cff99ccffUsa su boton de habilidad para equiparla.|r")
            else
                set selectedCost = WeaponProfileGetCost(selectedWeapon)
                if oro >= selectedCost then
                    call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - selectedCost)
                    if UnlockPlayerWeaponProfile(p, selectedWeapon) then
                        call MenuClientSetClickText(equip, "|cff99ff99Compraste:|r " + WeaponProfileGetName(selectedWeapon) + "\n|cff99ccffSe agrego su boton selector. Presionalo para equipar el disparo.|r")
                        call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                    else
                        call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro)
                        call MenuClientSetClickText(equip, "|cffff5555No se pudo agregar el arma al heroe.|r")
                    endif
                else
                    call MenuClientSetClickText(equip, "|cffffcc00Oro insuficiente para comprar:|r " + WeaponProfileGetName(selectedWeapon))
                endif
            endif
            call equip.show(true, equip.camera)
            set p = null
            return false
        endif

        set itemId = Client.getShopItemIndexFromSlot(slot)
        if itemId > 0 then
            set PlayerMenuSelectedShopWeapon[pdex] = itemId
            set PlayerMenuRenderedShopWeapon[pdex] = 0
            call MenuClientSetClickText(equip, "|cffffcc00Seleccionado:|r " + Client.getShopItemName(itemId))
            call equip.show(true, equip.camera)
            set p = null
            return false
        endif

        if (slot == Client.MUTATION_SLOT_INSTANCE) then
            if oro > 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - 1)
                call SetPlayerMissileInstanceCount(GetClickingPlayer(),GetPlayerMissileInstanceCount(GetClickingPlayer())+1)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                // Acción que quieres ejecutar
                //call DisplayTextToPlayer(p,0,0,"Se restó 1 de oro")
            elseif oro <= 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Oro Insuficiente Para Comprar Instance!|r")
            else
                if User.fromLocal() == u then
                    call StartSound(error_Neg)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Lords Engines No Activa/Fuera de Distancia!|r")
            endif
        endif

        if (slot == Client.MUTATION_SLOT_CAMERA_UP) then
            call StepMenuCameraHeight(pdex, GetMenuCameraHeightStep())
            call MenuClientSetClickText(equip, "|cffffcc00Cam Height:|r " + I2S(R2I(PlayerMenuCameraHeight[pdex])) + " |cffffcc00Offset:|r -" + I2S(R2I(PlayerMenuCameraOffset[pdex])))
        endif

        if (slot == Client.MUTATION_SLOT_DAMAGE) then
            if oro > 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - 1)
                call SetPlayerMissileDamageValue(GetClickingPlayer(),GetPlayerMissileDamageValue(GetClickingPlayer())+0.05)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                // Acción que quieres ejecutar
                //call DisplayTextToPlayer(p,0,0,"Se restó 1 de oro")
            elseif oro <= 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Oro Insuficiente Para Comprar damage!|r")
            else
                if User.fromLocal() == u then
                    call StartSound(error_Neg)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Lords Engines No Activa/Fuera de Distancia!|r")
            endif

        endif

        if (slot == Client.MUTATION_SLOT_REGEN) then
            if oro > 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - 1)
                call SetPlayerMissileHealOnHit(GetClickingPlayer(),GetPlayerMissileHealOnHit(GetClickingPlayer())+2.5)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                // Acción que quieres ejecutar
                //call DisplayTextToPlayer(p,0,0,"Se restó 1 de oro")
            elseif oro <= 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Oro Insuficiente Para Comprar Rege!|r")
            else
                if User.fromLocal() == u then
                    call StartSound(error_Neg)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Lords Engines No Activa/Fuera de Distancia!|r")
            endif

        endif

        if (slot == Client.MUTATION_SLOT_SMART_RECAST) then
            if oro > 5 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) and GetPlayerMissileUseSmartRecast(GetClickingPlayer()) == false then
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - 10)
                call SetPlayerMissileUseSmartRecast(GetClickingPlayer(),true)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                // Acción que quieres ejecutar
                //call DisplayTextToPlayer(p,0,0,"Se restó 1 de oro")
            elseif oro <= 5 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) and GetPlayerMissileUseSmartRecast(GetClickingPlayer()) == false then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Oro Insuficiente Para Comprar Smart!|r")

            elseif GetPlayerMissileUseSmartRecast(GetClickingPlayer()) == true then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Smart On!|r")
            else
                if User.fromLocal() == u then
                    call StartSound(error_Neg)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Lords Engines No Activa/Fuera de Distancia!|r")
            endif


        endif

        if (slot == Client.MUTATION_SLOT_ORB_LEVEL) then
            if oro > 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) and GetPlayerOrbLevel(GetClickingPlayer()) <= 3 then
                call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, oro - 1)
                call SetPlayerOrbLevel(GetClickingPlayer(),GetPlayerOrbLevel(GetClickingPlayer())+1)
                call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIem\\AIemTarget.mdl", but.picture, "origin"))
                // Acción que quieres ejecutar
                //call DisplayTextToPlayer(p,0,0,"Se restó 1 de oro")
            elseif oro <= 0 and isTender[pdex] and IsUnitNearTender(PlayerHero[pdex], 500.0) and GetPlayerOrbLevel(GetClickingPlayer()) <= 3 then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Oro Insuficiente Para Comprar LevelOrb!|r")

            elseif GetPlayerOrbLevel(GetClickingPlayer()) == 4 then
                if User.fromLocal() == u then
                    call StartSound(error)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Max LevelOrb!|r")
            else
                if User.fromLocal() == u then
                    call StartSound(error_Neg)
                    call ClearTextMessages()
                endif

                call MenuClientSetClickText(equip, "|cffffcc00Lords Engines No Activa/Fuera de Distancia!|r")
            endif
        endif

        if (slot == Client.MUTATION_SLOT_CAMERA_DOWN) then
            call StepMenuCameraHeight(pdex, -GetMenuCameraHeightStep())
            call MenuClientSetClickText(equip, "|cffffcc00Cam Height:|r " + I2S(R2I(PlayerMenuCameraHeight[pdex])) + " |cffffcc00Offset:|r -" + I2S(R2I(PlayerMenuCameraOffset[pdex])))
        endif

        /*
        if (slot == Client.MUTATION_SLOT_CAMERA_UP) then
            call UnitAddItemSwapped(CreateItem('tdex',0.,0.),PlayerHero[GetPlayerId(p)])
        endif
        if (slot == Client.MUTATION_SLOT_DAMAGE) then
            call SelectHeroSkill( PlayerHero[GetPlayerId(p)], 'AHfs' )
        endif
        if (slot == Client.MUTATION_SLOT_REGEN) then
            call SelectHeroSkill( PlayerHero[GetPlayerId(p)], 'AHbn' )
        endif
        if (slot == Client.MUTATION_SLOT_SMART_RECAST) then
            call SelectHeroSkill( PlayerHero[GetPlayerId(p)], 'AHdr' )
        endif
        if (slot == Client.MUTATION_SLOT_ORB_LEVEL) then
            call SelectHeroSkill( PlayerHero[GetPlayerId(p)], 'AHpx' )
        endif
        if (slot == Client.MUTATION_SLOT_CAMERA_DOWN) then
            call IncUnitAbilityLevel(PlayerHero[GetPlayerId(p)],'AHfs')
        endif
        if (slot == Client.MUTATION_SLOT_UNUSED) then
            call IncUnitAbilityLevel(PlayerHero[GetPlayerId(p)],'AHbn')
        endif
        if (slot == Client.SHOP_SLOT_PISTOL) then
            call IncUnitAbilityLevel(PlayerHero[GetPlayerId(p)],'AHdr')
        endif
        if (slot == Client.SHOP_SLOT_SHOTGUN) then
            call IncUnitAbilityLevel(PlayerHero[GetPlayerId(p)],'AHpx')
        endif
        */

        /*
        if (InvButtonDisabled[but]) then
            return false
        endif
        */
        //call inv.showLines(inv.pid, false, inv.camera) Oculta líneas/guías visuales del inventario antes de seguir.

        //set PlayerLastSlot[equip.user.id] = slot + 1

        // equip item
        /*
        if (inv > 0 and last+1 > 0) then

            set last = (Inventory.MAX_SLOTS * inv.currentPage) + last

            set itm = inv.getItem(last)

            if (itm.slot - 1 == slot or itm.slotAlt - 1 == slot) then
                set itm.tempCustomId = inv.getItemId(last)

                if (equip.equip(itm, slot)) then
                    set PlayerLastSlot[inv.pid] = 0
                    call inv.setItem(last, 0)

                    call TimerStart(NewTimerEx(but), 2, false, function InventoryCore_GracePeriod)
                    set InvButtonDisabled[but] = true
                endif
            endif
        endif
        */

        //set InvPlayerLastButton[equip.user.id] = but
        //set InvPlayerLastSlot[equip.user.id] = 0

        /*
        if (but != lastButton) then
            call SetUnitVertexColor(lastButton.picture, 255, 255, 255, 255)
            call SetUnitVertexColor(but.picture, 175, 175, 175, 255)
        endif

        set itemId = equip.item[slot].id
        */
        /*
        call Inventory.selector[inv.pid].show(false, inv.camera)
        call Equipment.selector[inv.pid].setPosition(but.centerx - 0.007, but.centery + 0.0272)
        call Equipment.selector[inv.pid].showPlayer(Player(inv.pid), true, inv.camera)
        */
        /*
        if (itemId > 0) then
            set equip.item[slot].tempCustomId = equip.itemId[slot]

            call inv.setTooltipTitle(GetObjectName(itemId))
            call GetInvItem(itemId).buildDescription(inv.owner)
            call inv.setTooltipCost("|cffffcc00" + I2S(GetInvItem(itemId).cost) + "|r")
            call inv.setTooltipIcon(inv.localInt(inv.pid, GetItemIcon(itemId), Inventory.ICON_TRANSPARENT))

            set equip.item[slot].tempCustomId = 0
        endif

        // display tooltip
        set Inventory.TOOLTIP_X = but.minx - 0.4
        set Inventory.TOOLTIP_Y = but.miny - 0.08

        call Inventory.showTooltip(inv, itemId > 0)
        */
        call equip.show(true, equip.camera)
        set p = null
        return false
    endfunction

    private function LClickItemSlot takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pdex = GetPlayerId(p)
        local Client equip = Client[Client.PlayerCurrentUnit[pdex]]

        if equip == 0 then
            set p = null
            return false
        endif
        if p != equip.user.handle then
            set p = null
            return false
        endif

        if (User.Local == p) then
            call SelectUnit(but.picture, false)
            call SelectUnit(equip.unit, true)
        endif

        call MenuClientShowSlotTooltip(but, p)
        set p = null
        return false
    endfunction

    private function RClickItemSlot takes nothing returns boolean
        local UIButton but = GetTriggerButton()
        local player p = GetClickingPlayer()
        local integer pdex = GetPlayerId(p)
        local Client equip = Client[Client.PlayerCurrentUnit[pdex]]
        local integer slot = but.customValue

        if equip == 0 then
            set p = null
            return false
        endif
        if p != equip.user.handle then
            set p = null
            return false
        endif

        if (User.Local == p) then
            call SelectUnit(but.picture, false)
            call SelectUnit(equip.unit, true)
        endif

        if slot == Client.HUB_SLOT_SHOP or slot == Client.HUB_SLOT_UPGRADES or slot == Client.HUB_SLOT_INTEL then
            call MenuClientSelectPanel(equip, slot)
            set p = null
            return false
        endif

        if slot == Client.SHOP_DETAIL_TREE_BUTTON then
            call MenuClientSelectPanel(equip, Client.HUB_SLOT_UPGRADES)
            set p = null
            return false
        endif

        if PlayerLastButton[pdex] == but and PlayerLastSlot[pdex] == slot + 1 then
            set PlayerLastButton[pdex] = 0
            set PlayerLastSlot[pdex] = 0
            if Client.selector[pdex] != 0 then
                call Client.selector[pdex].showPlayer(p, false, equip.camera)
            endif
            set p = null
            return ExecuteMenuSlotAction()
        endif

        set PlayerLastButton[pdex] = but
        set PlayerLastSlot[pdex] = slot + 1
        if Client.selector[pdex] != 0 then
            call Client.selector[pdex].setPosition(but.centerx - 0.007, but.centery + 0.0272)
            call Client.selector[pdex].showPlayer(p, true, equip.camera)
        endif
        call MenuClientShowSlotTooltip(but, p)

        set p = null
        return false
    endfunction

    private function Init takes nothing returns nothing
        local User user = User.first
        loop
            exitwhen user == User.NULL
            set PlayerMenuCameraHeight[user.id] = GetDefaultMenuCameraHeight()
            set PlayerMenuCameraOffset[user.id] = GetDefaultMenuCameraOffset()
            set PlayerMenuFogAppliedHeight[user.id] = -1.
            set PlayerMenuSelectedShopWeapon[user.id] = Client.SHOP_ITEM_PISTOL
            set PlayerMenuRenderedShopWeapon[user.id] = 0
            set PlayerMenuClickText[user.id] = "|cffffcc00Ayuda del menu|r\nClick izquierdo: ver descripcion.\nClick derecho: seleccionar.\nDoble click derecho: confirmar."
            set PlayerMenuShowShop[user.id] = false
            set PlayerMenuShowTree[user.id] = false
            set PlayerMenuShowEnemies[user.id] = false
            set user = user.next
        endloop
        set FuncLClickSlot = Filter(function LClickItemSlot)
        set FuncRClickSlot = Filter(function RClickItemSlot)
        //call Inventory.addLeftClickHook(function OnInventoryItemClick)
        //call Inventory.addRightClickHook(function OnInventoryItemRightClick)
    endfunction

endlibrary

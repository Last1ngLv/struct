library EquipHeroModels initializer Init
    
    globals
        private Table HeroModels
        private string array Path
        private integer Models = 0
    endglobals
    
    struct HeroModelData
        string path
        real scale
    endstruct
    
    function EquipSetHeroModel takes integer utype, real scale, string path returns nothing
        local HeroModelData data = HeroModelData.create()
        set data.path = path
        set data.scale = scale
        set HeroModels[utype] = data
    endfunction
    
    function EquipGetHeroModel takes integer id returns HeroModelData
        return HeroModels[id]
    endfunction
    
    private function Init takes nothing returns nothing
        set HeroModels=Table.create()
        
        //
        // configuration
        //
        call EquipSetHeroModel('Hpal', 0.10, "units\\human\\HeroBloodElf\\HeroBloodElf.mdl")
        call EquipSetHeroModel('hfoo', 0.08, "units\\human\\Footman\\Footman.mdl")
        call EquipSetHeroModel('Ulic', 0.08, "units\\undead\\HeroLich\\HeroLich.mdl")
        call EquipSetHeroModel('Obla', 0.08, "units\\orc\\HeroBladeMaster\\HeroBladeMaster.mdl")
        call EquipSetHeroModel('Edem', 0.08, "units\\nightelf\\HeroDemonHunter\\HeroDemonHunter.mdl")
        //
        // end config
        //
    endfunction

endlibrary
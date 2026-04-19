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
        call EquipSetHeroModel('H01A', 0.11, "units\\human\\HeroBloodElf\\HeroBloodElf.mdl")
        call EquipSetHeroModel('hhou', 0.040, "war3mapImported\\XPozoLife.mdx") //"war3mapImported\\PotraitRockGolemV1.mdl" 0.053 units\creeps\RockGolem\RockGolem.mdl
        call EquipSetHeroModel('H001', 0.16, "Marine.mdl")
        call EquipSetHeroModel('H005', 0.11, "Lobo.mdl")
        call EquipSetHeroModel('H006', 0.13, "war3mapImported\\Penguin.mdl")
        call EquipSetHeroModel('H009', 0.08, "war3mapImported\\Hero_ShinigamiP.mdl")
        call EquipSetHeroModel('H007', 0.08, "war3mapImported\\Yoshi TC By RTG.mdl")
        
        call EquipSetHeroModel('AM01', 0.16, "war3mapImported\\OrbBloodXR.mdx")
        call EquipSetHeroModel('AM02', 0.16, "war3mapImported\\OrbPoisonXR.mdx")
        call EquipSetHeroModel('AM03', 0.16, "war3mapImported\\OrbDarknessXR.mdx")
        call EquipSetHeroModel('AM04', 0.16, "war3mapImported\\OrbFireXR.mdx")
        call EquipSetHeroModel('AM05', 0.16, "war3mapImported\\OrbLightningXR.mdx")
        call EquipSetHeroModel('AM06', 0.16, "war3mapImported\\OrbLightXR.mdx")
        //
        // end config
        //
    endfunction

endlibrary
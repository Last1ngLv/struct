scope InvItemSetups initializer Init
    
    function CustomItemCondition takes nothing returns boolean
        local integer id = GetUnitTypeId(InvItem.eventUnit)
        return (id == 'Hpal' or id == 'Obla') // Paladin or Blademaster
    endfunction
    
    private function Init takes nothing returns nothing
        local InvItem itm
        
        // The more verbose way to delcare items:
        // Crown of Kings +5
        set itm = CreateInvItem('ckng', 'B00G', 1000, 0, "Increases the Strength, Intelligence, and Agility of the Hero by 5 when worn.")
        set itm.slot = 1 
        set itm.reqUnitType = 'Hpal'
        set itm.reqLevel = 3
        set itm.maxSockets = 1
        
        call itm.addBonus(BONUS_STRENGTH, 5)
        call itm.addBonus(BONUS_AGILITY, 5)
        call itm.addBonus(BONUS_INTELLIGENCE, 5)
        
        // with string parser
        // Claws of Attack +15
        call InitEquipItem.execute('ratf', "Increases the attack damage of the Hero by 15 when worn.^type=weapon; class=1h; maxsock=1; icon='D009'; cost=28; ^dmg=15;0;0;")
        
        // Robe of the Last Guardian
        call InitEquipItem.execute('I007', "Powerful magic robe.^type=armor; lvl=10; icon=B00Z; utype='Ulic'; cost=600; maxsock=2; ^def=0;10;20; int=20;0;5; life=300;0;0;")
        
        // Gems
        call InitEquipItem.execute('I009', "Can be socketed..^type=gem; icon=B012; cost=600; ^life=0;10;50;")
        call InitEquipItem.execute('I00A', "Can be socketed..^type=gem; icon=B013; cost=600; ^mana=0;5;35;")
        
        // two lines
        // Mask of Death
        set itm = CreateInvItem('modt', 'D02Z', 1000, 0, "While wearing this mask, a Hero will recover hit points equal to 50% of the attack damage dealt to an enemy unit.")
        set itm = SetEquipItemStats(/*slot=*/1, /*slot2=*/0, /*abil=*/'AIva', /*lvl=*/0, /*utype=*/0, /*reqAbil=*/0, /*dmg=*/0, /*def=*/0, /*str=*/0, /*agi=*/0, /*int=*/0, /*atckspd=*/0, /*sight=*/0, /*lifereg=*/0, /*manareg=*/0, itm)
        set itm.maxSockets = 1
        
        // Orb of Frost
        set itm = CreateInvItem('ofro', 'D04U', 1000, 'A003', " Adds 6 bonus cold damage to the attack of a Hero when carried. The Hero's attacks also become ranged when attacking air and slow the movement speed and attack rate of the enemy for 1 second.")
    
        // Boots of Quel'Thalas +6
        set itm = CreateInvItem('belv', 'B00I', 500, 0, " Increases the Agility of the Hero by 6 when worn.")
        set itm.slot = 11
        call itm.addBonus(BONUS_AGILITY, 6)
        set itm.maxSockets = 1
        
        // Belt of Giant Strength +6
        set itm = CreateInvItem('bgst', 'B00J', 500, 0, " Increases the Strength of the Hero by 6 when worn.")
        set itm.slot = 4
        call itm.addBonus(BONUS_STRENGTH, 6)
        set itm.maxSockets = 1
        
        // Gauntlets of Ogre Strength +3
        set itm = CreateInvItem('rst1', 'B00K', 100, 0, " Increases the Strength of the Hero by 3 when worn.")
        set itm.slot = 9
        call itm.addBonus(BONUS_STRENGTH, 3)
        set itm.maxSockets = 1
        
        // Necklace of Spell Immunity
        set itm = CreateInvItem('nspi', 'B00L', 1000, 0, " Renders the Hero invulnerable to magic.")
        set itm.slot = 7
        set itm.equipAbility = 'AImx'
        set itm.maxSockets = 1
        
        // Runed Bracers
        set itm = CreateInvItem('brac', 'B00M',  400, 0, " Reduces Magic damage dealt to the Hero by 33%.")
        set itm.slot = 10
        set itm.equipAbility = 'AIsr'
        set itm.maxSockets = 1
        
        // Ring of Protection +4
        set itm = CreateInvItem('rde3', 'B00O',  500, 0, " Increases the armor of the Hero by 4 when worn.")
        set itm.slot = 6
        set itm.slotAlt = 12
        call itm.addBonus(BONUS_ARMOR, 4)
        set itm.maxSockets = 1
        
        // Pauldron
        set itm = CreateInvItem('I000', 'B00P',  600, 0, " Increases the armor of the Hero by 4 when worn.")
        set itm.slot = 2
        set itm.slotAlt = 8
        call itm.addBonus(BONUS_ARMOR, 4)
        set itm.maxSockets = 1
        
        // Battlescarred Shoulderplate
        set itm = CreateInvItem('I003', 'B00V',  600, 0, " Increases the armor by 4 and strenght by 2 when worn.")
        set itm.slot = 2
        set itm.slotAlt = 8
        set itm.reqUnitType = 'Hpal'
        set itm.reqLevel = 3
        call itm.addBonus(BONUS_ARMOR, 4)
        call itm.addBonus(BONUS_STRENGTH, 2)
        set itm.maxSockets = 1
        
        // Lich Mantle
        set itm = CreateInvItem('I006', 'B00Y',  600, 0, " Increases Intelligence by 3 and Health by 50 when worn.")
        set itm.slot = 2
        set itm.slotAlt = 8
        set itm.reqUnitType = 'Ulic'
        set itm.reqLevel = 3
        call itm.addBonus(BONUS_INTELLIGENCE, 3)
        call itm.addBonus(BONUS_LIFE, 50)
        set itm.maxSockets = 1
        
        // Armor
        set itm = CreateInvItem('I001', 'B00Q',  600, 0, " Increases armor by 8 and life by 100 when worn.")
        set itm.slot = 3
        call itm.addBonus(BONUS_ARMOR, 8)
        call itm.addBonus(BONUS_LIFE, 100)
        set itm.maxSockets = 1
        
        // Silverhand Cuirass
        set itm = CreateInvItem('I004', 'B00W',  600, 0, " Increases armor by 10 and life by 150 when worn.")
        set itm.slot = 3
        set itm.reqUnitType = 'Hpal'
        set itm.reqLevel = 2
        call itm.addBonus(BONUS_ARMOR, 10)
        call itm.addBonus(BONUS_LIFE, 150)
        set itm.maxSockets = 2
        
        // Pants
        set itm = CreateInvItem('I002', 'B00R',  600, 0, "Increases Strength by 3 when worn.")
        set itm.slot = 5
        call itm.addBonus(BONUS_STRENGTH, 3)
        set itm.maxSockets = 1
        
        // Golden Legguards
        set itm = CreateInvItem('I005', 'B00X',  600, 0, "Increases Strength by 3 and Armor by 1 when worn.")
        set itm.slot = 5
        set itm.reqUnitType = 'Hpal'
        call itm.addBonus(BONUS_STRENGTH, 2)
        call itm.addBonus(BONUS_ARMOR, 1)
        set itm.maxSockets = 2
        
        // Kel'Thuzard's Robe
        set itm = CreateInvItem('I008', 'B010',  600, 0, "Increases Intelligence by 5, Health by 40, and Mana by 50 when worn.")
        set itm.slot = 3
        set itm.reqUnitType = 'Ulic'
        call itm.addBonus(BONUS_INTELLIGENCE, 5)
        call itm.addBonus(BONUS_LIFE, 40)
        call itm.addBonus(BONUS_MANA, 50)
        set itm.maxSockets = 1
        
        // Searing Blade
        set itm = CreateInvItem('srbd', 'B000',  1650, 0, "Adds 10 bonus fire damage to the attack of a Hero when carried. The Hero's attacks also do splash damage to nearby enemy units.")
        set itm.slot = 13
        set itm.equipAbility = 'AIfw'
        set itm.equipCondition = Filter(function CustomItemCondition)
        set itm.equipConditionStrPrefix = "Usable"
        set itm.equipConditionStr = "PL or BM"
        set itm.maxSockets = 3
        
        // Shield of Honor
        set itm = CreateInvItem('shhn', 'B001',  3350, 0, "|cff8b00ffUnique|r\nGrants nearby friendly units a 10% bonus to attack damage. Also increases the armor of the Hero by 8 when worn.")
        set itm.slot = 14
        set itm.equipAbility = 'AIcd'
        call itm.addBonus(BONUS_ARMOR, 8)
        set itm.maxSockets = 2
        
        // Dagger of Escape
        set itm = CreateInvItem('desc', 'B002',  400, 0, "Allows the Hero to teleport a short distance.")
        set itm.slot = 13
        set itm.slotAlt = 14
        set itm.reqUnitType = 'Edem'
        set itm.equipAbility = 'AIbk'
        set itm.maxSockets = 1
    endfunction
    
endscope
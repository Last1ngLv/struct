//TESH.scrollpos=19
//TESH.alwaysfold=0
// external ObjectMerger w3a ANso AS00 arlv 2 aran 1 99999 acdn 1 0 amcs 1 0 atar 1 "vuln,invu,alive,dead"
// external ObjectMerger w3a Amfl AS01 amcs 1 0
// external ObjectMerger w3t tkno IS00 iabi "AS01" ifil ""

//! zinc
library AbilitySilence
{
//! textmacro CreateObjects2 takes SB, MFL, ITEM
    constant integer SILENCE_ORDER = 852668; //OrderId("soulburn")
    constant integer SILENCE_ID = '$SB$'; //Soul Burn ability
    constant integer DETECT_ORDER = 852479; //OrderId("magicundefense")
    constant integer DETECT_ID = 'Amdf'; //Detector ability. I'm using Magic Defense cause no one else uses it.
    constant integer MFL_ID = '$MFL$'; //Mana Flare makes the unit temporarily immune to silence.
    constant integer ITEM_ID = '$ITEM$'; //Powerup that holds the Mana Flare ability.

//! endtextmacro
//! runtextmacro CreateObjects2("AS00", "AS01", "IS00")

    unit Dummy;
    boolean flag;
    integer id;

    /*If you already have a dummy in your map you
    may modify this function to make use of it.*/
    function GetDummy() -> unit
    {
        Dummy = CreateUnit(Player(15), 'uloc', .0, .0, .0);
        SetUnitScale(Dummy, 0, 0, 0);
        UnitRemoveAbility(Dummy, 'Amov');
        UnitRemoveAbility(Dummy, 'Aatk');
        return Dummy;
    }

    function EnableAbility(unit u, integer id)
    {
        IncUnitAbilityLevel(u, id);
        IssueTargetOrderById(Dummy, SILENCE_ORDER, u);
        DecUnitAbilityLevel(u, id);
        UnitRemoveAbility(u, 'BNso');
    }

    function DisableAbility(unit u, integer id)
    {
        IssueTargetOrderById(Dummy, SILENCE_ORDER, u);
        IncUnitAbilityLevel(u, id);
        UnitRemoveAbility(u, 'BNso');
        DecUnitAbilityLevel(u, id);
    }

    function OnSilence() -> boolean
    {
        if (GetIssuedOrderId() == DETECT_ORDER && UnitRemoveAbility(GetTriggerUnit(), MFL_ID))
        {
            /*At this point our unit is immune to silence, so we can 
            silence a single ability without affecting others.*/
            if (flag) DisableAbility(GetTriggerUnit(), id);
            else EnableAbility(GetTriggerUnit(), id);
        }
        return false;
    }

    public function SetUnitAbilitySilenced(unit u, integer i, boolean silence)
    {
        boolean inventory = UnitAddAbility(u, 'AInv');
        boolean hidden = IsUnitHidden(u);
        if (hidden) ShowUnit(u, true);
        UnitAddAbility(u, DETECT_ID);
        SetUnitOwner(Dummy, GetOwningPlayer(u), false);
        id = i;
        flag = silence;
        RemoveItem(UnitAddItemById(u, ITEM_ID));
        if (!UnitRemoveAbility(u, 'Bmfl'))
        {
            /* If the unit failed to cast Mana Flare, then it's probably
            dead or already silenced. So we just ignore it and continue*/
            if (silence) DisableAbility(u, i);
            else EnableAbility(u, i);
        }
        UnitRemoveAbility(u, DETECT_ID);
        if (hidden) ShowUnit(u, false);
        if (inventory) UnitRemoveAbility(u, 'AInv');
    }

    function onInit()
    {
        trigger t = CreateTrigger();
        TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_ISSUED_ORDER);
        TriggerAddCondition(t, Condition(function OnSilence));
        Dummy = GetDummy();
        UnitAddAbility(Dummy, SILENCE_ID);
        t = null;
    }
}
//! endzinc
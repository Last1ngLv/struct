//TESH.scrollpos=24
//TESH.alwaysfold=0
library SpellIndex/* v1.1
************************************************************
*
*   Makes spell indexing global and nulls members automatically.
*   A screen freeze is more likely than an overflow.
*
*   API: 
*       --> SpellIndex.create() and index.destroy()
*
************************************************************
*
*   */ uses /*
*       
*       */ Table                   /* hiveworkshop.com/forums/jass-resources-412/snippet-new-table-188084/
*       */ Missile                 /* hiveworkshop.com/forums/jass-resources-412/missile-265370/
*       */ TimerUtils              /* wc3c.net/showthread.php?t=101322
*       */ DummyCaster             /* github.com/nestharus/JASS/tree/master/jass/Systems/DummyCaster
*       */ WorldBounds             /* github.com/nestharus/JASS/tree/master/jass/Systems/WorldBounds
*       */ SpellEffectEvent        /* hiveworkshop.com/forums/jass-resources-412/snippet-spelleffectevent-187193/
*       */ RegisterPlayerUnitEvent /* hiveworkshop.com/forums/showthread.php?t=203338
*
***************************************************************
*
*   Credits to Bribe, Nestharus, Maghteridon96 and Vexorian.
*
***************************************************************/
    
    native UnitAlive takes unit id returns boolean
    
    struct SpellIndex
        //*  implement your Alloc module here.
    
        static constant group GLOBAL_GROUP = bj_lastCreatedGroup 
        //*  Add or remove struct members you to needs.
        //*  Units.
        unit      source
        unit      target
        player    user
        //* Effects.
        effect    fx
        ubersplat splat
        lightning flash
        //* Timer.
        timer     clock
        //*  Damage options.
        real      damage
        real      collision
        //*  Misc.
        real      time
        integer   count
        integer   level
        integer   phase
        
        //*  Conditionally destroy an handle on instance.destroy().
        //! textmacro SPELL_INDEX_CHECK_MEMBER takes VAR, TYPE
            if $VAR$ != null then
                call Destroy$TYPE$($VAR$) 
                set $VAR$ = null
            endif 
        //! endtextmacro
        
        method destroy takes nothing returns nothing
            //! runtextmacro SPELL_INDEX_CHECK_MEMBER("fx", "Effect")
            //! runtextmacro SPELL_INDEX_CHECK_MEMBER("splat", "Ubersplat")
            //! runtextmacro SPELL_INDEX_CHECK_MEMBER("flash", "Lightning")
            set target    = null
            set clock     = null
            set source    = null
            call deallocate()
        endmethod
    
    endstruct

endlibrary


library SelectionHeroSpawn requires PlayerUtils, OrderSmartChannel, HeroLives, PlayerHeroState, SelectionHeroConfig

    globals
        private constant real SELECTION_SPAWN_X = -1536.
        private constant real SELECTION_SPAWN_Y = 24064.
    endglobals

    function SelectionEnsureHeroCreated takes User u, integer heroChoice returns nothing
        local player p = u.toPlayer()
        if PlayerHero[u.id] != null and GetUnitTypeId(PlayerHero[u.id]) != 0 then
            return
        endif

        set PlayerHero[u.id] = CreateUnit(p, SelectionGetHeroUnitId(heroChoice), SELECTION_SPAWN_X, SELECTION_SPAWN_Y, 270.)
        call SILENCE_TESTUNIT_AMOV(PlayerHero[u.id])
        call HeroLivesInitHero(u.id, PlayerHero[u.id])

        if PlayerCamera[u.id] == 0 then
            set PlayerCamera[u.id] = Camera.create()
        endif

        call SetPlayerAllianceStateBJ(Player(bj_PLAYER_NEUTRAL_EXTRA), u.handle, bj_ALLIANCE_ALLIED_VISION)
        call SetPlayerAllianceStateBJ(u.handle, Player(bj_PLAYER_NEUTRAL_EXTRA), bj_ALLIANCE_ALLIED_VISION)
    endfunction

endlibrary

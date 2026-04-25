library AllianceConfig

    function InitHostileNeutralAlliances takes nothing returns nothing
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[8], bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[9], bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[10], bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[11], bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_FORCE_PLAYER[8], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_FORCE_PLAYER[9], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_FORCE_PLAYER[10], bj_ALLIANCE_ALLIED_VISION )
        call SetForceAllianceStateBJ( bj_FORCE_PLAYER[PLAYER_NEUTRAL_AGGRESSIVE], bj_FORCE_PLAYER[11], bj_ALLIANCE_ALLIED_VISION )
    endfunction

    function InitPlayerBountyStates takes nothing returns nothing
        call SetPlayerState(Player(0), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(1), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(2), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(3), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(4), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(5), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(6), PLAYER_STATE_GIVES_BOUNTY, 0)
        call SetPlayerState(Player(7), PLAYER_STATE_GIVES_BOUNTY, 0)
    endfunction

endlibrary

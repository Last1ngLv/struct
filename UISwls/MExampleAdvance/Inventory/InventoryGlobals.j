globals
    filterfunc InvFuncLClickSlot = null
    filterfunc InvFuncRClickSlot = null
    integer array InvPlayerLastSlot
    UIButton array InvPlayerLastButton
    boolean array InvButtonDisabled
    player InvEventPlayer = null
    InvItem InvEventItem = 0
    integer InvEventSlot = 0
    constant integer INVENTORY_KEY_START = 10000 // above 8191 
endglobals
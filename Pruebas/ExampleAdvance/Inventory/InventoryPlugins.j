library InventoryPlugins

    // add plugins here
    module InvPlugins
        implement InvTooltip
    endmodule
    
    module InvItemPlugins
        implement InvItemTooltip
        implement InvItemEquipment
        implement InvItemSocket
    endmodule

endlibrary
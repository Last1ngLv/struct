library InventoryTooltip

    module InvTooltip
        //
        // configuration
        //
        
        // about the length of tooltip line.
        // line lengths are resolution and char-width 
        // dependent for textags, so a new text tag
        // is created per-line.
        static constant integer TOOLTIP_LINE_LENGTH  = 32
        static constant integer TOOLTIP_LINES_MAX    = 16
        static constant integer TOOLTIP_TEXTURE      = 'B014'
        static constant real TOOLTIP_LINE_SPACING    = .05
        static constant real TOOLTIP_FONT_SIZE       = 7.5
        
        static constant integer ICON_TOOLTIP_GOLD  = 'B00H'
        static constant integer TOOLTIP_BACKGROUND = 'ttip'
        //
        // end config
        //
        
        readonly static UIText array ItemInfoTags[15][.TOOLTIP_LINES_MAX]
        static integer array RightSideStart
        
        static UIText array infoBoxTitle
        static UIText array infoBoxCost
        static UIText array infoBoxDesc
        static UIPicture array infoBox
        static UIPicture array infoIcon 
        static UIPicture array costIcon 
        
        method setTooltipTitle takes string title returns nothing
            call SetTextTagText(thistype.infoBoxTitle[this.pid].text, title, 10 * 0.0023)
        endmethod
        
        method setTooltipInfo takes string desc returns nothing
            call SetTextTagText(thistype.infoBoxTitle[this.pid].text, desc, TOOLTIP_FONT_SIZE * 0.0023)
        endmethod
        
        method setTooltipCost takes string value returns nothing
            call SetTextTagText(thistype.infoBoxCost[this.pid].text, value, 8 * 0.0023)
        endmethod
        
        method setTooltipIcon takes integer id returns nothing
            call this.infoIcon[this.pid].setTexture(id)
        endmethod
        
        static method setTooltipLine takes integer pid, integer line, string str returns nothing
            call SetTextTagText(Inventory.ItemInfoTags[pid][line].text, str, Inventory.TOOLTIP_FONT_SIZE * 0.0023)
        endmethod
        
        static method setTooltipSlot takes integer pid, integer line, string str returns nothing
            call SetTextTagText(Inventory.ItemInfoTags[pid][TOOLTIP_LINES_MAX-1].text, str, Inventory.TOOLTIP_FONT_SIZE * 0.0023)
        endmethod
        
        method showLines takes integer pid, boolean flag, Camera cam returns nothing
            local integer i = 0
            loop
                exitwhen i == TOOLTIP_LINES_MAX
                if (not flag) then
                    call SetTextTagText(Inventory.ItemInfoTags[pid][i].text, "", Inventory.TOOLTIP_FONT_SIZE * 0.0023)
                endif
                call Inventory.ItemInfoTags[pid][i].show(flag, cam)
                set i = i + 1
            endloop
        endmethod
        
        static method clearLines takes integer pid returns nothing
            local integer i = 0
            loop
                exitwhen i == TOOLTIP_LINES_MAX
                call SetTextTagText(Inventory.ItemInfoTags[pid][i].text, "", Inventory.TOOLTIP_FONT_SIZE * 0.0023)
                set i = i + 1
            endloop
        endmethod
        
        static method updateLines takes integer pid returns nothing
            local integer i = 0
            loop
                exitwhen i == TOOLTIP_LINES_MAX
                call Inventory.ItemInfoTags[pid][i].update()
                set i = i + 1
            endloop
        endmethod
        
        static method createTooltip takes thistype this, integer raceId returns nothing
            local boolean showLocally = (User.Local == User(this.pid).handle)
            local integer i = 0
        
            //if (showLocally) then
                if (thistype.infoBoxTitle[this.pid] == null) then
                    set thistype.infoBoxTitle[this.pid] = UIText.createEx(this.user.toPlayer(), TOOLTIP_X - 0.1, TOOLTIP_Y + .22, 1)
                    
                    set thistype.infoBoxDesc[this.pid] = UIText.createEx(this.user.toPlayer(), TOOLTIP_X - 0.1, TOOLTIP_Y + .25, 1)
                endif
                
                if (thistype.infoBoxCost[this.pid] == null) then
                    set thistype.infoBoxCost[this.pid] = UIText.createEx(this.user.toPlayer(), TOOLTIP_X - (0.065 - 0.), TOOLTIP_Y + .15, 1)
                endif
                
                
                // description lines
                if (ItemInfoTags[this.pid][0] == 0) then
                    loop
                        exitwhen i == TOOLTIP_LINES_MAX
                        
                        if (i == TOOLTIP_LINES_MAX-1) then
                            set ItemInfoTags[this.pid][i] = UIText.createEx(this.user.toPlayer(), TOOLTIP_X + 0.05, TOOLTIP_Y + .16, 1)
                        else
                            set ItemInfoTags[this.pid][i] = UIText.createEx(this.user.toPlayer(), TOOLTIP_X - 0.18, TOOLTIP_Y - (-.05 + (TOOLTIP_LINE_SPACING*i)), 1)
                        endif
                        
                        set i = i + 1
                    endloop
                endif
            //endif
            
            if (.infoIcon[this.pid] == 0) then  
                set .infoIcon[this.pid] = UIPicture.create(TOOLTIP_X - 0.18, TOOLTIP_Y + .28, 0.07, 0.07 * SCREEN_ASPECT_RATIO, 0.1, 0)
                set .costIcon[this.pid] = UIPicture.create(TOOLTIP_X - 0.1,  TOOLTIP_Y + .215, 0.03, 0.03 * SCREEN_ASPECT_RATIO, 0, 0)
                set .infoBox[this.pid] = UIPicture.createEx(TOOLTIP_X, TOOLTIP_Y, 0.20, 0.10, TOOLTIP_BACKGROUND, 120., 60., .localInt(this.pid, TOOLTIP_TEXTURE, ICON_TRANSPARENT))
            endif
            
            call .costIcon[this.pid].setTexture(Inventory.localInt(this.pid, ICON_TOOLTIP_GOLD, ICON_TRANSPARENT))
            call .infoIcon[this.pid].setTexture(Inventory.localInt(this.pid, ICON_TOOLTIP_GOLD, ICON_TRANSPARENT))
            
            call SetUnitVertexColor(.infoBox[this.pid].picture, 255, 255, 255, Inventory.localInt(this.pid, 255, 0))
        endmethod
        
        static method showTooltip takes thistype this, boolean flag returns nothing
            local integer i = 0
            
            loop
                exitwhen i == TOOLTIP_LINES_MAX
                if (i < Inventory.RightSideStart[this.pid]) then
                    call ItemInfoTags[this.pid][i].setPosition(TOOLTIP_X - 0.15, (TOOLTIP_Y - 0.05) - ((TOOLTIP_LINE_SPACING*i)))
                else
                    call ItemInfoTags[this.pid][i].setPosition(TOOLTIP_X + 0.175, (TOOLTIP_Y - 0.05) - ((TOOLTIP_LINE_SPACING*(i-Inventory.RightSideStart[this.pid]))))
                endif
                set i = i + 1
            endloop
                    
            call Inventory.ItemInfoTags[pid][TOOLTIP_LINES_MAX-1].setPosition(TOOLTIP_X + 0.175, TOOLTIP_Y + 0.05)
            
            call .infoBox[this.pid].setPosition(TOOLTIP_X, TOOLTIP_Y)
            call .infoBoxTitle[this.pid].setPosition(TOOLTIP_X - 0.15, TOOLTIP_Y + 0.1)
            call .infoBoxCost[this.pid].setPosition(TOOLTIP_X - 0.11, TOOLTIP_Y + 0.022)
            call .costIcon[this.pid].setPosition(TOOLTIP_X - 0.15 , TOOLTIP_Y + 0.1)

            call .infoBox[this.pid].show(flag, this.camera)
            //call .infoIcon[this.pid].show(flag, this.camera)
            call .infoBoxTitle[this.pid].show(flag, this.camera)
            call this.showLines(this.pid, flag, this.camera)
            call .infoBoxCost[this.pid].show(flag, this.camera)
            call .costIcon[this.pid].show(flag, this.camera)
        endmethod
        
        static method updateTooltip takes thistype this returns nothing
            local integer i = 0
            
            call .infoBox[this.pid].update()
            call .infoIcon[this.pid].update()
            call .infoBoxTitle[this.pid].update()
            call this.updateLines(this.pid)
            call .infoBoxCost[this.pid].update()
            call .costIcon[this.pid].update()
        endmethod
        
    endmodule
    
    module InvItemTooltip
        //
        // Tooltip building 
        //
        
        private static method getStringLine takes string str, integer line returns string
            local integer i = 0
            local integer l = StringLength(str)
            local string o = ""
            local integer c = 0
            loop
                exitwhen i > l
                if (SubString(str, i, i + 1) == "\n") then
                    set c = c + 1
                        
                    if (c == line) then
                        return o
                    else
                        set o = ""
                    endif
                endif

                set o = o + SubString(str, i, i + 1)
                set i = i + 1
            endloop
            return ""
        endmethod
        
        method lTrim takes string s returns string
            local integer i = 0
            loop
                exitwhen SubString(s, i, i + 1) != " "
                set s = SubString(s, 1, 9999)
                set i = i + 1
            endloop
            return s
        endmethod
        
        method buildDescriptionLines takes integer pid, integer startLine returns integer
            local integer i = 0
            local integer l = StringLength(this.info)
            local integer c = 0
            local integer j = 0
            local integer safeSpot = 0
            local string line = ""
            local string safe = ""
            local string char
        
            if (StringLength(.lTrim(this.info)) <= 0) then
                return startLine - 1
            endif
            
            loop
                exitwhen i > l
                
                set char = SubString(this.info, i, i + 1)

                if (char == "\n" or c >= Inventory.TOOLTIP_LINE_LENGTH) then
                    if (char != " " and char != "\n") then
                        set line = safe
                        
                        set i = safeSpot
                    endif
                    
                    call Inventory.setTooltipLine(pid, startLine + j, .lTrim(line))
    
                    set line = ""
                    
                    if (char != "\n") then
                        set i = i - 1
                    endif
                    
                    set char = ""
                    
                    set c = 0
                    set j = j + 1
                endif
                
                if (char == " ") then
                    set safe = line
                    set safeSpot = i
                endif
                
                set line = line + char
                
                set c = c + 1
                set i = i + 1
            endloop
            
            if (j == 0) then
                call Inventory.setTooltipLine(pid, startLine, .lTrim(line))
            elseif (line != "") then
                call Inventory.setTooltipLine(pid, startLine + j, .lTrim(line))
            endif
            
            return (startLine + j) + 1
        endmethod
    endmodule
    
endlibrary
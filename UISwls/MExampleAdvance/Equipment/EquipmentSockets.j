library EquipmentSockets

    module InvItemSocket
        integer maxSockets
        boolean isSocket
        
        static hashtable SocketTable = InitHashtable()
        
        method operator sockets takes nothing returns integer
            return LoadInteger(.SocketTable, this.tempCustomId, KEY_SOCKETS_COUNT*100)
        endmethod
        
        method operator sockets= takes integer val returns nothing
            call SaveInteger(.SocketTable, this.tempCustomId, KEY_SOCKETS_COUNT*100, val)
        endmethod
        
        method socketId takes integer index returns integer
            return LoadInteger(.SocketTable, this.tempCustomId, (KEY_SOCKETS_ID*100) + index)
        endmethod
        
        private static key KEY_SOCKETS
        private static key KEY_SOCKETS_ID
        private static key KEY_SOCKETS_COUNT
        
        method addSocket takes InvItem socket returns boolean
            if this.isSocket then
                return false
            endif
            
            if (this.sockets >= this.maxSockets) then
                return false
            endif
            
            call SaveInteger(.SocketTable, this.tempCustomId, (KEY_SOCKETS*100) + this.sockets, socket)
            call SaveInteger(.SocketTable, this.tempCustomId, (KEY_SOCKETS_ID*100) + this.sockets, socket.tempCustomId)
            
            set this.sockets = this.sockets + 1
            
            return true
        endmethod
        
        method getSocket takes integer index returns InvItem
            if this.isSocket then
                return 0
            endif
            
            return LoadInteger(.SocketTable, this.tempCustomId, (KEY_SOCKETS*100) + index)
        endmethod
        
    endmodule

endlibrary
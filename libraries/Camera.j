library Camera requires UIMath, PlayerUtils

    globals
        // configuration   
        
        // location on the map where the terrain is the default level
        constant real CHECK_DELTAZ_X = -1200
        constant real CHECK_DELTAZ_Y = 950
        
        constant real SCREEN_WIDTH  = 0.544
        constant real SCREEN_HEIGHT = 0.302
        
        constant real SCREEN_ASPECT_RATIO = SCREEN_WIDTH/SCREEN_HEIGHT
        
        constant integer CAMERA_DUMMY_TYPE  = 'e001'
        constant player CAMERA_DUMMY_PLAYER = Player(bj_PLAYER_NEUTRAL_EXTRA)
        
        private real DeltaZ = 0

        public unit array DummyUnit
        public location DummyLoc = Location(0,0)
    endglobals

    function GetTerrainZ takes real x, real y returns real
        call MoveLocation(DummyLoc, x, y)
        return GetLocationZ(DummyLoc)
    endfunction
    
    function GetCameraDeltaZ takes nothing returns real
        return DeltaZ
    endfunction
    
    private function Matrix4Perspective1 takes MATRIX4 Output, real fovy, real Aspect, real zn, real zf returns MATRIX4
        return Output.SetValues(2*zn/fovy,0,0,0,0,2*zn/Aspect,0,0,0,0,zf/(zf-zn),1,0,0,zn*zf/(zn-zf),0)
    endfunction

    private function Matrix4Perspective2 takes MATRIX4 Output, real n, real f, real r, real l, real t, real b returns MATRIX4
        return Output.SetValues(2*n/(r-l), 0, (r+l)/(r-l), 0, 0, 2*n/(t-b), (t+b)/(t-b), 0, 0, 0, -(f+n)/(f-n), -2*f*n/(f-n), 0, 0, -1, 0)
    endfunction

    private function Matrix4Look takes MATRIX4 Output, VECTOR3 PosCamera, VECTOR3 AxisX, VECTOR3 AxisY, VECTOR3 AxisZ returns MATRIX4
        return Output.SetValues(AxisX.x,AxisY.x,AxisZ.x,0,AxisX.y,AxisY.y,AxisZ.y,0,AxisX.z,AxisY.z,AxisZ.z,0,-Vec3Dot(AxisX, PosCamera),-Vec3Dot(AxisY, PosCamera),-Vec3Dot(AxisZ, PosCamera),1)
    endfunction

    struct Camera
        VECTOR3 eye
        VECTOR3 at
        unit target
        real distance
        real yaw
        real pitch
        real roll
        VECTOR3 axisX
        VECTOR3 axisY
        VECTOR3 axisZ
        private MATRIX4 view
        private MATRIX4 projection
        private boolean change
        integer customValue
        
        method win2World takes real X, real Y, real Range returns VECTOR3
            local VECTOR3 Output = VECTOR3.create()
            set Output.x = .eye.x+.axisZ.x*Range+X*.axisX.x*SCREEN_WIDTH*Range+Y*.axisY.x*SCREEN_HEIGHT*Range
            set Output.y = .eye.y+.axisZ.y*Range+X*.axisX.y*SCREEN_WIDTH*Range+Y*.axisY.y*SCREEN_HEIGHT*Range
            set Output.z = .eye.z+.axisZ.z*Range+X*.axisX.z*SCREEN_WIDTH*Range+Y*.axisY.z*SCREEN_HEIGHT*Range
            return Output
        endmethod

        method world2Win takes real X, real Y, real Z returns VECTOR3
            local VECTOR3 Pos = VECTOR3.New_1(X, Y, Z)
            local boolean b
            call Vec3Transform_2(Pos, Pos, .view)
            set b = Pos.z < 0
            call Vec3Transform_2(Pos, Pos, .projection)
            if b then
                set Pos.z = -Pos.z
            endif
            return Pos
        endmethod
        
        private method updateDistanceYawPitch takes nothing returns nothing
            local real dx = .at.x-.eye.x
            local real dy = .at.y-.eye.y
            local real dz = .at.z-.eye.z
            local real len2d
            set .distance = SquareRoot(dx*dx+dy*dy+dz*dz)
            set .yaw = Atan2(dy, dx)
            set len2d = SquareRoot(dx*dx+dy*dy)
            set .pitch = Atan2(dz, len2d)
        endmethod
        
        private method updateAxisMatrix takes nothing returns nothing
            local MATRIX3 mat
            call Vec3Normalize(.axisZ, Vec3Subtract(.axisZ, .at, .eye))
            set mat = Matrix3RotationAxis(MATRIX3.create(), .axisZ, -.roll)
            call Vec3Normalize(.axisX, Vec3Cross(.axisX, .axisZ, VECTOR3.oneZ))
            call Vec3Transform_1(.axisY, Vec3Cross(.axisY, .axisX, .axisZ), mat)
            call Vec3Transform_1(.axisX, .axisX, mat)
            call Matrix4Look(.view, .eye, .axisX, .axisY, .axisZ)
            call mat.destroy()
        endmethod

        method applyCameraForPlayer takes player p, boolean ignoreChange returns boolean
            if GetLocalPlayer() == p then
                call SetCameraField(CAMERA_FIELD_ROTATION, .yaw*bj_RADTODEG, 0)
                call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, .pitch*bj_RADTODEG, 0)
                call SetCameraField(CAMERA_FIELD_ROLL, .roll*bj_RADTODEG, 0)
                call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, .distance, 0)
                call SetCameraTargetController(DummyUnit[GetPlayerId(p)], .at.x, .at.y, false)
                call SetCameraField(CAMERA_FIELD_ZOFFSET, .at.z-DeltaZ, 0)
                call SetCameraField(CAMERA_FIELD_FARZ, 10000.00, 0.00)
            endif
            if .change or ignoreChange then
                set .change = false
                return true
            endif
            return false
        endmethod

        method setPosition takes real x, real y, real z returns nothing
            local real dx = x-.at.x
            local real dy = y-.at.y
            local real dz = z-.at.z
            set .eye.x = .eye.x+dx
            set .eye.y = .eye.y+dy
            set .eye.z = .eye.z+dz
            set .at.x = x
            set .at.y = y
            set .at.z = z
            set .change = true
        endmethod
        
        method setEyeAndAt takes real ex, real ey, real ez, real tx, real ty, real tz returns nothing
            set .eye.x = ex
            set .eye.y = ey
            set .eye.z = ez
            set .at.x = tx
            set .at.y = ty
            set .at.z = tz
            call .updateDistanceYawPitch()
            call .updateAxisMatrix()
            set .change = true
        endmethod
        
        method setYawPitchRoll takes real yaw, real pitch, real roll, boolean EyeLock returns nothing
            local real Z = .distance*Sin(pitch)
            local real XY = .distance*Cos(pitch)
            local real X = XY*Cos(yaw)
            local real Y = XY*Sin(yaw)
            set .yaw = yaw
            set .pitch = pitch
            set .roll = roll
            if EyeLock then
                set .at.x = .eye.x+X
                set .at.y = .eye.y+Y
                set .at.z = .eye.z+Z
            else
                set .eye.x = .at.x-X
                set .eye.y = .at.y-Y
                set .eye.z = .at.z-Z
            endif
            call .updateAxisMatrix()
            set .change = true
        endmethod
        
        static method create takes nothing returns thistype
            local thistype this = thistype.allocate()
            
            set .customValue = 0
            set .change = true
            set .eye = VECTOR3.New_1(0.0,-922.668,DeltaZ+1367.912)
            set .at = VECTOR3.New_1(0, 0, DeltaZ)
            set .distance = 0
            set .yaw = 0
            set .pitch = 0
            set .roll = 0
            set .axisX = VECTOR3.create()
            set .axisY = VECTOR3.create()
            set .axisZ = VECTOR3.create()
            set .view  = MATRIX4.create()
            set .projection = Matrix4Perspective2(MATRIX4.create(), 0.5, 10000, -SCREEN_WIDTH/2, SCREEN_WIDTH/2, -SCREEN_HEIGHT/2, SCREEN_HEIGHT/2)
            call .updateDistanceYawPitch()
            call .updateAxisMatrix()
            
            return this
        endmethod
        
        method destroy takes nothing returns nothing
            call .eye.destroy()
            call .at.destroy()
            call .axisX.destroy()
            call .axisY.destroy()
            call .axisZ.destroy()
            call .view.destroy()
            call .projection.destroy()
            call this.destroy()
        endmethod
        
    endstruct

    private module CamInitModule
        private static method onInit takes nothing returns nothing
            local integer i = 0
            local User user
            
            loop
                exitwhen i == User.AmountPlaying
                
                set user = User.fromPlaying(i)
                
                set DummyUnit[user.id] = CreateUnit(CAMERA_DUMMY_PLAYER, CAMERA_DUMMY_TYPE, 0, 0, 0)
                call ShowUnit(DummyUnit[user.id], false)
                call PauseUnit(DummyUnit[user.id], true)
                
                set i = i + 1
            endloop
            
            // init delta z
            call SetCameraPosition(CHECK_DELTAZ_X, CHECK_DELTAZ_Y)
            set DeltaZ = GetCameraTargetPositionZ() - 6
        endmethod
    endmodule
    
    private struct CamInit
        implement CamInitModule
    endstruct
    
endlibrary

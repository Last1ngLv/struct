library UIMath initializer Init

    public function R2I_N takes real r returns integer
        local integer i = R2I(r)
        if (r < I2R(i)+0.5) then
            return i
        else
            return i+1
        endif
    endfunction

    struct VECTOR3
        static VECTOR3 Zero
        static VECTOR3 oneX
        static VECTOR3 oneY
        static VECTOR3 oneZ
        real x
        real y
        real z
        
        static method New_0 takes nothing returns VECTOR3
            local VECTOR3 this = VECTOR3.create()
            set .x = 0
            set .y = 0
            set .z = 0
            return this
        endmethod
        
        static method New_1 takes real x, real y, real z returns VECTOR3
            local VECTOR3 this = VECTOR3.create()
            set .x = x
            set .y = y
            set .z = z
            return this
        endmethod
        
        static method New_2 takes VECTOR3 v returns VECTOR3
            local VECTOR3 this = VECTOR3.create()
            set .x = v.x
            set .y = v.y
            set .z = v.z
            return this
        endmethod
        
        method SetValues takes real x, real y, real z returns VECTOR3
            set .x = x
            set .y = y
            set .z = z
            return this
        endmethod
        
        method Length takes nothing returns real
            return SquareRoot(.x*.x+.y*.y+.z*.z)
        endmethod
        
        method LengthSq takes nothing returns real
            return .x*.x+.y*.y+.z*.z
        endmethod
        
        method ToString takes nothing returns string
            return "Vector3 id "+I2S(this) + "\nx = "+R2S(.x)+"   y = "+R2S(.y)+"   z = "+R2S(.z)
        endmethod
        
    endstruct

    function Vec3Add takes VECTOR3 Output, VECTOR3 v1, VECTOR3 v2 returns VECTOR3
        set Output.x = v1.x + v2.x
        set Output.y = v1.y + v2.y
        set Output.z = v1.z + v2.z
        return Output
    endfunction

    function Vec3Subtract takes VECTOR3 Output, VECTOR3 v1, VECTOR3 v2 returns VECTOR3
        set Output.x = v1.x - v2.x
        set Output.y = v1.y - v2.y
        set Output.z = v1.z - v2.z
        return Output
    endfunction
        
    function Vec3Scale takes VECTOR3 Output, VECTOR3 v, real r returns VECTOR3
        set Output.x = v.x * r
        set Output.y = v.y * r
        set Output.z = v.z * r
        return Output
    endfunction
        
    function Vec3Division takes VECTOR3 Output, VECTOR3 v, real r returns VECTOR3
        set Output.x = v.x / r
        set Output.y = v.y / r
        set Output.z = v.z / r
        return Output
    endfunction

    function Vec3Length takes VECTOR3 v returns real
        return SquareRoot(v.x*v.x+v.y*v.y+v.z*v.z)
    endfunction

    function Vec3LengthSq takes VECTOR3 v returns real
        return v.x*v.x+v.y*v.y+v.z*v.z
    endfunction

    function Vec3Normalize takes VECTOR3 Output, VECTOR3 v returns VECTOR3
        local real len = SquareRoot(v.x*v.x+v.y*v.y+v.z*v.z)
        set Output.x = v.x/len
        set Output.y = v.y/len
        set Output.z = v.z/len
        return Output
    endfunction

    function Vec3Dot takes VECTOR3 v1, VECTOR3 v2 returns real
        return v1.x*v2.x+v1.y*v2.y+v1.z*v2.z
    endfunction

    function Vec3Cross takes VECTOR3 Output, VECTOR3 v1, VECTOR3 v2 returns VECTOR3
        local real y  = v1.z * v2.x - v1.x * v2.z
        local real z = v1.x * v2.y - v1.y * v2.x
        set Output.x = v1.y * v2.z - v1.z * v2.y
        set Output.y = y
        set Output.z = z
        return Output
    endfunction

    function Vec3Transform_1 takes VECTOR3 Output, VECTOR3 v, MATRIX3 m returns VECTOR3
        local real y = v.x*m.m12+v.y*m.m22+v.z*m.m32
        local real z = v.x*m.m13+v.y*m.m23+v.z*m.m33
        set Output.x = v.x*m.m11+v.y*m.m21+v.z*m.m31
        set Output.y = y
        set Output.z = z
        return Output
    endfunction

    function Vec3Transform_2 takes VECTOR3 Output, VECTOR3 v, MATRIX4 m returns VECTOR3
        local real y = v.x*m.m12+v.y*m.m22+v.z*m.m32+m.m42
        local real z = v.x*m.m13+v.y*m.m23+v.z*m.m33+m.m43
        local real w = v.x*m.m14+v.y*m.m24+v.z*m.m34+m.m44
        set Output.x = (v.x*m.m11+v.y*m.m21+v.z*m.m31+m.m41)/w
        set Output.y = y/w
        set Output.z = z/w
        return Output
    endfunction


    struct MATRIX3
        static MATRIX3 Zero
        static MATRIX3 E
        real m11
        real m12
        real m13
        real m21
        real m22
        real m23
        real m31
        real m32
        real m33
        
        static method New_0 takes nothing returns MATRIX3
            local MATRIX3 this = MATRIX3.create()
            set .m11 = 0
            set .m12 = 0
            set .m13 = 0
            set .m21 = 0
            set .m22 = 0
            set .m23 = 0
            set .m31 = 0
            set .m32 = 0
            set .m33 = 0
            return this
        endmethod
        
        static method New_1 takes real r11, real r12, real r13, real r21, real r22, real r23, real r31, real r32, real r33 returns MATRIX3
            local MATRIX3 this = MATRIX3.create()
            set .m11 = r11
            set .m12 = r12
            set .m13 = r13
            set .m21 = r21
            set .m22 = r22
            set .m23 = r23
            set .m31 = r31
            set .m32 = r32
            set .m33 = r33
            return this
        endmethod
        
        static method New_2 takes MATRIX3 m returns MATRIX3
            local MATRIX3 this = MATRIX3.create()
            set .m11 = m.m11
            set .m12 = m.m12
            set .m13 = m.m13
            set .m21 = m.m21
            set .m22 = m.m22
            set .m23 = m.m23
            set .m31 = m.m31
            set .m32 = m.m32
            set .m33 = m.m33
            return this
        endmethod
        
        method SetValues takes real r11, real r12, real r13, real r21, real r22, real r23, real r31, real r32, real r33 returns MATRIX3
            set .m11 = r11
            set .m12 = r12
            set .m13 = r13
            set .m21 = r21
            set .m22 = r22
            set .m23 = r23
            set .m31 = r31
            set .m32 = r32
            set .m33 = r33
            return this
        endmethod
     
        method ToString takes nothing returns string
            return "Matrux3 id "+I2S(this)+"\n"+R2S(.m11)+"  "+R2S(.m12)+"  "+R2S(.m13)+"\n"+R2S(.m21)+"  "+R2S(.m22)+"  "+R2S(.m23)+"\n"+R2S(.m31)+"  "+R2S(.m32)+"  "+R2S(.m33)
        endmethod
        
    endstruct

    function Matrix3Multiply takes MATRIX3 Output, MATRIX3 M1, MATRIX3 M2 returns MATRIX3  
        return Output.SetValues(M1.m11*M2.m11+M1.m21*M2.m12+M1.m31*M2.m13,M1.m12*M2.m11+M1.m22*M2.m12+M1.m32*M2.m13,M1.m13*M2.m11+M1.m23*M2.m12+M1.m33*M2.m13,M1.m11*M2.m21+M1.m21*M2.m22+M1.m31*M2.m23,M1.m12*M2.m21+M1.m22*M2.m22+M1.m32*M2.m23,M1.m13*M2.m21+M1.m23*M2.m22+M1.m33*M2.m23,M1.m11*M2.m31+M1.m21*M2.m32+M1.m31*M2.m33,M1.m12*M2.m31+M1.m22*M2.m32+M1.m32*M2.m33,M1.m13*M2.m31+M1.m23*M2.m32+M1.m33*M2.m33)
    endfunction

    function Matrix3Scaling takes MATRIX3 Output, real x, real y, real z returns MATRIX3
        return Output.SetValues(x,0,0,0,y,0,0,0,z)
    endfunction

    function Matrix3RotationX takes MATRIX3 Output, real a returns MATRIX3
        return Output.SetValues(1,0,0,0,Cos(a),-Sin(a),0,Sin(a),Cos(a))
    endfunction

    function Matrix3RotationY takes MATRIX3 Output, real a returns MATRIX3
        return Output.SetValues(Cos(a),0,Sin(a),0,1,0,-Sin(a),0,Cos(a))
    endfunction

    function Matrix3RotationZ takes MATRIX3 Output, real a returns MATRIX3
        return Output.SetValues(Cos(a),-Sin(a),0,Sin(a),Cos(a),0,0,0,1)
    endfunction

    function Matrix3RotationAxis takes MATRIX3 Output, VECTOR3 v, real a returns MATRIX3
        local real cosa = Cos(a)
        local real sina = Sin(a)
        return Output.SetValues(cosa+(1-cosa)*v.x*v.x,(1-cosa)*v.x*v.y-sina*v.z,(1-cosa)*v.x*v.z+sina*v.y,(1-cosa)*v.y*v.x+sina*v.z,cosa+(1-cosa)*v.y*v.y,(1-cosa)*v.y*v.z-sina*v.x,(1-cosa)*v.z*v.x-sina*v.y,(1-cosa)*v.z*v.y+sina*v.x,cosa+(1-cosa)*v.z*v.z)
    endfunction

    function Matrix3RotationYawPitchRoll takes MATRIX3 Output, real Yaw, real Pitch, real Roll returns MATRIX3
        local real cosa = Cos(Yaw)
        local real sina = Sin(Yaw)
        local real cosb = Cos(Pitch)
        local real sinb = Sin(Pitch)
        local real cosy = Cos(Roll)
        local real siny = Sin(Roll)
        return Output.SetValues(cosa*cosb,cosa*sinb*siny-sina*cosy,cosa*sinb*cosy+sina*siny,sina*cosb,sina*sinb*siny+cosa*cosy,sina*sinb*cosy-cosa*siny,-sinb,cosb*siny,cosb*cosy)
    endfunction

    struct MATRIX4
        static MATRIX4 Zero
        static MATRIX4 E
        real m11
        real m12
        real m13
        real m14
        real m21
        real m22
        real m23
        real m24
        real m31
        real m32
        real m33
        real m34
        real m41
        real m42
        real m43
        real m44
        
        static method New_0 takes nothing returns MATRIX4
            local MATRIX4 this = MATRIX4.create()
            set .m11 = 0
            set .m12 = 0
            set .m13 = 0
            set .m14 = 0
            set .m21 = 0
            set .m22 = 0
            set .m23 = 0
            set .m24 = 0
            set .m31 = 0
            set .m32 = 0
            set .m33 = 0
            set .m34 = 0
            set .m41 = 0
            set .m42 = 0
            set .m43 = 0
            set .m44 = 0
            return this
        endmethod
        
        static method New_1 takes real r11, real r12, real r13, real r14, real r21, real r22, real r23, real r24, real r31, real r32, real r33, real r34, real r41, real r42, real r43, real r44 returns MATRIX4
            local MATRIX4 this = MATRIX4.create()
            set .m11 = r11
            set .m12 = r12
            set .m13 = r13
            set .m14 = r14
            set .m21 = r21
            set .m22 = r22
            set .m23 = r23
            set .m24 = r24
            set .m31 = r31
            set .m32 = r32
            set .m33 = r33
            set .m34 = r34
            set .m41 = r41
            set .m42 = r42
            set .m43 = r43
            set .m44 = r44
            return this
        endmethod
        
        static method New_2 takes MATRIX4 m returns MATRIX4
            local MATRIX4 this = MATRIX4.create()
            set .m11 = m.m11
            set .m12 = m.m12
            set .m13 = m.m13
            set .m14 = m.m14
            set .m21 = m.m21
            set .m22 = m.m22
            set .m23 = m.m23
            set .m24 = m.m24
            set .m31 = m.m31
            set .m32 = m.m32
            set .m33 = m.m33
            set .m34 = m.m34
            set .m41 = m.m41
            set .m42 = m.m42
            set .m43 = m.m43
            set .m44 = m.m44
            return this
        endmethod
        
        static method New_3 takes MATRIX3 m returns MATRIX4
            local MATRIX4 this = MATRIX4.create()
            set .m11 = m.m11
            set .m12 = m.m12
            set .m13 = m.m13
            set .m14 = 0
            set .m21 = m.m21
            set .m22 = m.m22
            set .m23 = m.m23
            set .m24 = 0
            set .m31 = m.m31
            set .m32 = m.m32
            set .m33 = m.m33
            set .m34 = 0
            set .m41 = 0
            set .m42 = 0
            set .m43 = 0
            set .m44 = 1
            return this
        endmethod
        
        method SetValues takes real r11, real r12, real r13, real r14, real r21, real r22, real r23, real r24, real r31, real r32, real r33, real r34, real r41, real r42, real r43, real r44 returns MATRIX4
            set .m11 = r11
            set .m12 = r12
            set .m13 = r13
            set .m14 = r14
            set .m21 = r21
            set .m22 = r22
            set .m23 = r23
            set .m24 = r24
            set .m31 = r31
            set .m32 = r32
            set .m33 = r33
            set .m34 = r34
            set .m41 = r41
            set .m42 = r42
            set .m43 = r43
            set .m44 = r44
            return this
        endmethod
     
        method ToString takes nothing returns string
            return "Matrux4 id "+I2S(this)+"\n"+R2S(.m11)+"  "+R2S(.m12)+"  "+R2S(.m13)+"  "+R2S(.m14)+"\n"+R2S(.m21)+"  "+R2S(.m22)+"  "+R2S(.m23)+"  "+R2S(.m24)+"\n"+R2S(.m31)+"  "+R2S(.m32)+"  "+R2S(.m33)+"  "+R2S(.m34)+"\n"+R2S(.m41)+"  "+R2S(.m42)+"  "+R2S(.m43)+"  "+R2S(.m44)
        endmethod
        
    endstruct

    function Matrix4Multiply takes MATRIX4 Output, MATRIX4 M1, MATRIX4 M2 returns MATRIX4
        return Output.SetValues(M1.m11*M2.m11+M1.m21*M2.m12+M1.m31*M2.m13+M1.m41*M2.m14,M1.m12*M2.m11+M1.m22*M2.m12+M1.m32*M2.m13+M1.m42*M2.m14,M1.m13*M2.m11+M1.m23*M2.m12+M1.m33*M2.m13+M1.m43*M2.m14,M1.m14*M2.m11+M1.m24*M2.m12+M1.m34*M2.m13+M1.m44*M2.m14,M1.m11*M2.m21+M1.m21*M2.m22+M1.m31*M2.m23+M1.m41*M2.m24,M1.m12*M2.m21+M1.m22*M2.m22+M1.m32*M2.m23+M1.m42*M2.m24,M1.m13*M2.m21+M1.m23*M2.m22+M1.m33*M2.m23+M1.m43*M2.m24,M1.m14*M2.m21+M1.m24*M2.m22+M1.m34*M2.m23+M1.m44*M2.m24,M1.m11*M2.m31+M1.m21*M2.m32+M1.m31*M2.m33+M1.m41*M2.m34,M1.m12*M2.m31+M1.m22*M2.m32+M1.m32*M2.m33+M1.m42*M2.m34,M1.m13*M2.m31+M1.m23*M2.m32+M1.m33*M2.m33+M1.m43*M2.m34,M1.m14*M2.m31+M1.m24*M2.m32+M1.m34*M2.m33+M1.m44*M2.m34,M1.m11*M2.m41+M1.m21*M2.m42+M1.m31*M2.m43+M1.m41*M2.m44,M1.m12*M2.m41+M1.m22*M2.m42+M1.m32*M2.m43+M1.m42*M2.m44,M1.m13*M2.m41+M1.m23*M2.m42+M1.m33*M2.m43+M1.m43*M2.m44,M1.m14*M2.m41+M1.m24*M2.m42+M1.m34*M2.m43+M1.m44*M2.m44)
    endfunction

    private function Init takes nothing returns nothing
       set VECTOR3.Zero = VECTOR3.New_0()
       set VECTOR3.oneX = VECTOR3.New_1(1,0,0)
       set VECTOR3.oneY = VECTOR3.New_1(0,1,0)
       set VECTOR3.oneZ = VECTOR3.New_1(0,0,1)
       set MATRIX3.Zero = MATRIX3.New_0()
       set MATRIX3.E = MATRIX3.New_1(1,0,0,0,1,0,0,0,1)
       set MATRIX4.Zero = MATRIX4.New_0()
       set MATRIX4.E = MATRIX4.New_1(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1)
    endfunction

endlibrary
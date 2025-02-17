from math import tan, cos, sin

struct Mat4:
    var value: SIMD[DType.float32, 16]

    @always_inline
    fn __init__(
        mut self: Mat4,
        xx: Float32, xy: Float32, xz: Float32, xw: Float32,
        yx: Float32, yy: Float32, yz: Float32, yw: Float32,
        zx: Float32, zy: Float32, zz: Float32, zw: Float32,
        wx: Float32, wy: Float32, wz: Float32, ww: Float32,
    ):
        self.value = SIMD[DType.float32, 16](
            xx, xy, xz, xw,
            yx, yy, yz, yw,
            zx, zy, zz, zw,
            wx, wy, wz, ww,
        )
    
    @always_inline
    fn __copyinit__(out self, other: Mat4):
        self.value = other.value

    @staticmethod
    fn zero() -> Mat4:
        """
        Returns a 4x4 matrix filled with zeros.
        """
        return Mat4(
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0
        )

    @staticmethod
    fn identity() -> Mat4:
        """
        Returns the identity matrix (diagonal of 1s).
        """
        return Mat4(
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        )

    @staticmethod
    fn translation(tx: Float32, ty: Float32, tz: Float32) -> Mat4:
        """
        Returns a translation matrix.
        """
        return Mat4(
            1.0, 0.0, 0.0, tx,
            0.0, 1.0, 0.0, ty,
            0.0, 0.0, 1.0, tz,
            0.0, 0.0, 0.0, 1.0
        )

    @staticmethod
    fn scaling(sx: Float32, sy: Float32, sz: Float32) -> Mat4:
        """
        Returns a scaling matrix.
        """
        return Mat4(
            sx, 0.0, 0.0, 0.0,
            0.0, sy, 0.0, 0.0,
            0.0, 0.0, sz, 0.0,
            0.0, 0.0, 0.0, 1.0
        )

    @staticmethod
    fn rotation_x(angle: Float32) -> Mat4:
        """
        Returns a rotation matrix around the X-axis.
        """
        c = cos(angle)
        s = sin(angle)
        return Mat4(
            1.0, 0.0, 0.0, 0.0,
            0.0, c, -s, 0.0,
            0.0, s, c, 0.0,
            0.0, 0.0, 0.0, 1.0
        )

    @staticmethod
    fn rotation_y(angle: Float32) -> Mat4:
        """
        Returns a rotation matrix around the Y-axis.
        """
        c = cos(angle)
        s = sin(angle)
        return Mat4(
            c, 0.0, s, 0.0,
            0.0, 1.0, 0.0, 0.0,
            -s, 0.0, c, 0.0,
            0.0, 0.0, 0.0, 1.0
        )

    @staticmethod
    fn rotation_z(angle: Float32) -> Mat4:
        """
        Returns a rotation matrix around the Z-axis.
        """
        c = cos(angle)
        s = sin(angle)
        return Mat4(
            c, -s, 0.0, 0.0,
            s, c, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0
        )

    @staticmethod
    fn perspective(fov: Float32, aspect_width: Float32, aspect_height: Float32, near: Float32, far: Float32) -> Mat4:
        """
        Returns a perspective projection matrix.
        """
        f = 1.0 / tan(fov / 2.0)
        return Mat4(
            f / (aspect_height/aspect_width), 0.0, 0.0, 0.0,
            0.0, f, 0.0, 0.0,
            0.0, 0.0, (far + near) / (near - far), (2.0 * far * near) / (near - far),
            0.0, 0.0, -1.0, 0.0
        )

    @always_inline
    fn __getitem__(self: Mat4, i: Int) -> Float32:
        return self.value[i]

    @always_inline
    fn __setitem__(mut self: Mat4, i: Int, value: Float32):
        self.value[i] = value

    @always_inline
    fn __mul__(self: Mat4, other: Mat4) -> Mat4:
        """
        Multiplies two matrices.
        """
        result = Mat4.zero()
        for y in range(4):
            for x in range(4):
                var sum_value: Float32 = 0.0
                for k in range(4):
                    sum_value += self[k * 4 + x] * other[y * 4 + k]
                result[y * 4 + x] = sum_value
        return result

const std = @import("../../index.zig");
const debug = std.debug;
const math = std.math;
const cmath = math.complex;
const Complex = cmath.Complex;

pub fn ldexp_cexp(z: var, expt: i32) Complex(@typeOf(z.re)) {
    const T = @typeOf(z.re);

    return switch (T) {
        f32 => ldexp_cexp32(z, expt),
        f64 => ldexp_cexp64(z, expt),
        else => unreachable,
    };
}

fn frexp_exp32(x: f32, expt: *i32) f32 {
    const k = 235; // reduction constant
    const kln2 = 162.88958740; // k * ln2

    const exp_x = math.exp(x - kln2);
    const hx = @bitCast(u32, exp_x);
    expt.* = i32(hx >> 23) - (0x7f + 127) + k;
    return @bitCast(f32, (hx & 0x7fffff) | ((0x7f + 127) << 23));
}

fn ldexp_cexp32(z: *const Complex(f32), expt: i32) Complex(f32) {
    var ex_expt: i32 = undefined;
    const exp_x = frexp_exp32(z.re, &ex_expt);
    const exptf = expt + ex_expt;

    const half_expt1 = @divTrunc(exptf, 2);
    const scale1 = @bitCast(f32, (0x7f + half_expt1) << 23);

    const half_expt2 = exptf - half_expt1;
    const scale2 = @bitCast(f32, (0x7f + half_expt2) << 23);

    return Complex(f32).new(math.cos(z.im) * exp_x * scale1 * scale2, math.sin(z.im) * exp_x * scale1 * scale2);
}

fn frexp_exp64(x: f64, expt: *i32) f64 {
    const k = 1799; // reduction constant
    const kln2 = 1246.97177782734161156; // k * ln2

    const exp_x = math.exp(x - kln2);

    const fx = @bitCast(u64, x);
    const hx = u32(fx >> 32);
    const lx = @truncate(u32, fx);

    expt.* = i32(hx >> 20) - (0x3ff + 1023) + k;

    const high_word = (hx & 0xfffff) | ((0x3ff + 1023) << 20);
    return @bitCast(f64, (u64(high_word) << 32) | lx);
}

fn ldexp_cexp64(z: *const Complex(f64), expt: i32) Complex(f64) {
    var ex_expt: i32 = undefined;
    const exp_x = frexp_exp64(z.re, &ex_expt);
    const exptf = i64(expt + ex_expt);

    const half_expt1 = @divTrunc(exptf, 2);
    const scale1 = @bitCast(f64, (0x3ff + half_expt1) << 20);

    const half_expt2 = exptf - half_expt1;
    const scale2 = @bitCast(f64, (0x3ff + half_expt2) << 20);

    return Complex(f64).new(
        math.cos(z.im) * exp_x * scale1 * scale2,
        math.sin(z.im) * exp_x * scale1 * scale2,
    );
}

const std = @import("std");
const builtin = @import("builtin");
const common = @import("common.zig");

const linux = std.os.linux;
const assert = std.debug.assert;
const abort = std.posix.abort;

comptime {
    // When libc is linked, do not export our own version of `__tls_get_addr`
    if (!builtin.link_libc and builtin.os.tag == .linux) {
        switch (builtin.cpu.arch) {
            .x86_64 => @export(&__tls_get_addr_linux_x86_64, .{ .name = "__tls_get_addr", .linkage = common.linkage, .visibility = common.visibility }),
            .aarch64, .aarch64_be => @export(&__tls_get_addr_linux_aarch64, .{ .name = "__tls_get_addr", .linkage = common.linkage, .visibility = common.visibility }),
            else => {},
        }
    }
}

const TlsIndex = extern struct {
    ti_module: usize,
    ti_offset: usize,
};

const DtvPointer = extern struct {
    val: *anyopaque,
    to_free: *anyopaque,
};

const Dtv = extern union {
    counter: usize,
    pointer: DtvPointer,
};

pub fn __tls_get_addr_linux_x86_64(tls_index: *TlsIndex) callconv(.c) *anyopaque {
    // Get dtv address without a `arch_prctl` syscall
    //
    // The aternative way would be:
    // ```
    // const ret = @call(.always_inline, linux.syscall2, .{ .arch_prctl, linux.ARCH.GET_FS, @intFromPtr(&addr) });
    // assert(ret == 0);
    // ```

    const addr = asm volatile ("mov %fs:0, %[ret]"
        : [ret] "=r" (-> usize),
    );

    // Use the general way of getting the requested variable address
    // We assume that information is layout like what standard dynamic linker does
    // We also assume that the dtv entry is already allocated
    const dtv: [*]Dtv = @ptrFromInt(addr);
    const var_addr = @intFromPtr(&dtv[tls_index.ti_module].pointer) + tls_index.ti_offset;

    return @ptrFromInt(var_addr);
}

pub fn __tls_get_addr_linux_aarch64(tls_index: *TlsIndex) callconv(.c) *anyopaque {
    const addr = asm volatile ("mrs %[ret], tpidr_el0"
        : [ret] "=r" (-> usize),
    );

    // Use the general way of getting the requested variable address
    // We assume that information is layout like what standard dynamic linker does
    // We also assume that the dtv entry is already allocated
    const dtv: [*]Dtv = @ptrFromInt(addr);
    const var_addr = @intFromPtr(&dtv[tls_index.ti_module].pointer) + tls_index.ti_offset;

    return @ptrFromInt(var_addr);
}

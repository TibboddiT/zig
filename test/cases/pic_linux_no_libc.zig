const std = @import("std");

// As soon as a new implementation of __tls_get_addr is included in compiler_rt, corresponding arch should be added to this test
pub fn main() void {}

// run
// backend=stage2,llvm
// target=aarch64-linux,aarch64_be-linux,x86_64-linux
// pic=true

const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });
    const optimize = b.standardOptimizeOption(.{});

    const module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Export WASM-4 symbols
    module.export_symbol_names = &[_][]const u8{ "start", "update" };

    const lib = b.addExecutable(.{
        .name = "cart",
        .root_module = module,
        .version = try std.SemanticVersion.parse("1.0.2"),
    });

    lib.entry = .disabled;
    lib.import_memory = true;
    lib.initial_memory = 65536;
    lib.max_memory = 65536;
    lib.stack_size = 14752;

    b.installArtifact(lib);
}

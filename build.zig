const std = @import("std");

/// Main build entry point
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build options
    const pic = b.option(bool, "pic", "Position Independent Code") orelse true;
    const optimize_for_size = b.option(bool, "optimize-size", "Optimize for size instead of speed") orelse false;
    const strip_debug = b.option(bool, "strip", "Strip debug symbols") orelse true;

    // C source files for libpostal library
    // Note: Data files like *_data.c are #included by other sources, not compiled separately
    const c_sources = [_][]const u8{
        "src/strndup.c",
        "src/libpostal.c",
        "src/expand.c",
        "src/address_dictionary.c",
        "src/transliterate.c",
        "src/tokens.c",
        "src/trie.c",
        "src/trie_search.c",
        "src/trie_utils.c",
        "src/string_utils.c",
        "src/file_utils.c",
        "src/utf8proc/utf8proc.c",
        // Note: utf8proc_data.c is included by utf8proc.c, not compiled separately
        "src/normalize.c",
        "src/numex.c",
        "src/libpostal_features.c",
        "src/unicode_scripts.c",
        "src/address_parser.c",
        "src/address_parser_io.c",
        "src/averaged_perceptron.c",
        "src/crf.c",
        "src/crf_context.c",
        "src/sparse_matrix.c",
        "src/averaged_perceptron_tagger.c",
        "src/graph.c",
        "src/graph_builder.c",
        "src/language_classifier.c",
        "src/language_features.c",
        "src/logistic_regression.c",
        "src/logistic.c",
        "src/minibatch.c",
        "src/float_utils.c",
        "src/ngrams.c",
        "src/place.c",
        "src/near_dupe.c",
        "src/double_metaphone.c",
        "src/geohash/geohash.c",
        "src/dedupe.c",
        "src/string_similarity.c",
        "src/acronyms.c",
        "src/soft_tfidf.c",
        "src/jaccard.c",
        // libscanner sources (linked into libpostal)
        "src/klib/drand48.c",
        "src/scanner.c",
    };

    // Build libraries for native target
    const c_flags = get_c_flags(b, target, optimize, pic, optimize_for_size);
    
    const lib = buildLibrary(b, "postal", target, optimize, &c_sources, c_flags);
    configureLibrary(lib, target, strip_debug);
    b.installArtifact(lib);

    const jni_lib = buildJNILibrary(b, target, optimize, c_flags, lib);
    configureLibrary(jni_lib, target, strip_debug);
    b.installArtifact(jni_lib);

    // Cross-compilation step - builds for all supported platforms
    const CrossTarget = struct {
        query: std.Target.Query,
        name: []const u8,
        optimize_mode: std.builtin.OptimizeMode,
    };

    // Supported cross-compilation targets
    const cross_targets = [_]CrossTarget{
        .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu }, .name = "linux-x86_64", .optimize_mode = .ReleaseSmall },
        .{ .query = .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu }, .name = "linux-aarch64", .optimize_mode = .ReleaseSmall },
        .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .gnu }, .name = "windows-x86_64", .optimize_mode = .ReleaseSmall },
        .{ .query = .{ .cpu_arch = .aarch64, .os_tag = .windows, .abi = .gnu }, .name = "windows-aarch64", .optimize_mode = .ReleaseSmall },
        .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .macos }, .name = "macos-x86_64", .optimize_mode = .ReleaseSmall },
        .{ .query = .{ .cpu_arch = .aarch64, .os_tag = .macos }, .name = "macos-aarch64", .optimize_mode = .ReleaseSmall },
    };

    const cross_step = b.step("cross", "Build optimized libraries for all platforms");

    for (cross_targets) |target_info| {
        const resolved_target = b.resolveTargetQuery(target_info.query);
        const flags = get_c_flags(b, resolved_target, target_info.optimize_mode, pic, optimize_for_size);

        // Build main library for this target
        const cross_lib = buildLibrary(b, "postal", resolved_target, target_info.optimize_mode, &c_sources, flags);
        configureLibrary(cross_lib, resolved_target, true);

        // Build JNI wrapper for this target
        const cross_jni = buildJNILibrary(b, resolved_target, target_info.optimize_mode, flags, cross_lib);
        configureLibrary(cross_jni, resolved_target, true);

        // Install to platform-specific directories
        const install_dir = b.fmt("lib/{s}", .{target_info.name});
        const install_lib = b.addInstallArtifact(cross_lib, .{
            .dest_dir = .{ .override = .{ .custom = install_dir } },
        });
        const install_jni = b.addInstallArtifact(cross_jni, .{
            .dest_dir = .{ .override = .{ .custom = install_dir } },
        });

        cross_step.dependOn(&install_lib.step);
        cross_step.dependOn(&install_jni.step);
    }
}

/// Build the main libpostal library
fn buildLibrary(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    sources: []const []const u8,
    flags: []const []const u8,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = name,
        .root_module = module,
        .linkage = .dynamic,
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });

    lib.addCSourceFiles(.{
        .files = sources,
        .flags = flags,
    });

    lib.addIncludePath(b.path("."));
    lib.linkLibC();

    return lib;
}

/// Build the JNI wrapper library
fn buildJNILibrary(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    flags: []const []const u8,
    main_lib: *std.Build.Step.Compile,
) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    const jni_lib = b.addLibrary(.{
        .name = "postal_jni",
        .root_module = module,
        .linkage = .dynamic,
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });

    jni_lib.addCSourceFile(.{
        .file = b.path("src/jni/libpostal_jni.c"),
        .flags = flags,
    });

    jni_lib.addIncludePath(b.path("src"));
    jni_lib.addIncludePath(b.path("."));
    jni_lib.addIncludePath(b.path("src/jni/include"));
    jni_lib.linkLibrary(main_lib);
    jni_lib.linkLibC();

    return jni_lib;
}

/// Configure platform-specific linker settings for a library
fn configureLibrary(lib: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, strip: bool) void {
    if (strip) {
        lib.root_module.strip = true;
    }

    lib.link_gc_sections = true;

    switch (target.result.os.tag) {
        .linux, .macos => {
            lib.linker_allow_shlib_undefined = true;
        },
        else => {},
    }
}

/// Generate C compiler flags based on target platform and build settings
fn get_c_flags(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, pic: bool, optimize_for_size: bool) []const []const u8 {
    var c_flags_list = std.ArrayList([]const u8){};

    // Common defines
    const common_defines = [_][]const u8{
        "-DLIBPOSTAL_EXPORTS",
        "-DHAVE_LIBC",
        "-std=gnu99",
        "-DNDEBUG",
        "-DLIBPOSTAL_DATA_DIR=\"/usr/local/share/libpostal\"",
        "-DHAVE_SNAPPY=0",
    };

    for (common_defines) |flag| {
        c_flags_list.append(b.allocator, flag) catch unreachable;
    }

    // Platform-specific defines
    switch (target.result.os.tag) {
        .windows => {
            // Windows: Don't use config.h to avoid wrong HAVE_DRAND48 define
            // The custom drand48 implementation in src/klib/drand48.c will be used
            // MinGW provides dirent.h compatibility
            c_flags_list.append(b.allocator, "-DHAVE_DIRENT_H") catch unreachable;
        },
        else => {
            // POSIX platforms: use config.h
            c_flags_list.append(b.allocator, "-DHAVE_CONFIG_H") catch unreachable;
        },
    }

    if (pic) {
        c_flags_list.append(b.allocator, "-fPIC") catch unreachable;
    }

    // Optimization level
    const opt_flag = if (optimize_for_size)
        "-Os"
    else switch (optimize) {
        .ReleaseFast => "-O3",
        .ReleaseSmall => "-Os",
        else => "-O2",
    };
    c_flags_list.append(b.allocator, opt_flag) catch unreachable;

    // Size and performance optimization flags
    const perf_flags = [_][]const u8{
        "-ffunction-sections",
        "-fdata-sections",
        "-fno-stack-protector",
        "-fomit-frame-pointer",
    };

    for (perf_flags) |flag| {
        c_flags_list.append(b.allocator, flag) catch unreachable;
    }

    return c_flags_list.items;
}

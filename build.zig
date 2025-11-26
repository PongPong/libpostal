const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // Enhanced optimization options
    const optimize_for_size = b.option(bool, "optimize-size", "Optimize for size instead of speed") orelse false;
    const strip_debug = b.option(bool, "strip", "Strip debug symbols") orelse true;
    const enable_lto = b.option(bool, "lto", "Enable Link Time Optimization") orelse true;
    const pic = b.option(bool, "pic", "Position Independent Code") orelse true;
    
    // Define all C source files for libpostal
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
        "src/utf8proc/utf8proc_data.c",
        "src/normalize.c",
        "src/numex.c",
        "src/numex_data.c",
        "src/features.c",
        "src/unicode_scripts.c",
        "src/unicode_scripts_data.c",
        "src/address_parser.c",
        "src/address_parser_io.c",
        "src/averaged_perceptron.c",
        "src/crf.c",
        "src/crf_context.c",
        "src/sparse_matrix.c",
        "src/sparse_matrix_utils.c",
        "src/averaged_perceptron_tagger.c",
        "src/graph.c",
        "src/graph_builder.c",
        "src/language_classifier.c",
        "src/language_classifier_io.c",
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
        "src/transliteration_data.c",
        "src/address_expansion_data.c",
        "src/gazetteer_data.c",
        "src/scanner.c",
        "src/bloom.c",
        "src/regularization.c",
        "src/ftrl.c",
        "src/geo_disambiguation.c",
        "src/geodb.c",
        "src/geonames.c",
        "src/shuffle.c",
        "src/cartesian_product.c",
        "src/msgpack_utils.c",
        "src/json_encode.c",
        "src/cmp/cmp.c",
        "src/murmur/murmur.c",
        "src/sparkey/buf.c",
        "src/sparkey/endiantools.c",
        "src/sparkey/hashheader.c",
        "src/sparkey/hashiter.c",
        "src/sparkey/hashreader.c",
        "src/sparkey/logheader.c",
        "src/sparkey/logreader.c",
        "src/sparkey/logwriter.c",
        "src/sparkey/MurmurHash3.c",
        "src/sparkey/returncodes.c",
    };

    // Build optimized C flags
    var c_flags_list = std.ArrayList([]const u8).init(b.allocator);
    defer c_flags_list.deinit();
    
    c_flags_list.append("-DLIBPOSTAL_EXPORTS") catch unreachable;
    c_flags_list.append("-DHAVE_LIBC") catch unreachable;
    c_flags_list.append("-std=c99") catch unreachable;
    c_flags_list.append("-DNDEBUG") catch unreachable;
    
    if (pic) {
        c_flags_list.append("-fPIC") catch unreachable;
    }
    
    // Optimization flags
    if (optimize_for_size) {
        c_flags_list.append("-Os") catch unreachable;
    } else if (optimize == .ReleaseFast) {
        c_flags_list.append("-O3") catch unreachable;
    } else if (optimize == .ReleaseSmall) {
        c_flags_list.append("-Os") catch unreachable;
    } else {
        c_flags_list.append("-O2") catch unreachable;
    }
    
    // LTO and size optimization
    if (enable_lto) {
        c_flags_list.append("-flto") catch unreachable;
    }
    
    c_flags_list.append("-ffunction-sections") catch unreachable;
    c_flags_list.append("-fdata-sections") catch unreachable;
    c_flags_list.append("-fno-stack-protector") catch unreachable;
    c_flags_list.append("-fomit-frame-pointer") catch unreachable;
    
    const c_flags = c_flags_list.items;

    // Create root module for the library
    const lib_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    // Build shared library for libpostal
    const lib = b.addLibrary(.{
        .name = "postal",
        .root_module = lib_module,
        .linkage = .dynamic,
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });

    lib.addCSourceFiles(.{
        .files = &c_sources,
        .flags = c_flags,
    });

    lib.addIncludePath(b.path("src"));
    lib.linkLibC();
    
    // Size optimization linker flags
    if (enable_lto) {
        lib.want_lto = true;
    }
    
    if (strip_debug) {
        lib.strip = true;
    }
    
    // Platform-specific linker flags
    switch (target.result.os.tag) {
        .linux => {
            lib.linker_allow_shlib_undefined = true;
            // Dead code elimination
            lib.link_gc_sections = true;
        },
        .macos => {
            lib.linker_allow_shlib_undefined = true;
            lib.link_gc_sections = true;
        },
        .windows => {
            // Windows-specific optimizations
        },
        else => {},
    }

    b.installArtifact(lib);

    // Build JNI wrapper as shared library
    const jni_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    const jni_lib = b.addLibrary(.{
        .name = "postal_jni",
        .root_module = jni_module,
        .linkage = .dynamic,
        .version = .{ .major = 1, .minor = 0, .patch = 0 },
    });

    jni_lib.addCSourceFile(.{
        .file = b.path("src/jni/libpostal_jni.c"),
        .flags = c_flags,
    });

    jni_lib.addIncludePath(b.path("src"));
    jni_lib.addIncludePath(b.path("src/jni/include"));
    jni_lib.linkLibrary(lib);
    jni_lib.linkLibC();
    
    // Apply same optimizations to JNI wrapper
    if (enable_lto) {
        jni_lib.want_lto = true;
    }
    
    if (strip_debug) {
        jni_lib.strip = true;
    }
    
    switch (target.result.os.tag) {
        .linux => {
            jni_lib.linker_allow_shlib_undefined = true;
            jni_lib.link_gc_sections = true;
        },
        .macos => {
            jni_lib.linker_allow_shlib_undefined = true;
            jni_lib.link_gc_sections = true;
        },
        .windows => {},
        else => {},
    }

    b.installArtifact(jni_lib);

    // Build step for cross-compilation targets
    const CrossTarget = struct {
        query: std.Target.Query,
        name: []const u8,
        optimize_mode: std.builtin.OptimizeMode,
    };
    
    const cross_targets = [_]CrossTarget{
        .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu }, .name = "linux-x86_64", .optimize_mode = .ReleaseSmall },
        .{ .query = .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .gnu }, .name = "linux-aarch64", .optimize_mode = .ReleaseSmall },
        .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .gnu }, .name = "windows-x86_64", .optimize_mode = .ReleaseSmall },
        .{ .query = .{ .cpu_arch = .aarch64, .os_tag = .windows, .abi = .gnu }, .name = "windows-aarch64", .optimize_mode = .ReleaseSmall },
        .{ .query = .{ .cpu_arch = .x86_64, .os_tag = .macos }, .name = "macos-x86_64", .optimize_mode = .ReleaseSmall },
        .{ .query = .{ .cpu_arch = .aarch64, .os_tag = .macos }, .name = "macos-aarch64", .optimize_mode = .ReleaseSmall },
    };

    const cross_step = b.step("cross", "Build optimized libraries for all platforms");

    for (cross_targets) |cross_target_info| {
        const cross_target = b.resolveTargetQuery(cross_target_info.query);
        
        const cross_lib_module = b.createModule(.{
            .target = cross_target,
            .optimize = cross_target_info.optimize_mode,
        });
        
        const cross_lib = b.addLibrary(.{
            .name = "postal",
            .root_module = cross_lib_module,
            .linkage = .dynamic,
            .version = .{ .major = 1, .minor = 0, .patch = 0 },
        });

        cross_lib.addCSourceFiles(.{
            .files = &c_sources,
            .flags = c_flags,
        });

        cross_lib.addIncludePath(b.path("src"));
        cross_lib.linkLibC();
        
        // Aggressive optimization for cross-compilation
        cross_lib.want_lto = true;
        cross_lib.strip = true;
        cross_lib.link_gc_sections = true;
        
        switch (cross_target.result.os.tag) {
            .linux, .macos => {
                cross_lib.linker_allow_shlib_undefined = true;
            },
            else => {},
        }

        const cross_jni_module = b.createModule(.{
            .target = cross_target,
            .optimize = cross_target_info.optimize_mode,
        });

        const cross_jni = b.addLibrary(.{
            .name = "postal_jni",
            .root_module = cross_jni_module,
            .linkage = .dynamic,
            .version = .{ .major = 1, .minor = 0, .patch = 0 },
        });

        cross_jni.addCSourceFile(.{
            .file = b.path("src/jni/libpostal_jni.c"),
            .flags = c_flags,
        });

        cross_jni.addIncludePath(b.path("src"));
        cross_jni.addIncludePath(b.path("src/jni/include"));
        cross_jni.linkLibrary(cross_lib);
        cross_jni.linkLibC();
        
        // Same optimizations for JNI
        cross_jni.want_lto = true;
        cross_jni.strip = true;
        cross_jni.link_gc_sections = true;
        
        switch (cross_target.result.os.tag) {
            .linux, .macos => {
                cross_jni.linker_allow_shlib_undefined = true;
            },
            else => {},
        }

        // Install to platform-specific directories
        const install_dir = b.fmt("lib/{s}", .{cross_target_info.name});
        
        const install_cross_lib = b.addInstallArtifact(cross_lib, .{
            .dest_dir = .{ .override = .{ .custom = install_dir } },
        });
        const install_cross_jni = b.addInstallArtifact(cross_jni, .{
            .dest_dir = .{ .override = .{ .custom = install_dir } },
        });
        
        cross_step.dependOn(&install_cross_lib.step);
        cross_step.dependOn(&install_cross_jni.step);
    }
}

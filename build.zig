const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
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

    const c_flags = [_][]const u8{
        "-DLIBPOSTAL_EXPORTS",
        "-DHAVE_LIBC",
        "-std=c99",
        "-fPIC",
    };

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
        .flags = &c_flags,
    });

    lib.addIncludePath(b.path("src"));
    lib.linkLibC();

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
        .flags = &c_flags,
    });

    jni_lib.addIncludePath(b.path("src"));
    jni_lib.addIncludePath(b.path("src/jni/include"));
    jni_lib.linkLibrary(lib);
    jni_lib.linkLibC();

    b.installArtifact(jni_lib);

    // Build step for cross-compilation targets
    const cross_targets = [_]std.Target.Query{
        .{ .cpu_arch = .x86_64, .os_tag = .linux },
        .{ .cpu_arch = .aarch64, .os_tag = .linux },
        .{ .cpu_arch = .x86_64, .os_tag = .windows },
        .{ .cpu_arch = .aarch64, .os_tag = .windows },
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .aarch64, .os_tag = .macos },
    };

    const cross_step = b.step("cross", "Build for all targets");

    for (cross_targets) |target_query| {
        const cross_target = b.resolveTargetQuery(target_query);
        
        const cross_lib_module = b.createModule(.{
            .target = cross_target,
            .optimize = optimize,
        });
        
        const cross_lib = b.addLibrary(.{
            .name = "postal",
            .root_module = cross_lib_module,
            .linkage = .dynamic,
            .version = .{ .major = 1, .minor = 0, .patch = 0 },
        });

        cross_lib.addCSourceFiles(.{
            .files = &c_sources,
            .flags = &c_flags,
        });

        cross_lib.addIncludePath(b.path("src"));
        cross_lib.linkLibC();

        const cross_jni_module = b.createModule(.{
            .target = cross_target,
            .optimize = optimize,
        });

        const cross_jni = b.addLibrary(.{
            .name = "postal_jni",
            .root_module = cross_jni_module,
            .linkage = .dynamic,
            .version = .{ .major = 1, .minor = 0, .patch = 0 },
        });

        cross_jni.addCSourceFile(.{
            .file = b.path("src/jni/libpostal_jni.c"),
            .flags = &c_flags,
        });

        cross_jni.addIncludePath(b.path("src"));
        cross_jni.addIncludePath(b.path("src/jni/include"));
        cross_jni.linkLibrary(cross_lib);
        cross_jni.linkLibC();

        const install_cross_lib = b.addInstallArtifact(cross_lib, .{});
        const install_cross_jni = b.addInstallArtifact(cross_jni, .{});
        
        cross_step.dependOn(&install_cross_lib.step);
        cross_step.dependOn(&install_cross_jni.step);
    }
}

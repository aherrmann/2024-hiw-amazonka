load("@prelude//cxx:linker.bzl", "is_pdb_generated")
load("@prelude//linking:link_info.bzl", "LinkOrdering", "LinkStyle")
load(
    "@prelude//cxx:cxx_toolchain_types.bzl",
    "BinaryUtilitiesInfo",
    "CCompilerInfo",
    "CxxCompilerInfo",
    "CxxPlatformInfo",
    "CxxToolchainInfo",
    "LinkerInfo",
    "PicBehavior",
    "ShlibInterfacesMode",
)
load("@prelude//linking:lto.bzl", "LtoMode")
load("@prelude//cxx:headers.bzl", "HeaderMode")

def _nix_cxx_toolchain(ctx: AnalysisContext) -> list[Provider]:
    nix_cc = ctx.attrs.nix_cc[DefaultInfo].sub_targets

    compiler = nix_cc["cc"][RunInfo]
    cxx_compiler = nix_cc["c++"][RunInfo]

    compiler_type = "clang" if host_info().os.is_macos else "g++"
    archiver = nix_cc["ar"][RunInfo]
    archiver_type = "gnu"
    archiver_supports_argfiles = True
    asm_compiler = compiler
    asm_compiler_type = compiler_type
    compiler = compiler
    cxx_compiler = cxx_compiler
    linker = cxx_compiler
    linker_type = "gnu"
    pic_behavior = PicBehavior("supported")
    binary_extension = ""
    object_file_extension = "o"
    static_library_extension = "a"
    shared_library_name_default_prefix = "lib"
    shared_library_name_format = "{}.so"
    shared_library_versioned_name_format = "{}.so.{}"
    additional_linker_flags = []
    if host_info().os.is_macos:
        archiver_supports_argfiles = False
        linker_type = "darwin"
        pic_behavior = PicBehavior("always_enabled")
    elif host_info().os.is_windows:
        fail("not supported")
    elif host_info().os.is_linux:
        pass
    else:
        additional_linker_flags = ["-fuse-ld=lld"]

    if compiler_type == "clang":
        llvm_link = RunInfo(args = ["llvm-link"])
    else:
        llvm_link = None

    return [
        DefaultInfo(),
        CxxToolchainInfo(
            mk_comp_db = ctx.attrs.make_comp_db,
            linker_info = LinkerInfo(
                linker = RunInfo(args = linker),
                linker_flags = additional_linker_flags + ctx.attrs.link_flags,
                archiver = archiver,
                archiver_type = archiver_type,
                archiver_supports_argfiles = archiver_supports_argfiles,
                generate_linker_maps = False,
                lto_mode = LtoMode("none"),
                type = linker_type,
                link_binaries_locally = True,
                archive_objects_locally = True,
                use_archiver_flags = True,
                static_dep_runtime_ld_flags = [],
                static_pic_dep_runtime_ld_flags = [],
                shared_dep_runtime_ld_flags = [],
                independent_shlib_interface_linker_flags = [],
                shlib_interfaces = ShlibInterfacesMode("stub_from_library"),
                link_style = LinkStyle(ctx.attrs.link_style),
                link_weight = 1,
                binary_extension = binary_extension,
                object_file_extension = object_file_extension,
                shared_library_name_default_prefix = shared_library_name_default_prefix,
                shared_library_name_format = shared_library_name_format,
                shared_library_versioned_name_format = shared_library_versioned_name_format,
                static_library_extension = static_library_extension,
                force_full_hybrid_if_capable = False,
                is_pdb_generated = is_pdb_generated(linker_type, ctx.attrs.link_flags),
                link_ordering = ctx.attrs.link_ordering,
            ),
            bolt_enabled = False,
            binary_utilities_info = BinaryUtilitiesInfo(
                nm = nix_cc["nm"][RunInfo],
                objcopy = nix_cc["objcopy"][RunInfo],
                ranlib = nix_cc["ranlib"][RunInfo],
                strip = nix_cc["strip"][RunInfo],
                dwp = None,
                bolt_msdk = None,
            ),
            cxx_compiler_info = CxxCompilerInfo(
                compiler = RunInfo(args = [cxx_compiler]),
                preprocessor_flags = [],
                compiler_flags = ctx.attrs.cxx_flags,
                compiler_type = compiler_type,
            ),
            c_compiler_info = CCompilerInfo(
                compiler = RunInfo(args = [compiler]),
                preprocessor_flags = [],
                compiler_flags = ctx.attrs.c_flags,
                compiler_type = compiler_type,
            ),
            as_compiler_info = CCompilerInfo(
                compiler = RunInfo(args = [compiler]),
                compiler_type = compiler_type,
            ),
            asm_compiler_info = CCompilerInfo(
                compiler = RunInfo(args = [asm_compiler]),
                compiler_type = asm_compiler_type,
            ),
            header_mode = HeaderMode("symlink_tree_only"),
            cpp_dep_tracking_mode = ctx.attrs.cpp_dep_tracking_mode,
            pic_behavior = pic_behavior,
            llvm_link = llvm_link,
        ),
        CxxPlatformInfo(name = "aarch64" if host_info().arch.is_aarch64 else "x86_64"),
    ]

nix_cxx_toolchain = rule(
    impl = _nix_cxx_toolchain,
    attrs = {
        "c_flags": attrs.list(attrs.string(), default = []),
        "cpp_dep_tracking_mode": attrs.string(default = "makefile"),
        "cxx_flags": attrs.list(attrs.string(), default = []),
        "link_ordering": attrs.option(attrs.enum(LinkOrdering.values()), default = None),
        "link_flags": attrs.list(attrs.string(), default = []),
        "link_style": attrs.string(default = "shared"),
        "make_comp_db": attrs.default_only(attrs.exec_dep(providers = [RunInfo], default = "prelude//cxx/tools:make_comp_db")),
        "nix_cc": attrs.dep(
            default = "//:nix_cxx",
        )
    },
    is_toolchain_rule = True,
)
 

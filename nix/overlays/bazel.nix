self: super:
let
  extraPatches = super.lib.optional self.stdenv.isDarwin ./bazel/darwin_sleep.patch;
  extraPostPatch = super.lib.optionalString self.stdenv.isDarwin ''
    sed -i.bak -E \
      -e "s;codesign;CODESIGN_ALLOCATE=${self.darwin.cctools}/bin/${self.darwin.cctools.targetPrefix}codesign_allocate ${self.darwin.sigtool}/bin/codesign;" \
      tools/osx/BUILD
  '';
in
{
  bazel_6 = super.bazel_6.overrideAttrs (attrs: {
    patches = attrs.patches ++ extraPatches;
    postPatch = attrs.postPatch + extraPostPatch;
  });
}

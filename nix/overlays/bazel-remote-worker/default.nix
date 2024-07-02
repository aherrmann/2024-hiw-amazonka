{ buildBazelPackage
, bazel_6
, jdk17_headless
, makeWrapper
, fetchFromGitHub
, darwin
, wrapCCWith
, overrideCC
, writeTextFile
, llvmPackages
, libiconv
, lib
, stdenv
}:

let
  inherit (darwin.apple_sdk.frameworks) CoreFoundation CoreServices Foundation;
  postLinkSignHook =
    writeTextFile {
      name = "post-link-sign-hook";
      executable = true;
      text = ''
        CODESIGN_ALLOCATE=${darwin.cctools}/bin/codesign_allocate \
          ${darwin.sigtool}/bin/codesign -f -s - "$linkerOutput"
      '';
    };
  darwinCC =
    wrapCCWith rec {
      cc = stdenv.cc.cc;
      bintools = stdenv.cc.bintools.override { inherit postLinkSignHook; };
      extraBuildCommands = with darwin.apple_sdk.frameworks; ''
        echo "-Wno-unused-command-line-argument" >> $out/nix-support/cc-cflags
        echo "-Wno-elaborated-enum-base" >> $out/nix-support/cc-cflags
        echo "-isystem ${llvmPackages.libcxx.dev}/include/c++/v1" >> $out/nix-support/cc-cflags
        echo "-isystem ${llvmPackages.clang-unwrapped.lib}/lib/clang/${cc.version}/include" >> $out/nix-support/cc-cflags
      '' + (
        lib.optionalString (darwin.apple_sdk.libs ? libDER)
          ''echo "-isystem${darwin.apple_sdk.libs.libDER}/include" >> $out/nix-support/cc-cflags''
      ) + ''
        echo "-F${CoreFoundation}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-F${CoreServices}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-F${Security}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-F${Foundation}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-F${IOKit}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-F${DiskArbitration}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-F${CFNetwork}/Library/Frameworks" >> $out/nix-support/cc-cflags
        echo "-L${llvmPackages.libcxx}/lib" >> $out/nix-support/cc-cflags
        echo "-L${llvmPackages.libcxxabi}/lib" >> $out/nix-support/cc-cflags
        echo "-L${libiconv}/lib" >> $out/nix-support/cc-cflags
        echo "-L${darwin.libobjc}/lib" >> $out/nix-support/cc-cflags
        echo "-resource-dir=${stdenv.cc}/resource-root" >> $out/nix-support/cc-cflags
      '';
    };
  patches = bazel_6.patches ++ [
    ./0001-Accept-missing-RequestMetadata.patch
    ./0002-Implement-BatchReadBlobsRequest-handler-for-remote-w.patch
    ./0004-Reduce-max-batch-size.patch
    ./0005-increase-max-inbound-msg-size.patch
    ./0006-dont-clear-environment.patch
  ] ++ lib.optional (!stdenv.hostPlatform.isAarch64) ./0003-Remove-thermal-monitor.patch;
  postPatch = bazel_6.postPatch + ''
    rm .bazelversion
    cat >>.bazelrc <<EOF
    build --tool_java_runtime_version=local_jdk
    build --java_runtime_version=local_jdk
    EOF
  '' + lib.optionalString stdenv.isDarwin ''
    cat >>.bazelrc <<EOF
    build --repo_env=CC='${darwinCC}/bin/clang'
    build --repo_env=CXX='${darwinCC}/bin/clang++'
    build --repo_env=LD='${darwin.cctools}/bin/ld'
    build --repo_env=LIBTOOL='${darwin.cctools}/bin/libtool'
    build --repo_env=BAZEL_USE_CPP_ONLY_TOOLCHAIN=1
    EOF
  '';
in

buildBazelPackage.override { stdenv = if stdenv.isDarwin then overrideCC stdenv darwinCC else stdenv; } {
  pname = "bazel-remote-worker";
  version = "6.4.0";

  src = fetchFromGitHub {
    owner = "bazelbuild";
    repo = "bazel";
    rev = "6.4.0";
    hash = "sha256-hmDaPvS6JI09Fe2YLoxiOSPRYSF2zzieSgBZFkJ96eo=";
  };

  buildInputs = [ jdk17_headless makeWrapper ];

  bazel = bazel_6;
  bazelTargets = [ "//src/tools/remote:worker_deploy.jar" ];

  fetchAttrs = {
    inherit patches postPatch;

    sha256 = "sha256-CY5UyN6sb5OW0vRScZ0MZTAUHf+d7Rrr1Pw7wQc+k34=";

  };

  buildAttrs = {
    inherit patches postPatch;

    installPhase = ''
      makeWrapper ${jdk17_headless}/bin/java $out/bin/bazel-remote-worker --add-flags "-jar $out/share/worker_deploy.jar" --set-default JAVA_RUNFILES $out/share/runfiles
      install -Dm644 bazel-bin/src/tools/remote/worker_deploy.jar $out/share/worker_deploy.jar
      install -Dm755 bazel-bin/src/main/tools/linux-sandbox $out/share/runfiles/src/main/tools/linux-sandbox
      install -Dm755 bazel-bin/src/main/tools/process-wrapper $out/share/runfiles/src/main/tools/process-wrapper
    '';
  };

  meta = with lib; {
    homepage = "https://github.com/bazelbuild/bazel/";
    description = "Remote build worker included within Bazel for testing.";
    license = licenses.asl20;
    platforms = platforms.linux ++ platforms.darwin;
  };
}

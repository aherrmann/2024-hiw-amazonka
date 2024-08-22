image = "docker://ghcr.io/aherrmann/amazonka-buck2@sha256:fb1e07b33a66310fb8d1fbbfff733875e9152723213d0cf0b0a0a4585a0b2480"

def _platforms(ctx):
    constraints = dict()
    constraints.update(ctx.attrs.cpu_configuration[ConfigurationInfo].constraints)
    constraints.update(ctx.attrs.os_configuration[ConfigurationInfo].constraints)
    configuration = ConfigurationInfo(constraints = constraints, values = {})

    platform = ExecutionPlatformInfo(
        label = ctx.label.raw_target(),
        configuration = configuration,
        executor_config = CommandExecutorConfig(
            local_enabled = True,
            remote_enabled = True,

            allow_cache_uploads = True,
            use_limited_hybrid = True,
            remote_execution_properties = {
                "OSFamily": "Linux",
                "container-image": image,
                "recycle-runner": True,
                "nonroot-workspace": True,
            },
            remote_execution_use_case = "buck2-default",
            remote_output_paths = "output_paths",
            remote_cache_enabled = True,
        ),
    )

    return [DefaultInfo(), ExecutionPlatformRegistrationInfo(platforms = [platform])]

buildbuddy= rule(
    attrs = {
        "cpu_configuration": attrs.dep(providers = [ConfigurationInfo]),
        "os_configuration": attrs.dep(providers = [ConfigurationInfo]),
    },
    impl = _platforms
)

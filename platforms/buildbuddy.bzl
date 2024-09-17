image = "docker://ghcr.io/aherrmann/amazonka-buck2@sha256:43efaf7023fd9072e393b7768e19a8e76b65f3ccb59f8b30a2e2037e88310adf"

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
                "workload-isolation-type": "podman",
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

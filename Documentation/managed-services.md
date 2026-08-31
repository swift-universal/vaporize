# Vaporize Managed Services

Vaporize projects a service declared in `project.pkl` into the current host's
native user-service manager. Windows uses Task Scheduler under
`\\Wrkstrm\\Services`; macOS uses a LaunchAgent under
`~/Library/LaunchAgents`.

```pkl
services = new {
  ["takumi-fused"] = new {
    scope = "user"
    activation = "login"
    executable = "%USERPROFILE%/.swiftpm/bin/digikoma-windows-serve.exe"
    arguments = new { "--host"; "127.0.0.1"; "--port"; "8003" }
    restartPolicy = "on-failure"
    healthCheck = new {
      kind = "http"
      url = "http://127.0.0.1:8003/v1/models"
    }
  }
}
```

The same commands work on both supported hosts:

```text
vaporize.cli@wrkstrm-core.clia.sh service install takumi-fused --pkl-path project.pkl
vaporize.cli@wrkstrm-core.clia.sh service start takumi-fused --pkl-path project.pkl
vaporize.cli@wrkstrm-core.clia.sh service status takumi-fused --pkl-path project.pkl
vaporize.cli@wrkstrm-core.clia.sh service logs takumi-fused --pkl-path project.pkl
vaporize.cli@wrkstrm-core.clia.sh service stop takumi-fused --pkl-path project.pkl
vaporize.cli@wrkstrm-core.clia.sh service uninstall takumi-fused --pkl-path project.pkl
```

`install` is idempotent. It replaces the existing native registration with the
new declaration. `uninstall` removes the registration and generated launcher
files but preserves service logs. System scope is intentionally rejected until
Vaporize has an explicit elevation and authorization contract.

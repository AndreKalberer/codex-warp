. "$PSScriptRoot\oz-parent-common.ps1"

$state = New-HookState
if ($null -eq $state) {
    exit 0
}
if (Test-ListenerLifecycleManagedExternally) {
    exit 0
}

New-StateDir $state.StateDir
Start-ListenerIfNeeded (Join-Path $PSScriptRoot "oz-parent-listener.ps1") $state.StateDir

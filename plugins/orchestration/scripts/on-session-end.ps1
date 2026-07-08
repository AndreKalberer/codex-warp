. "$PSScriptRoot\oz-parent-common.ps1"

$state = New-HookState
if ($null -eq $state) {
    exit 0
}
if (Test-ListenerLifecycleManagedExternally) {
    exit 0
}

Clear-HookState $state.StateDir

. "$PSScriptRoot\oz-parent-common.ps1"

$state = Import-HookState
if ($null -eq $state) {
    exit 0
}

$output = Write-StopBlockIfPending $state.StateDir
if ($null -ne $output) {
    $output
}

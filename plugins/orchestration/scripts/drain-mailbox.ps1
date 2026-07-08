param(
    [Parameter(Mandatory = $true)]
    [string]$HookEvent
)

. "$PSScriptRoot\oz-parent-common.ps1"

$state = Import-HookState
if ($null -eq $state) {
    exit 0
}

if (Test-ListenerLifecycleManagedExternally) {
    $output = Write-DriverHookAdditionalContext $HookEvent $state.StateDir
    if ($null -ne $output) {
        $output
        Confirm-DriverHookOutput $state.StateDir
    }
    exit 0
}

$maxContextChars = 6000
$parsedMaxContextChars = 0
if ([int]::TryParse($env:OZ_PARENT_MAX_CONTEXT_CHARS, [ref]$parsedMaxContextChars) -and $parsedMaxContextChars -gt 0) {
    $maxContextChars = $parsedMaxContextChars
}

$parentContext = New-ParentContextFromStagedMessages $state.StateDir $maxContextChars
if ($null -eq $parentContext) {
    exit 0
}

Confirm-AndRemoveStagedMessages $state.StateDir $parentContext.SurfacedIds
Write-HookAdditionalContext $HookEvent $parentContext.Context

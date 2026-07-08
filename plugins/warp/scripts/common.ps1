$ErrorActionPreference = "Stop"

$PluginCurrentProtocolVersion = 1

function Test-ShouldUseStructured {
    if ([string]::IsNullOrEmpty($env:WARP_CLI_AGENT_PROTOCOL_VERSION)) {
        return $false
    }
    if ([string]::IsNullOrEmpty($env:WARP_CLIENT_VERSION)) {
        return $false
    }
    return $true
}

function Read-HookInput {
    return [Console]::In.ReadToEnd()
}

function ConvertFrom-JsonSafe {
    param([string]$Json)

    if ([string]::IsNullOrWhiteSpace($Json)) {
        return $null
    }

    try {
        return $Json | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-JsonProperty {
    param(
        [object]$Object,
        [string]$Name,
        [object]$Default = ""
    )

    if ($null -eq $Object) {
        return $Default
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return $Default
    }

    return $property.Value
}

function Get-TruncatedText {
    param(
        [string]$Value,
        [int]$MaxLength
    )

    if ($null -eq $Value) {
        return ""
    }

    if ($Value.Length -gt $MaxLength) {
        return $Value.Substring(0, $MaxLength - 3) + "..."
    }

    return $Value
}

function Get-ProtocolVersion {
    $warpVersion = 1
    $parsed = 0
    if ([int]::TryParse($env:WARP_CLI_AGENT_PROTOCOL_VERSION, [ref]$parsed)) {
        $warpVersion = $parsed
    }

    if ($warpVersion -lt $PluginCurrentProtocolVersion) {
        return $warpVersion
    }

    return $PluginCurrentProtocolVersion
}

function New-WarpPayload {
    param(
        [string]$InputJson,
        [string]$Event,
        [hashtable]$ExtraFields = @{}
    )

    $inputObject = ConvertFrom-JsonSafe $InputJson
    $sessionId = [string](Get-JsonProperty $inputObject "session_id" "")
    $cwd = [string](Get-JsonProperty $inputObject "cwd" "")
    $project = ""

    if (-not [string]::IsNullOrEmpty($cwd)) {
        $project = Split-Path -Leaf $cwd
    }

    $payload = [ordered]@{
        v = Get-ProtocolVersion
        agent = "codex"
        event = $Event
        session_id = $sessionId
        cwd = $cwd
        project = $project
    }

    foreach ($key in $ExtraFields.Keys) {
        $payload[$key] = $ExtraFields[$key]
    }

    return ($payload | ConvertTo-Json -Compress -Depth 50)
}

function Send-WarpNotification {
    param(
        [string]$Title,
        [string]$Body
    )

    $escape = [char]27
    $bell = [char]7
    $message = "$escape]777;notify;$Title;$Body$bell"

    try {
        $stream = [System.IO.File]::Open("CONOUT$", [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Write)
        try {
            $writer = New-Object System.IO.StreamWriter($stream, [Console]::OutputEncoding)
            $writer.AutoFlush = $true
            $writer.Write($message)
        } finally {
            if ($writer) {
                $writer.Dispose()
            } else {
                $stream.Dispose()
            }
        }
    } catch {
        # Hook stdout is reserved for Codex hook control JSON. If there is no
        # attached console device, drop the notification rather than emitting
        # OSC text to captured stdout and making the hook fail.
    }
}

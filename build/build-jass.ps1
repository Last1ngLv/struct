param(
    [string]$OutputPath = "",
    [switch]$Watch,
    [int]$DebounceMs = 250,
    [string[]]$IgnoreDirs = @("build", "Pruebas", "MissileExamples", "logs"),
    [switch]$SkipRequireValidation
)

$ErrorActionPreference = "Stop"

function Normalize-FileSystemPath {
    param([string]$PathValue)

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $PathValue
    }

    if ($PathValue.StartsWith("\\?\UNC\")) {
        return "\" + $PathValue.Substring(7)
    }

    if ($PathValue.StartsWith("\\?\")) {
        return $PathValue.Substring(4)
    }

    return $PathValue
}

function Resolve-AbsolutePath {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue,
        [Parameter(Mandatory = $true)][string]$BaseDir
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $BaseDir $PathValue))
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$BaseDir,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    $baseNormalized = $BaseDir.TrimEnd("\", "/") + "\"
    $baseUri = New-Object System.Uri($baseNormalized)
    $targetUri = New-Object System.Uri($TargetPath)
    $rel = $baseUri.MakeRelativeUri($targetUri).ToString()
    return [System.Uri]::UnescapeDataString($rel).Replace("\", "/")
}

function Normalize-SourceEntry {
    param([Parameter(Mandatory = $true)][string]$Entry)
    return $Entry.Trim().Replace("\", "/")
}

$scriptDir = Normalize-FileSystemPath $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $scriptDir = Split-Path -Parent (Normalize-FileSystemPath $PSCommandPath)
    }
    elseif ($MyInvocation -and $MyInvocation.MyCommand -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
        $scriptDir = Split-Path -Parent (Normalize-FileSystemPath $MyInvocation.MyCommand.Path)
    }
    else {
        $scriptDir = Normalize-FileSystemPath ((Get-Location).Path)
    }
}

$scriptDir = Normalize-FileSystemPath $scriptDir
$workspaceRoot = [System.IO.Directory]::GetParent([System.IO.Path]::GetFullPath($scriptDir)).FullName

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = "build/AllCode.generated.j"
}

$outputAbs = Resolve-AbsolutePath -PathValue $OutputPath -BaseDir $workspaceRoot
$ignoreAbsDirs = @()

if ($DebounceMs -lt 50) {
    $DebounceMs = 50
}

foreach ($dir in $IgnoreDirs) {
    if ([string]::IsNullOrWhiteSpace($dir)) {
        continue
    }
    $abs = Resolve-AbsolutePath -PathValue $dir -BaseDir $workspaceRoot
    $ignoreAbsDirs += ($abs.TrimEnd("\", "/") + "\")
}

function Should-IgnorePath {
    param([Parameter(Mandatory = $true)][string]$CandidatePath)

    $candidate = [System.IO.Path]::GetFullPath($CandidatePath)
    if ($candidate -ieq $outputAbs) {
        return $true
    }

    foreach ($dir in $ignoreAbsDirs) {
        if ($candidate.StartsWith($dir, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Get-DiscoverableSourceEntries {
    $found = New-Object System.Collections.Generic.List[string]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    Get-ChildItem -Path $workspaceRoot -Recurse -File -Filter "*.j" | ForEach-Object {
        $full = [System.IO.Path]::GetFullPath($_.FullName)
        if (Should-IgnorePath -CandidatePath $full) {
            return
        }

        $rel = Get-RelativePathSafe -BaseDir $workspaceRoot -TargetPath $full
        $normalized = Normalize-SourceEntry -Entry $rel
        if ($seen.Add($normalized)) {
            $found.Add($normalized)
        }
    }

    $found.Sort()
    return $found
}

function Parse-LibraryDeclarationLine {
    param(
        [Parameter(Mandatory = $true)][string]$DeclarationLine,
        [Parameter(Mandatory = $true)][int]$SourceIndex,
        [Parameter(Mandatory = $true)][string]$SourceEntry
    )

    $lineNoComment = $DeclarationLine.Split("//")[0].Trim()
    if ([string]::IsNullOrWhiteSpace($lineNoComment)) {
        return $null
    }

    $match = [regex]::Match($lineNoComment, "(?i)^library(?:_once)?\s+([A-Za-z_]\w*)\b(.*)$")
    if (-not $match.Success) {
        return $null
    }

    $libraryName = $match.Groups[1].Value
    $requires = New-Object System.Collections.Generic.List[object]
    $reqMatch = [regex]::Match($lineNoComment, "(?i)\brequires\s+(.+)$")
    if ($reqMatch.Success) {
        $reqPart = $reqMatch.Groups[1].Value
        $segments = $reqPart.Split(",")
        foreach ($seg in $segments) {
            $token = $seg.Trim()
            if ($token -eq "") {
                continue
            }

            $isOptional = $false
            if ($token -match "^(?i)optional\s+") {
                $isOptional = $true
                $token = [regex]::Replace($token, "^(?i)optional\s+", "")
            }

            $token = $token.Trim()
            if ($token.Contains(" ")) {
                $token = $token.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[0]
            }

            if ($token -ne "") {
                $requires.Add([pscustomobject]@{
                    Name     = $token
                    Optional = $isOptional
                })
            }
        }
    }

    return [pscustomobject]@{
        Name        = $libraryName
        SourceIndex = $SourceIndex
        SourceEntry = $SourceEntry
        Requires    = $requires
    }
}

function Get-LibraryDeclarations {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][int]$SourceIndex,
        [Parameter(Mandatory = $true)][string]$SourceEntry
    )

    $decls = New-Object System.Collections.Generic.List[object]
    $lines = Get-Content -LiteralPath $FilePath
    foreach ($line in $lines) {
        $trimmed = $line.TrimStart()
        if (
            $trimmed.StartsWith("library ", [System.StringComparison]::OrdinalIgnoreCase) -or
            $trimmed.StartsWith("library_once ", [System.StringComparison]::OrdinalIgnoreCase)
        ) {
            $decl = Parse-LibraryDeclarationLine -DeclarationLine $trimmed -SourceIndex $SourceIndex -SourceEntry $SourceEntry
            if ($null -ne $decl) {
                $decls.Add($decl)
            }
        }
    }
    return $decls
}

function Validate-DiscoveredDependencies {
    param([Parameter(Mandatory = $true)][string[]]$Entries)

    $libraries = New-Object System.Collections.Generic.List[object]
    $libByName = @{}
    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $Entries.Count; $i++) {
        $entry = $Entries[$i]
        $full = Resolve-AbsolutePath -PathValue $entry -BaseDir $workspaceRoot
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            continue
        }

        $decls = @(Get-LibraryDeclarations -FilePath $full -SourceIndex ($i + 1) -SourceEntry $entry)
        if ($decls.Count -eq 0) {
            $warnings.Add("Non-library source discovered: '$entry' (compiler order is only guaranteed for library/require dependencies)")
            continue
        }

        foreach ($decl in $decls) {
            $libraries.Add($decl)
            if ($libByName.ContainsKey($decl.Name)) {
                $prev = $libByName[$decl.Name]
                $errors.Add("Duplicate library '$($decl.Name)': '$($prev.SourceEntry)' and '$($decl.SourceEntry)'")
            }
            else {
                $libByName[$decl.Name] = $decl
            }
        }
    }

    foreach ($lib in $libraries) {
        foreach ($req in $lib.Requires) {
            if (-not $libByName.ContainsKey($req.Name)) {
                if ($req.Optional) {
                    $warnings.Add("Optional require '$($req.Name)' missing for '$($lib.Name)' ('$($lib.SourceEntry)')")
                }
                else {
                    $errors.Add("Missing require '$($req.Name)' for '$($lib.Name)' ('$($lib.SourceEntry)')")
                }
            }
        }
    }

    if ($warnings.Count -gt 0) {
        Write-Host "[build-jass] Validation warnings:" -ForegroundColor Yellow
        foreach ($w in $warnings) {
            Write-Host "  - $w" -ForegroundColor Yellow
        }
    }

    if ($errors.Count -gt 0) {
        $msg = "Require validation failed (`$SkipRequireValidation to bypass):`n - " + ($errors -join "`n - ")
        throw $msg
    }
}

function Invoke-Build {
    $entries = @(Get-DiscoverableSourceEntries)
    if ($entries.Count -eq 0) {
        throw "No .j source files discovered under: $workspaceRoot"
    }

    if (-not $SkipRequireValidation) {
        Validate-DiscoveredDependencies -Entries $entries
    }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("// AUTO-GENERATED FILE. DO NOT EDIT DIRECTLY.")
    [void]$sb.AppendLine("// Source discovery: all .j files excluding: $($IgnoreDirs -join ', ')")
    [void]$sb.AppendLine("// Source order: deterministic path sort; vJASS library requires own compile/init order.")
    [void]$sb.AppendLine("// Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("")

    foreach ($entry in $entries) {
        $full = Resolve-AbsolutePath -PathValue $entry -BaseDir $workspaceRoot
        $rel = Get-RelativePathSafe -BaseDir $workspaceRoot -TargetPath $full
        $content = Get-Content -LiteralPath $full -Raw

        [void]$sb.AppendLine("// ===== BEGIN: $rel =====")
        [void]$sb.AppendLine($content)
        if (-not $content.EndsWith("`n")) {
            [void]$sb.AppendLine("")
        }
        [void]$sb.AppendLine("// ===== END: $rel =====")
        [void]$sb.AppendLine("")
    }

    $newContent = $sb.ToString()

    if (Test-Path -LiteralPath $outputAbs -PathType Leaf) {
        $oldContent = Get-Content -LiteralPath $outputAbs -Raw
        if ($oldContent -eq $newContent) {
            Write-Host "[build-jass] No changes: $outputAbs"
            return $false
        }
    }

    $outDir = Split-Path -Parent $outputAbs
    if (-not (Test-Path -LiteralPath $outDir -PathType Container)) {
        New-Item -ItemType Directory -Path $outDir | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($outputAbs, $newContent, $utf8NoBom)

    Write-Host "[build-jass] Generated: $outputAbs"
    Write-Host "[build-jass] Sources: $($entries.Count)"

    return $true
}

[void](Invoke-Build)

if (-not $Watch) {
    exit 0
}

$script:pendingBuild = $false
$script:lastEventAt = Get-Date

$buildSignalAction = {
    param($sender, $eventArgs)
    $changedPath = [System.IO.Path]::GetFullPath($eventArgs.FullPath)

    if ($changedPath -ieq $using:outputAbs) {
        return
    }
    foreach ($dir in $using:ignoreAbsDirs) {
        if ($changedPath.StartsWith($dir, [System.StringComparison]::OrdinalIgnoreCase)) {
            return
        }
    }

    $script:pendingBuild = $true
    $script:lastEventAt = Get-Date
}

$watcherSource = New-Object System.IO.FileSystemWatcher
$watcherSource.Path = $workspaceRoot
$watcherSource.Filter = "*.j"
$watcherSource.IncludeSubdirectories = $true
$watcherSource.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite, Size'
$watcherSource.EnableRaisingEvents = $true

Register-ObjectEvent -InputObject $watcherSource -EventName Changed -Action $buildSignalAction | Out-Null
Register-ObjectEvent -InputObject $watcherSource -EventName Created -Action $buildSignalAction | Out-Null
Register-ObjectEvent -InputObject $watcherSource -EventName Deleted -Action $buildSignalAction | Out-Null
Register-ObjectEvent -InputObject $watcherSource -EventName Renamed -Action $buildSignalAction | Out-Null

Write-Host "[build-jass] Watch mode ON (debounce ${DebounceMs}ms)"
Write-Host "[build-jass] Watching .j files under: $workspaceRoot"
Write-Host "[build-jass] Output: $outputAbs"
if ($ignoreAbsDirs.Count -gt 0) {
    Write-Host "[build-jass] Ignoring folders:"
    foreach ($dir in $ignoreAbsDirs) {
        Write-Host "  - $($dir.TrimEnd('\'))"
    }
}

try {
    while ($true) {
        Start-Sleep -Milliseconds 100

        if ($script:pendingBuild) {
            $elapsedMs = ((Get-Date) - $script:lastEventAt).TotalMilliseconds
            if ($elapsedMs -ge $DebounceMs) {
                $script:pendingBuild = $false
                try {
                    [void](Invoke-Build)
                }
                catch {
                    Write-Host "[build-jass] Build error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
}
finally {
    Get-EventSubscriber | Where-Object { $_.SourceObject -eq $watcherSource } | Unregister-Event
    $watcherSource.Dispose()
}

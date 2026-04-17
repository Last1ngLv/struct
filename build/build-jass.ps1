param(
    [string]$ManifestPath = "",
    [string]$OutputPath = "",
    [switch]$Watch,
    [int]$DebounceMs = 250,
    [string[]]$IgnoreDirs = @("build", "Pruebas", "logs"),
    [switch]$SkipRequireValidation,
    [switch]$AutoSyncManifest,
    [switch]$AutoOrderManifest
)

$ErrorActionPreference = "Stop"

function Resolve-AbsolutePath {
    param(
        [Parameter(Mandatory = $true)][string]$PathValue,
        [Parameter(Mandatory = $true)][string]$BaseDir
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return $PathValue
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

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = "build/jass-order.txt"
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = "build/AllCode.generated.j"
}

$manifestAbs = Resolve-AbsolutePath -PathValue $ManifestPath -BaseDir $workspaceRoot
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
    $normalized = $abs.TrimEnd("\", "/") + "\"
    $ignoreAbsDirs += $normalized
}

function Should-IgnorePath {
    param([Parameter(Mandatory = $true)][string]$CandidatePath)

    $candidate = [System.IO.Path]::GetFullPath($CandidatePath)
    foreach ($dir in $ignoreAbsDirs) {
        if ($candidate.StartsWith($dir, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Read-ManifestEntries {
    if (-not (Test-Path -LiteralPath $manifestAbs -PathType Leaf)) {
        throw "Manifest not found: $manifestAbs"
    }
    $items = Get-Content -LiteralPath $manifestAbs |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }
    if ($items.Count -eq 0) {
        throw "Manifest has no input files: $manifestAbs"
    }
    return $items
}

function Normalize-ManifestEntry {
    param([Parameter(Mandatory = $true)][string]$Entry)

    return $Entry.Trim().Replace("\", "/")
}

function Get-DiscoverableSourceEntries {
    $found = New-Object System.Collections.Generic.List[string]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    Get-ChildItem -Path $workspaceRoot -Recurse -File -Filter "*.j" | ForEach-Object {
        $full = [System.IO.Path]::GetFullPath($_.FullName)
        if ($full -ieq $outputAbs) {
            return
        }
        if (Should-IgnorePath -CandidatePath $full) {
            return
        }

        $rel = Get-RelativePathSafe -BaseDir $workspaceRoot -TargetPath $full
        $normalized = Normalize-ManifestEntry -Entry $rel
        if ($seen.Add($normalized)) {
            $found.Add($normalized)
        }
    }

    $found.Sort()
    return $found
}

function Sync-ManifestEntries {
    if (-not (Test-Path -LiteralPath $manifestAbs -PathType Leaf)) {
        throw "Manifest not found: $manifestAbs"
    }

    $rawLines = Get-Content -LiteralPath $manifestAbs
    $prefixLines = New-Object System.Collections.Generic.List[string]
    $startedEntries = $false
    foreach ($line in $rawLines) {
        $trim = $line.Trim()
        if (-not $startedEntries -and ($trim -eq "" -or $trim.StartsWith("#"))) {
            $prefixLines.Add($line)
            continue
        }
        $startedEntries = $true
    }

    $entries = Read-ManifestEntries | ForEach-Object { Normalize-ManifestEntry -Entry $_ }
    $existing = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $entries) {
        [void]$existing.Add($entry)
    }

    $discovered = Get-DiscoverableSourceEntries
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($entry in $discovered) {
        if (-not $existing.Contains($entry)) {
            $missing.Add($entry)
        }
    }

    $discoveredSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $discovered) {
        [void]$discoveredSet.Add($entry)
    }

    $stale = New-Object System.Collections.Generic.List[string]
    $kept = New-Object System.Collections.Generic.List[string]
    foreach ($entry in $entries) {
        if ($discoveredSet.Contains($entry)) {
            $kept.Add($entry)
        }
        else {
            $stale.Add($entry)
        }
    }

    if ($missing.Count -eq 0 -and $stale.Count -eq 0) {
        return $false
    }

    foreach ($entry in $missing) {
        $kept.Add($entry)
    }

    $sb = New-Object System.Text.StringBuilder
    foreach ($line in $prefixLines) {
        [void]$sb.AppendLine($line)
    }
    if ($prefixLines.Count -gt 0 -and $prefixLines[$prefixLines.Count - 1].Trim() -ne "") {
        [void]$sb.AppendLine("")
    }
    foreach ($entry in $kept) {
        [void]$sb.AppendLine($entry)
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($manifestAbs, $sb.ToString(), $utf8NoBom)

    if ($missing.Count -gt 0) {
        Write-Host "[build-jass] Manifest updated (+$($missing.Count)): $manifestAbs"
    }
    if ($stale.Count -gt 0) {
        Write-Host "[build-jass] Manifest pruned (-$($stale.Count)): $manifestAbs"
    }
    foreach ($entry in $missing) {
        Write-Host "  + $entry"
    }
    foreach ($entry in $stale) {
        Write-Host "  - $entry"
    }

    return $true
}

function Sort-ManifestByDependencies {
    if (-not (Test-Path -LiteralPath $manifestAbs -PathType Leaf)) {
        throw "Manifest not found: $manifestAbs"
    }

    $rawLines = Get-Content -LiteralPath $manifestAbs
    $prefixLines = New-Object System.Collections.Generic.List[string]
    $startedEntries = $false
    foreach ($line in $rawLines) {
        $trim = $line.Trim()
        if (-not $startedEntries -and ($trim -eq "" -or $trim.StartsWith("#"))) {
            $prefixLines.Add($line)
            continue
        }
        $startedEntries = $true
    }

    $entries = Read-ManifestEntries
    $entryMeta = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $entries.Count; $i++) {
        $entry = Normalize-ManifestEntry -Entry $entries[$i]
        $full = Resolve-AbsolutePath -PathValue $entry -BaseDir $workspaceRoot
        $decls = @()
        if (Test-Path -LiteralPath $full -PathType Leaf) {
            $decls = @(Get-LibraryDeclarations -FilePath $full -ManifestIndex ($i + 1) -ManifestEntry $entry)
        }

        $entryMeta.Add([pscustomobject]@{
            Entry = $entry
            Index = $i + 1
            Decls = $decls
        })
    }

    $libEntries = @($entryMeta | Where-Object { $_.Decls.Count -gt 0 })
    $otherEntries = @($entryMeta | Where-Object { $_.Decls.Count -eq 0 })

    $libByName = @{}
    $duplicates = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($meta in $libEntries) {
        foreach ($decl in $meta.Decls) {
            $name = $decl.Name
            if ($libByName.ContainsKey($name)) {
                [void]$duplicates.Add($name)
            }
            else {
                $libByName[$name] = $meta
            }
        }
    }

    $adj = @{}
    $inDeg = @{}
    foreach ($meta in $libEntries) {
        $adj[$meta.Entry] = New-Object System.Collections.Generic.List[string]
        $inDeg[$meta.Entry] = 0
    }

    foreach ($meta in $libEntries) {
        foreach ($decl in $meta.Decls) {
            $fromName = $decl.Name
            foreach ($req in $decl.Requires) {
                if (-not $libByName.ContainsKey($req.Name)) {
                    continue
                }
                if ($duplicates.Contains($fromName) -or $duplicates.Contains($req.Name)) {
                    continue
                }
                $depMeta = $libByName[$req.Name]
                if ($depMeta.Entry -eq $meta.Entry) {
                    continue
                }
                if (-not $adj[$depMeta.Entry].Contains($meta.Entry)) {
                    $adj[$depMeta.Entry].Add($meta.Entry)
                    $inDeg[$meta.Entry] = [int]$inDeg[$meta.Entry] + 1
                }
            }
        }
    }

    $queue = New-Object System.Collections.Generic.List[object]
    foreach ($meta in $libEntries) {
        if ($inDeg[$meta.Entry] -eq 0) {
            $queue.Add($meta)
        }
    }

    $orderedLib = New-Object System.Collections.Generic.List[object]
    while ($queue.Count -gt 0) {
        $current = $queue | Sort-Object Index | Select-Object -First 1
        [void]$queue.Remove($current)
        $orderedLib.Add($current)

        foreach ($nextEntry in $adj[$current.Entry]) {
            $inDeg[$nextEntry] = [int]$inDeg[$nextEntry] - 1
            if ($inDeg[$nextEntry] -eq 0) {
                $nextMeta = $libEntries | Where-Object { $_.Entry -eq $nextEntry } | Select-Object -First 1
                if ($nextMeta -ne $null) {
                    $queue.Add($nextMeta)
                }
            }
        }
    }

    # Si hay ciclos o duplicados, preserva el orden original para los restantes.
    $orderedSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($meta in $orderedLib) {
        [void]$orderedSet.Add($meta.Entry)
    }
    foreach ($meta in ($libEntries | Sort-Object Index)) {
        if (-not $orderedSet.Contains($meta.Entry)) {
            $orderedLib.Add($meta)
        }
    }

    $finalEntries = New-Object System.Collections.Generic.List[string]
    foreach ($meta in $orderedLib) {
        $finalEntries.Add($meta.Entry)
    }
    foreach ($meta in ($otherEntries | Sort-Object Index)) {
        $finalEntries.Add($meta.Entry)
    }

    $oldText = (Get-Content -LiteralPath $manifestAbs -Raw)
    $sb = New-Object System.Text.StringBuilder
    foreach ($line in $prefixLines) {
        [void]$sb.AppendLine($line)
    }
    if ($prefixLines.Count -gt 0 -and $prefixLines[$prefixLines.Count - 1].Trim() -ne "") {
        [void]$sb.AppendLine("")
    }
    foreach ($entry in $finalEntries) {
        [void]$sb.AppendLine($entry)
    }
    $newText = $sb.ToString()

    if ($newText -ne $oldText) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($manifestAbs, $newText, $utf8NoBom)
        Write-Host "[build-jass] Manifest reordered by requires: $manifestAbs"
        return $true
    }

    return $false
}

function Parse-LibraryDeclarationLine {
    param(
        [Parameter(Mandatory = $true)][string]$DeclarationLine,
        [Parameter(Mandatory = $true)][int]$ManifestIndex,
        [Parameter(Mandatory = $true)][string]$ManifestEntry
    )

    $lineNoComment = $DeclarationLine.Split("//")[0].Trim()
    if ([string]::IsNullOrWhiteSpace($lineNoComment)) {
        return $null
    }
    $match = [regex]::Match($lineNoComment, "(?i)^library\s+([A-Za-z_]\w*)\b(.*)$")
    if (-not $match.Success) {
        return $null
    }

    $libraryName = $match.Groups[1].Value
    $lineRemainder = $match.Groups[2].Value

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
            if ($token -eq "") {
                continue
            }

            # Si quedaron múltiples palabras, toma la primera como nombre de librería.
            # Evita ruido por comentarios/formato no estándar.
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
        Name          = $libraryName
        ManifestIndex = $ManifestIndex
        ManifestEntry = $ManifestEntry
        Requires      = $requires
    }
}

function Get-LibraryDeclarations {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][int]$ManifestIndex,
        [Parameter(Mandatory = $true)][string]$ManifestEntry
    )

    $decls = New-Object System.Collections.Generic.List[object]
    $lines = Get-Content -LiteralPath $FilePath
    foreach ($line in $lines) {
        $trimmed = $line.TrimStart()
        if ($trimmed.StartsWith("library ", [System.StringComparison]::OrdinalIgnoreCase)) {
            $decl = Parse-LibraryDeclarationLine -DeclarationLine $trimmed -ManifestIndex $ManifestIndex -ManifestEntry $ManifestEntry
            if ($null -ne $decl) {
                $decls.Add($decl)
            }
        }
    }
    return $decls
}

function Validate-ManifestDependencies {
    param(
        [Parameter(Mandatory = $true)][string[]]$Entries
    )

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

        $decls = @(Get-LibraryDeclarations -FilePath $full -ManifestIndex ($i + 1) -ManifestEntry $entry)
        if ($decls.Count -eq 0) {
            continue
        }

        foreach ($decl in $decls) {
            $libraries.Add($decl)
            if ($libByName.ContainsKey($decl.Name)) {
                $prev = $libByName[$decl.Name]
                $errors.Add("Duplicate library '$($decl.Name)': #$($prev.ManifestIndex) '$($prev.ManifestEntry)' and #$($decl.ManifestIndex) '$($decl.ManifestEntry)'")
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
                    $warnings.Add("Optional require '$($req.Name)' missing for '$($lib.Name)' (#$($lib.ManifestIndex) '$($lib.ManifestEntry)')")
                }
                else {
                    $errors.Add("Missing require '$($req.Name)' for '$($lib.Name)' (#$($lib.ManifestIndex) '$($lib.ManifestEntry)')")
                }
                continue
            }

            $dep = $libByName[$req.Name]
            if ($dep.ManifestIndex -gt $lib.ManifestIndex) {
                $errors.Add("Order violation: '$($lib.Name)' (#$($lib.ManifestIndex)) requires '$($req.Name)' (#$($dep.ManifestIndex)); move '$($dep.ManifestEntry)' above '$($lib.ManifestEntry)'")
            }
        }
    }

    if ($warnings.Count -gt 0) {
        Write-Host "[build-jass] Require warnings:" -ForegroundColor Yellow
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
    if ($script:useAutoSyncManifest) {
        [void](Sync-ManifestEntries)
    }
    if ($script:useAutoOrderManifest) {
        [void](Sort-ManifestByDependencies)
    }

    $entries = Read-ManifestEntries
    if (-not $SkipRequireValidation) {
        Validate-ManifestDependencies -Entries $entries
    }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("// AUTO-GENERATED FILE. DO NOT EDIT DIRECTLY.")
    [void]$sb.AppendLine("// Source manifest: $([System.IO.Path]::GetFileName($manifestAbs))")
    [void]$sb.AppendLine("// Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("")

    $missing = New-Object System.Collections.Generic.List[string]

    foreach ($entry in $entries) {
        $full = Resolve-AbsolutePath -PathValue $entry -BaseDir $workspaceRoot
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            $missing.Add($entry)
            continue
        }

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

    if ($missing.Count -gt 0) {
        $list = $missing -join ", "
        throw "Missing files from manifest: $list"
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

    return $true
}

$script:useAutoSyncManifest = $AutoSyncManifest -or $Watch
$script:useAutoOrderManifest = $AutoOrderManifest -or $Watch
[void](Invoke-Build)

if (-not $Watch) {
    exit 0
}

$manifestDir = Split-Path -Parent $manifestAbs
$manifestName = Split-Path -Leaf $manifestAbs

$script:pendingBuild = $false
$script:lastEventAt = Get-Date

$buildSignalAction = {
    param($sender, $eventArgs)
    $changedPath = [System.IO.Path]::GetFullPath($eventArgs.FullPath)

    if ($changedPath -ieq $using:outputAbs) {
        return
    }
    if ($using:ignoreAbsDirs.Count -gt 0) {
        foreach ($dir in $using:ignoreAbsDirs) {
            if ($changedPath.StartsWith($dir, [System.StringComparison]::OrdinalIgnoreCase)) {
                return
            }
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

$watcherManifest = New-Object System.IO.FileSystemWatcher
$watcherManifest.Path = $manifestDir
$watcherManifest.Filter = $manifestName
$watcherManifest.IncludeSubdirectories = $false
$watcherManifest.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite, Size'
$watcherManifest.EnableRaisingEvents = $true

Register-ObjectEvent -InputObject $watcherSource -EventName Changed -Action $buildSignalAction | Out-Null
Register-ObjectEvent -InputObject $watcherSource -EventName Created -Action $buildSignalAction | Out-Null
Register-ObjectEvent -InputObject $watcherSource -EventName Deleted -Action $buildSignalAction | Out-Null
Register-ObjectEvent -InputObject $watcherSource -EventName Renamed -Action $buildSignalAction | Out-Null

Register-ObjectEvent -InputObject $watcherManifest -EventName Changed -Action $buildSignalAction | Out-Null
Register-ObjectEvent -InputObject $watcherManifest -EventName Created -Action $buildSignalAction | Out-Null
Register-ObjectEvent -InputObject $watcherManifest -EventName Deleted -Action $buildSignalAction | Out-Null
Register-ObjectEvent -InputObject $watcherManifest -EventName Renamed -Action $buildSignalAction | Out-Null

Write-Host "[build-jass] Watch mode ON (debounce ${DebounceMs}ms)"
Write-Host "[build-jass] Watching .j files under: $workspaceRoot"
Write-Host "[build-jass] Watching manifest: $manifestAbs"
Write-Host "[build-jass] AutoSyncManifest: $script:useAutoSyncManifest"
Write-Host "[build-jass] AutoOrderManifest: $script:useAutoOrderManifest"
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
    Get-EventSubscriber | Where-Object {
        $_.SourceObject -eq $watcherSource -or $_.SourceObject -eq $watcherManifest
    } | Unregister-Event

    $watcherSource.Dispose()
    $watcherManifest.Dispose()
}

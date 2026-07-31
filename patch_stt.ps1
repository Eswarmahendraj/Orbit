# Patch speech_to_text-6.6.2: remove V1 embedding (Registrar) code that no longer compiles
$f = "D:\pub_cache\hosted\pub.dev\speech_to_text-6.6.2\android\src\main\kotlin\com\csdcorp\speech_to_text\SpeechToTextPlugin.kt"

if (-not (Test-Path $f)) {
    Write-Host "File not found: $f" -ForegroundColor Red
    exit 1
}

$lines = Get-Content $f
$result = [System.Collections.Generic.List[string]]::new()

$inCompanion = $false
$braceDepth  = 0
$skipped     = 0

foreach ($line in $lines) {
    # Remove the Registrar import line
    if ($line -match 'import.*PluginRegistry\.Registrar') {
        $result.Add("// PATCHED: $line")
        $skipped++
        continue
    }

    if (-not $inCompanion) {
        # Detect start of companion object block
        if ($line -match '^\s*companion object') {
            $inCompanion = $true
            $braceDepth  = ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count `
                         - ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
            $result.Add("// PATCHED OUT companion object (V1 embedding)")
            $skipped++
            continue
        }
        $result.Add($line)
    } else {
        # Count braces to find the closing } of companion object
        $open  = ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
        $close = ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
        $braceDepth += $open - $close
        $skipped++
        if ($braceDepth -le 0) {
            $inCompanion = $false
        }
    }
}

$result | Set-Content $f -Encoding UTF8
Write-Host "Patched speech_to_text: $skipped lines removed/commented (Registrar import + companion object)" -ForegroundColor Green

Set-Location D:\AURA_App
$env:PATH = "D:\flutter\bin;" + $env:PATH
$env:PUB_CACHE = "D:\pub_cache"
flutter analyze 2>&1 | Out-File -FilePath D:\AURA_App\analyze_output.txt -Encoding utf8
Write-Host "Done" -ForegroundColor Green

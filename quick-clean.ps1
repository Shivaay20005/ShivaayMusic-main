# Quick Project Cleaner - एक command में सब clean!
# Run: .\quick-clean.ps1

Write-Host "⚡ QUICK CLEAN शुरू..." -ForegroundColor Yellow

# Stop everything
.\gradlew.bat --stop 2>$null
taskkill /f /im java.exe 2>$null

# Delete main directories
$dirs = @("build", "app\build", ".gradle", "$env:USERPROFILE\.gradle\caches")
$dirs | ForEach-Object { if (Test-Path $_) { Remove-Item -Recurse -Force $_ 2>$null } }

# Clean all build dirs recursively  
Get-ChildItem -Recurse -Directory -Name "build" 2>$null | ForEach-Object { Remove-Item -Recurse -Force $_ 2>$null }

# Quick gradle clean
.\gradlew.bat clean --no-daemon 2>$null

Write-Host "✅ CLEAN COMPLETE! अब build करें: .\gradlew.bat build" -ForegroundColor Green
# Shivaay Music - Complete Project Cleaner Script
# यह script आपके Android project को completely clean कर देगी
# Run: .\clean-project.ps1

Write-Host "🚀 शुरू हो रहा है Complete Project Cleaning..." -ForegroundColor Green
Write-Host ""

# Function to safely remove directories
function Remove-DirectorySafely {
    param([string]$Path, [string]$Description)
    
    if (Test-Path $Path) {
        try {
            Write-Host "🗑️  $Description को delete कर रहे हैं..." -ForegroundColor Yellow
            Remove-Item -Recurse -Force $Path -ErrorAction Stop
            Write-Host "✅ $Description successfully deleted!" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  $Description delete करने में error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "ℹ️  $Description already नहीं है" -ForegroundColor Cyan
    }
}

# Function to safely remove files
function Remove-FileSafely {
    param([string]$Path, [string]$Description)
    
    if (Test-Path $Path) {
        try {
            Write-Host "🗑️  $Description को delete कर रहे हैं..." -ForegroundColor Yellow
            Remove-Item -Force $Path -ErrorAction Stop
            Write-Host "✅ $Description successfully deleted!" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠️  $Description delete करने में error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "ℹ️  $Description already नहीं है" -ForegroundColor Cyan
    }
}

Write-Host "🛑 Step 1: Gradle Daemons को stop कर रहे हैं..." -ForegroundColor Magenta
try {
    & .\gradlew.bat --stop 2>$null
    Write-Host "✅ Gradle daemons stopped!" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  Gradle daemon stop करने में error, continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "💀 Step 2: Java processes को kill कर रहे हैं..." -ForegroundColor Magenta
try {
    taskkill /f /im java.exe 2>$null
    Start-Sleep -Seconds 2
    Write-Host "✅ Java processes killed!" -ForegroundColor Green
}
catch {
    Write-Host "ℹ️  कोई Java process running नहीं था" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🧹 Step 3: Project के सारे build directories clean कर रहे हैं..." -ForegroundColor Magenta

# Project की सारी build directories
$buildDirs = @(
    "build",
    "app\build",
    "innertube\build", 
    "jossredconnect\build",
    "kizzy\build",
    "kugou\build",
    "lrclib\build",
    "material-color-utilities\build"
)

foreach ($dir in $buildDirs) {
    Remove-DirectorySafely -Path $dir -Description "Build directory: $dir"
}

# Recursively find और delete करें सारी build directories
Write-Host "🔍 Recursively सारी build directories ढूंढ रहे हैं..." -ForegroundColor Yellow
try {
    Get-ChildItem -Recurse -Directory -Name "build" -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-DirectorySafely -Path $_ -Description "Build directory: $_"
    }
}
catch {
    Write-Host "ℹ️  Recursive build cleanup completed" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📱 Step 4: Android specific cache directories..." -ForegroundColor Magenta

# Android specific directories
$androidDirs = @(
    "app\.cxx",
    "app\src\main\assets\temp",
    ".gradle",
    ".idea\caches"
)

foreach ($dir in $androidDirs) {
    Remove-DirectorySafely -Path $dir -Description "Android cache: $dir"
}

Write-Host ""
Write-Host "🌐 Step 5: Global Gradle cache clean कर रहे हैं..." -ForegroundColor Magenta

# Global Gradle cache directories
$gradleCacheDirs = @(
    "$env:USERPROFILE\.gradle\caches",
    "$env:USERPROFILE\.gradle\daemon", 
    "$env:USERPROFILE\.gradle\wrapper\dists\.tmp",
    "$env:USERPROFILE\.android\build-cache"
)

foreach ($dir in $gradleCacheDirs) {
    Remove-DirectorySafely -Path $dir -Description "Global cache: $dir"
}

Write-Host ""
Write-Host "📝 Step 6: Temp files और logs clean कर रहे हैं..." -ForegroundColor Magenta

# Temp files और logs
$tempFiles = @(
    "*.log",
    "*.tmp",
    "hs_err_pid*.log",
    "replay_pid*.log"
)

foreach ($pattern in $tempFiles) {
    try {
        Get-ChildItem -File $pattern -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-FileSafely -Path $_.FullName -Description "Temp file: $($_.Name)"
        }
    }
    catch {
        # Silent continue
    }
}

Write-Host ""
Write-Host "🔧 Step 7: IDE specific files clean कर रहे हैं..." -ForegroundColor Magenta

$ideDirs = @(
    ".idea\shelf",
    ".idea\workspace.xml",
    ".idea\tasks.xml",
    ".vscode",
    "*.iml"
)

foreach ($item in $ideDirs) {
    if ($item.Contains("*")) {
        try {
            Get-ChildItem -File $item -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-FileSafely -Path $_.FullName -Description "IDE file: $($_.Name)"
            }
        }
        catch {
            # Silent continue
        }
    }
    else {
        Remove-DirectorySafely -Path $item -Description "IDE directory: $item"
    }
}

Write-Host ""
Write-Host "🎯 Step 8: Final Gradle clean command..." -ForegroundColor Magenta

try {
    Write-Host "▶️  Gradle clean command चला रहे हैं..." -ForegroundColor Yellow
    & .\gradlew.bat clean --no-daemon 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Gradle clean successful!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Gradle clean में कुछ warnings हो सकती हैं, लेकिन project clean हो गया" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "ℹ️  Gradle clean skip कर रहे हैं (files already cleaned)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "🎉 PROJECT COMPLETELY CLEANED! 🎉" -ForegroundColor Green -BackgroundColor Black
Write-Host "=" * 60 -ForegroundColor Green
Write-Host ""
Write-Host "✅ अब आप fresh build कर सकते हैं:" -ForegroundColor Cyan
Write-Host "   .\gradlew.bat build" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""
Write-Host "✅ Release APK बनाने के लिए:" -ForegroundColor Cyan  
Write-Host "   .\gradlew.bat assembleRelease" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""
Write-Host "🚀 Happy Coding! Project clean और ready है!" -ForegroundColor Green

# Optional: Ask user if they want to build immediately
Write-Host ""
$buildNow = Read-Host "क्या आप अभी build करना चाहते हैं? (y/n)"
if ($buildNow -eq 'y' -or $buildNow -eq 'Y' -or $buildNow -eq 'yes') {
    Write-Host ""
    Write-Host "🚀 Building project..." -ForegroundColor Green
    & .\gradlew.bat build
}
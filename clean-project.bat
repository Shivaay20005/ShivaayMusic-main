@echo off
echo ===============================================
echo   SHIVAAY MUSIC - PROJECT CLEANER
echo ===============================================
echo.

echo [1/5] Stopping Gradle daemons...
call gradlew.bat --stop >nul 2>&1

echo [2/5] Killing Java processes...
taskkill /f /im java.exe >nul 2>&1

echo [3/5] Deleting build directories...
if exist "build" rmdir /s /q "build" >nul 2>&1
if exist "app\build" rmdir /s /q "app\build" >nul 2>&1
if exist ".gradle" rmdir /s /q ".gradle" >nul 2>&1

echo [4/5] Cleaning global caches...
if exist "%USERPROFILE%\.gradle\caches" rmdir /s /q "%USERPROFILE%\.gradle\caches" >nul 2>&1

echo [5/5] Running Gradle clean...
call gradlew.bat clean --no-daemon >nul 2>&1

echo.
echo ===============================================
echo   PROJECT CLEANED SUCCESSFULLY! 
echo ===============================================
echo.
echo Ready to build! Run: gradlew.bat build
echo For APK: gradlew.bat assembleRelease
echo.
pause
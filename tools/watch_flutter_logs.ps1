param(
  [string]$DeviceId = "AAAJBB5102104110",
  [string]$PackageName = "com.pawmilya.pawmilya_app"
)

Write-Host "Clearing existing logcat buffer..." -ForegroundColor Cyan
adb -s $DeviceId logcat -c

Write-Host "Starting live logs for $PackageName ..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop." -ForegroundColor Yellow

adb -s $DeviceId logcat -v time | Select-String -Pattern "flutter|DartVM|AndroidRuntime|FATAL EXCEPTION|$PackageName|E/flutter" -CaseSensitive:$false

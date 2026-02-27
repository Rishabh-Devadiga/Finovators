[CmdletBinding()]
param(
  [string]$ApiBaseUrl = ""
)

$ErrorActionPreference = "Stop"

$repo = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repo

$releaseApk = Join-Path $repo "app/frontend/flutter_app/build/app/outputs/flutter-apk/app-release.apk"
$debugApk = Join-Path $repo "app/frontend/flutter_app/build/app/outputs/flutter-apk/app-debug.apk"
$targetApk = Join-Path $repo "app/releases/GigBit.apk"
$targetDir = Split-Path -Parent $targetApk
New-Item -ItemType Directory -Force $targetDir | Out-Null

if (Test-Path $releaseApk) {
  Copy-Item -Force $releaseApk $targetApk
  Write-Host "Copied release APK -> app/releases/GigBit.apk"
} elseif (Test-Path $debugApk) {
  Copy-Item -Force $debugApk $targetApk
  Write-Host "Copied debug APK -> app/releases/GigBit.apk"
} else {
  Write-Warning "No APK found. Build app first:"
  Write-Warning "  cd app/frontend/flutter_app"
  Write-Warning "  flutter build apk --release"
}

if ($ApiBaseUrl.Trim().Length -gt 0) {
  $api = $ApiBaseUrl.Trim()
  if ($api.EndsWith("/")) { $api = $api.TrimEnd("/") }
  foreach ($f in @("web/frontend/landing.html", "web/frontend/admin.html")) {
    $p = Join-Path $repo $f
    $content = Get-Content -Raw $p
    $updated = [Regex]::Replace(
      $content,
      '<meta name="gigbit-api-base" content="[^"]*"\s*/>',
      "<meta name=""gigbit-api-base"" content=""$api"" />"
    )
    Set-Content -Path $p -Value $updated
    Write-Host "Updated API base meta in $f"
  }
}

Write-Host "Done."

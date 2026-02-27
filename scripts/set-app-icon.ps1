param(
  [Parameter(Mandatory = $false)]
  [string]$IconPath = "app/frontend/flutter_app/assets/branding/app_icon.png"
)

$ErrorActionPreference = "Stop"

function Assert-File([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Icon not found: $Path`nPut your PNG at $Path (recommended), or run: powershell -ExecutionPolicy Bypass -File scripts/set-app-icon.ps1 -IconPath C:\path\to\icon.png"
  }
}

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

function Get-TrimRect([System.Drawing.Bitmap]$Bmp, [int]$AlphaThreshold = 8, [double]$PadRatio = 0.06) {
  Add-Type -AssemblyName System.Drawing

  $w = $Bmp.Width
  $h = $Bmp.Height
  $minX = $w
  $minY = $h
  $maxX = -1
  $maxY = -1

  $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
  $data = $Bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  try {
    $stride = [Math]::Abs($data.Stride)
    $bytes = $stride * $h
    $buf = New-Object byte[] $bytes
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $buf, 0, $bytes)

    for ($y = 0; $y -lt $h; $y++) {
      $row = $y * $stride
      for ($x = 0; $x -lt $w; $x++) {
        $idx = $row + ($x * 4)
        $a = $buf[$idx + 3]
        if ($a -gt $AlphaThreshold) {
          if ($x -lt $minX) { $minX = $x }
          if ($y -lt $minY) { $minY = $y }
          if ($x -gt $maxX) { $maxX = $x }
          if ($y -gt $maxY) { $maxY = $y }
        }
      }
    }
  } finally {
    $Bmp.UnlockBits($data)
  }

  if ($maxX -lt 0 -or $maxY -lt 0) {
    return $rect
  }

  $pad = [int][Math]::Round([Math]::Min($w, $h) * $PadRatio)
  $minX = [Math]::Max(0, $minX - $pad)
  $minY = [Math]::Max(0, $minY - $pad)
  $maxX = [Math]::Min($w - 1, $maxX + $pad)
  $maxY = [Math]::Min($h - 1, $maxY + $pad)

  $tw = ($maxX - $minX + 1)
  $th = ($maxY - $minY + 1)

  return New-Object System.Drawing.Rectangle($minX, $minY, $tw, $th)
}

function Resize-Png([string]$InPath, [string]$OutPath, [int]$Size) {
  Add-Type -AssemblyName System.Drawing

  $srcBmp = [System.Drawing.Bitmap]::FromFile($InPath)
  try {
    $trimRect = Get-TrimRect -Bmp $srcBmp
    $cropped = $srcBmp.Clone($trimRect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
      $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
      try {
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
          $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
          $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
          $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
          $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

          # Draw and crop to square (center-crop) to avoid letterboxing.
          $scale = [Math]::Max($Size / $cropped.Width, $Size / $cropped.Height)
          $drawW = [int][Math]::Ceiling($cropped.Width * $scale)
          $drawH = [int][Math]::Ceiling($cropped.Height * $scale)
          $x = [int][Math]::Floor(($Size - $drawW) / 2)
          $y = [int][Math]::Floor(($Size - $drawH) / 2)
          $g.DrawImage($cropped, $x, $y, $drawW, $drawH)

          $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png) | Out-Null
        } finally {
          $g.Dispose()
        }
      } finally {
        $bmp.Dispose()
      }
    } finally {
      $cropped.Dispose()
    }
  } finally {
    $srcBmp.Dispose()
  }
}

Assert-File $IconPath

Ensure-Dir "app/frontend/flutter_app/assets/branding"

$targets = @(
  @{ Dir = "app/frontend/flutter_app/android/app/src/main/res/mipmap-mdpi";   Size = 48  }
  @{ Dir = "app/frontend/flutter_app/android/app/src/main/res/mipmap-hdpi";   Size = 72  }
  @{ Dir = "app/frontend/flutter_app/android/app/src/main/res/mipmap-xhdpi";  Size = 96  }
  @{ Dir = "app/frontend/flutter_app/android/app/src/main/res/mipmap-xxhdpi"; Size = 144 }
  @{ Dir = "app/frontend/flutter_app/android/app/src/main/res/mipmap-xxxhdpi"; Size = 192 }
)

foreach ($t in $targets) {
  Ensure-Dir $t.Dir
  $out = Join-Path $t.Dir "ic_launcher.png"
  Resize-Png -InPath $IconPath -OutPath $out -Size $t.Size
  Write-Host "Wrote $out"
}

Write-Host "Done. Rebuild / reinstall the app to see the new launcher icon."

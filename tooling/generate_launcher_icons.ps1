Add-Type -AssemblyName System.Drawing

function New-RoundedPath {
  param(
    [single]$X,
    [single]$Y,
    [single]$Width,
    [single]$Height,
    [single]$Radius
  )

  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  if ($Radius -le 0) {
    $path.AddRectangle((New-Object System.Drawing.RectangleF($X, $Y, $Width, $Height)))
    return $path
  }

  $diameter = [single]($Radius * 2)
  $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $path.AddArc([single]($X + $Width - $diameter), $Y, $diameter, $diameter, 270, 90)
  $path.AddArc(
    [single]($X + $Width - $diameter),
    [single]($Y + $Height - $diameter),
    $diameter,
    $diameter,
    0,
    90
  )
  $path.AddArc($X, [single]($Y + $Height - $diameter), $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function Save-TransPilotIcon {
  param(
    [string]$OutputPath,
    [int]$Size,
    [bool]$RoundedBackground
  )

  $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.Clear([System.Drawing.Color]::Transparent)

  $sizeF = [single]$Size
  $backgroundBrush = New-Object System.Drawing.SolidBrush(
    [System.Drawing.Color]::FromArgb(14, 95, 101)
  )
  $glowBrush = New-Object System.Drawing.SolidBrush(
    [System.Drawing.Color]::FromArgb(34, 255, 255, 255)
  )
  $headBrush = New-Object System.Drawing.SolidBrush(
    [System.Drawing.Color]::FromArgb(161, 244, 235)
  )
  $tipBrush = New-Object System.Drawing.SolidBrush(
    [System.Drawing.Color]::FromArgb(241, 255, 251)
  )
  $stemBrush = New-Object System.Drawing.SolidBrush(
    [System.Drawing.Color]::FromArgb(174, 255, 247)
  )
  $shadowBrush = New-Object System.Drawing.SolidBrush(
    [System.Drawing.Color]::FromArgb(150, 7, 34, 37)
  )

  if ($RoundedBackground) {
    $bgPath = New-RoundedPath -X 0 -Y 0 -Width $sizeF -Height $sizeF -Radius ([single]($sizeF * 0.23))
    $graphics.FillPath($backgroundBrush, $bgPath)
    $bgPath.Dispose()
  } else {
    $graphics.FillRectangle($backgroundBrush, 0, 0, $sizeF, $sizeF)
  }

  $graphics.FillEllipse(
    $glowBrush,
    [single]($sizeF * 0.14),
    [single]($sizeF * 0.12),
    [single]($sizeF * 0.72),
    [single]($sizeF * 0.28)
  )
  $graphics.FillEllipse(
    $shadowBrush,
    [single]($sizeF * 0.34),
    [single]($sizeF * 0.71),
    [single]($sizeF * 0.32),
    [single]($sizeF * 0.08)
  )
  $graphics.FillRectangle(
    $stemBrush,
    [single]($sizeF * 0.452),
    [single]($sizeF * 0.31),
    [single]($sizeF * 0.096),
    [single]($sizeF * 0.36)
  )

  $headPoints = [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF([single]($sizeF * 0.50), [single]($sizeF * 0.20))),
    (New-Object System.Drawing.PointF([single]($sizeF * 0.67), [single]($sizeF * 0.39))),
    (New-Object System.Drawing.PointF([single]($sizeF * 0.50), [single]($sizeF * 0.34))),
    (New-Object System.Drawing.PointF([single]($sizeF * 0.33), [single]($sizeF * 0.39)))
  )
  $graphics.FillPolygon($headBrush, $headPoints)

  $tipPoints = [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF([single]($sizeF * 0.50), [single]($sizeF * 0.22))),
    (New-Object System.Drawing.PointF([single]($sizeF * 0.61), [single]($sizeF * 0.31))),
    (New-Object System.Drawing.PointF([single]($sizeF * 0.50), [single]($sizeF * 0.285))),
    (New-Object System.Drawing.PointF([single]($sizeF * 0.39), [single]($sizeF * 0.31)))
  )
  $graphics.FillPolygon($tipBrush, $tipPoints)

  $directory = Split-Path $OutputPath -Parent
  if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
  }

  $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

  $shadowBrush.Dispose()
  $stemBrush.Dispose()
  $tipBrush.Dispose()
  $headBrush.Dispose()
  $glowBrush.Dispose()
  $backgroundBrush.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
}

$projectRoot = Split-Path $PSScriptRoot -Parent
$icons = @(
  [pscustomobject]@{ Path = (Join-Path $projectRoot "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"); Size = 48; Rounded = $true },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"); Size = 72; Rounded = $true },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"); Size = 96; Rounded = $true },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"); Size = 144; Rounded = $true },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"); Size = 192; Rounded = $true },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"); Size = 20; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"); Size = 40; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"); Size = 60; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"); Size = 29; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"); Size = 58; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"); Size = 87; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"); Size = 40; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"); Size = 80; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"); Size = 120; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"); Size = 120; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"); Size = 180; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"); Size = 76; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"); Size = 152; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"); Size = 167; Rounded = $false },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"); Size = 1024; Rounded = $false }
)

foreach ($icon in $icons) {
  Save-TransPilotIcon -OutputPath $icon.Path -Size $icon.Size -RoundedBackground $icon.Rounded
}

$cleanup = @(
  (Join-Path $projectRoot "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_preview.png"),
  (Join-Path $projectRoot "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_preview2.png"),
  (Join-Path $projectRoot "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_test.png"),
  (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x-preview.png"),
  (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x-preview2.png"),
  (Join-Path $projectRoot "probe_direct.png"),
  (Join-Path $projectRoot "probe_simple.png"),
  (Join-Path $projectRoot "probe_transpilot_180.png")
)

foreach ($file in $cleanup) {
  if (Test-Path $file) {
    Remove-Item $file -Force
  }
}

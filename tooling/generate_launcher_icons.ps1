Add-Type -AssemblyName System.Drawing

function Save-ResizedIcon {
  param(
    [string]$SourcePath,
    [string]$OutputPath,
    [int]$Size
  )

  $source = [System.Drawing.Image]::FromFile($SourcePath)
  $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $graphics.Clear([System.Drawing.Color]::Transparent)
  $graphics.DrawImage($source, 0, 0, $Size, $Size)

  $directory = Split-Path $OutputPath -Parent
  if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
  }

  $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

  $graphics.Dispose()
  $bitmap.Dispose()
  $source.Dispose()
}

$projectRoot = Split-Path $PSScriptRoot -Parent
$sourceIcon = Join-Path $projectRoot "icon.png"

if (-not (Test-Path $sourceIcon)) {
  throw "Source icon not found: $sourceIcon"
}

$icons = @(
  [pscustomobject]@{ Path = (Join-Path $projectRoot "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"); Size = 48 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"); Size = 72 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"); Size = 96 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"); Size = 144 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"); Size = 192 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"); Size = 20 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"); Size = 40 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"); Size = 60 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"); Size = 29 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"); Size = 58 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"); Size = 87 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"); Size = 40 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"); Size = 80 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"); Size = 120 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"); Size = 120 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"); Size = 180 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"); Size = 76 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"); Size = 152 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"); Size = 167 },
  [pscustomobject]@{ Path = (Join-Path $projectRoot "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"); Size = 1024 }
)

foreach ($icon in $icons) {
  Save-ResizedIcon -SourcePath $sourceIcon -OutputPath $icon.Path -Size $icon.Size
}

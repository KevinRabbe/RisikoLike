$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repo = Split-Path -Parent $PSScriptRoot
$assetRoot = Join-Path $repo 'assets\ui\atlas_front'
$auditRoot = Join-Path $assetRoot '_audit'
$contactPath = Join-Path $auditRoot 'extraction_contact.png'
New-Item -ItemType Directory -Force -Path $auditRoot | Out-Null

$files = Get-ChildItem -LiteralPath $assetRoot -Recurse -File -Filter '*.png' | Where-Object { $_.FullName -ne $contactPath } | Sort-Object FullName
$columns = 4
$tileWidth = 320
$tileHeight = 230
$rows = [math]::Ceiling($files.Count / $columns)
$canvasWidth = [int]($columns * $tileWidth)
$canvasHeight = [int]($rows * $tileHeight)
$canvas = New-Object System.Drawing.Bitmap -ArgumentList @($canvasWidth, $canvasHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$graphics.Clear([System.Drawing.Color]::FromArgb(7, 17, 29))
$font = New-Object System.Drawing.Font -ArgumentList @('Arial', 9)
$brush = New-Object System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::FromArgb(225, 230, 238))
$lightCheckerBrush = New-Object System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::FromArgb(38, 51, 64))
$darkCheckerBrush = New-Object System.Drawing.SolidBrush -ArgumentList @([System.Drawing.Color]::FromArgb(25, 35, 47))

for ($index = 0; $index -lt $files.Count; $index++) {
    $file = $files[$index]
    $column = $index % $columns
    $row = [math]::Floor($index / $columns)
    $left = $column * $tileWidth
    $top = $row * $tileHeight
    $preview = New-Object System.Drawing.Rectangle -ArgumentList @([int]($left + 6), [int]($top + 6), [int]($tileWidth - 12), 178)
    for ($checkerY = $preview.Top; $checkerY -lt $preview.Bottom; $checkerY += 16) {
        for ($checkerX = $preview.Left; $checkerX -lt $preview.Right; $checkerX += 16) {
            $even = ((($checkerX - $preview.Left) / 16) + (($checkerY - $preview.Top) / 16)) % 2 -eq 0
            $checkerBrush = if ($even) { $lightCheckerBrush } else { $darkCheckerBrush }
            $graphics.FillRectangle($checkerBrush, $checkerX, $checkerY, 16, 16)
        }
    }
    $image = [System.Drawing.Image]::FromFile($file.FullName)
    $scale = [math]::Min(($preview.Width - 8) / $image.Width, ($preview.Height - 8) / $image.Height)
    $drawWidth = [int]([math]::Max(1, $image.Width * $scale))
    $drawHeight = [int]([math]::Max(1, $image.Height * $scale))
    $drawX = $preview.Left + [int](($preview.Width - $drawWidth) / 2)
    $drawY = $preview.Top + [int](($preview.Height - $drawHeight) / 2)
    $graphics.DrawImage($image, $drawX, $drawY, $drawWidth, $drawHeight)
    $image.Dispose()
    $relative = $file.FullName.Substring($assetRoot.Length + 1).Replace('\', '/')
    $graphics.DrawString($relative, $font, $brush, $left + 8, $top + 191)
}

$canvas.Save($contactPath, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$font.Dispose()
$brush.Dispose()
$lightCheckerBrush.Dispose()
$darkCheckerBrush.Dispose()
$canvas.Dispose()
Write-Output ("CONTACT_SHEET={0}" -f $contactPath)
Write-Output ("CONTACT_ASSETS={0}" -f $files.Count)

Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies 'System.Drawing.dll' @"
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class AtlasAssetExtractor
{
    public static void Extract(string sourcePath, string outputPath, int x, int y, int width, int height, bool alphaKey, bool cyanKey)
    {
        using (var source = new Bitmap(sourcePath))
        using (var crop = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(crop))
        {
            graphics.DrawImage(source, new Rectangle(0, 0, width, height), new Rectangle(x, y, width, height), GraphicsUnit.Pixel);
            if (alphaKey)
            {
                for (var py = 0; py < crop.Height; py++)
                {
                    for (var px = 0; px < crop.Width; px++)
                    {
                        var color = crop.GetPixel(px, py);
                        var maximum = Math.Max(color.R, Math.Max(color.G, color.B));
                        var minimum = Math.Min(color.R, Math.Min(color.G, color.B));
                        var saturation = maximum - minimum;
                        var alpha = SmoothStep(25.0, 98.0, maximum);
                        if (cyanKey)
                        {
                            var cyanSignal = Math.Max(0.0, color.G - color.R);
                            var whiteSignal = Math.Min(color.R, Math.Min(color.G, color.B));
                            var cyanAlpha = SmoothStep(22.0, 78.0, cyanSignal);
                            var whiteAlpha = SmoothStep(145.0, 225.0, whiteSignal);
                            alpha = Math.Max(cyanAlpha, whiteAlpha) * SmoothStep(38.0, 145.0, maximum);
                        }
                        else if (saturation < 12 && maximum < 120)
                        {
                            alpha *= 0.55;
                        }
                        alpha = Math.Pow(alpha, 1.65);
                        crop.SetPixel(px, py, Color.FromArgb((int)Math.Round(alpha * 255.0), color.R, color.G, color.B));
                    }
                }
            }
            else
            {
                for (var py = 0; py < crop.Height; py++)
                {
                    for (var px = 0; px < crop.Width; px++)
                    {
                        var color = crop.GetPixel(px, py);
                        crop.SetPixel(px, py, Color.FromArgb(255, color.R, color.G, color.B));
                    }
                }
            }
            crop.Save(outputPath, ImageFormat.Png);
        }
    }

    private static double SmoothStep(double edge0, double edge1, double value)
    {
        var t = Math.Max(0.0, Math.Min(1.0, (value - edge0) / (edge1 - edge0)));
        return t * t * (3.0 - 2.0 * t);
    }
}
"@

$repo = Split-Path -Parent $PSScriptRoot
$outputRoot = Join-Path $repo 'assets\ui\atlas_front'
$sheetOne = 'D:\Downloads\ChatGPT-Bild 28. Sept. 2026, 18_39_58-1.png'
$sheetTwo = 'D:\Downloads\ChatGPT-Bild 28. Sept. 2026, 18_39_59-2.png'

$assets = @(
    @{ Source = $sheetTwo; Relative = 'backgrounds\main_menu_command_room.png'; X = 11; Y = 32; W = 574; H = 275; Alpha = $false },
    @{ Source = $sheetTwo; Relative = 'backgrounds\lobby_command_room.png'; X = 604; Y = 32; W = 516; H = 276; Alpha = $false },
    @{ Source = $sheetTwo; Relative = 'backgrounds\menu_dark_overlay.png'; X = 1136; Y = 32; W = 389; H = 276; Alpha = $false },
    @{ Source = $sheetTwo; Relative = 'branding\atlas_front_wordmark.png'; X = 11; Y = 345; W = 499; H = 153; Alpha = $true },
    @{ Source = $sheetTwo; Relative = 'branding\atlas_front_mark.png'; X = 523; Y = 345; W = 268; H = 153; Alpha = $true },
    @{ Source = $sheetTwo; Relative = 'decor\command_corner.png'; X = 808; Y = 372; W = 145; H = 112; Alpha = $true },
    @{ Source = $sheetTwo; Relative = 'decor\separator_glow.png'; X = 1000; Y = 420; W = 255; H = 70; Alpha = $true },
    @{ Source = $sheetTwo; Relative = 'decor\scanline_overlay.png'; X = 1264; Y = 347; W = 262; H = 148; Alpha = $true },
    @{ Source = $sheetOne; Relative = 'decor\holographic_grid.png'; X = 1262; Y = 43; W = 258; H = 112; Alpha = $true },
    @{ Source = $sheetOne; Relative = 'decor\panel_corner.png'; X = 1035; Y = 650; W = 100; H = 82; Alpha = $true },
    @{ Source = $sheetOne; Relative = 'decor\panel_bar.png'; X = 1148; Y = 650; W = 155; H = 82; Alpha = $true },
    @{ Source = $sheetOne; Relative = 'decor\panel_circle.png'; X = 1315; Y = 646; W = 105; H = 95; Alpha = $true },
    @{ Source = $sheetOne; Relative = 'decor\tech_pattern.png'; X = 1417; Y = 648; W = 112; H = 95; Alpha = $true },
    @{ Source = $sheetTwo; Relative = 'game\world_underlay.png'; X = 983; Y = 538; W = 289; H = 207; Alpha = $true },
    @{ Source = $sheetTwo; Relative = 'game\ocean_grid.png'; X = 1286; Y = 538; W = 240; H = 207; Alpha = $false },
    @{ Source = $sheetTwo; Relative = 'states\reconnect_backdrop.png'; X = 11; Y = 787; W = 466; H = 214; Alpha = $false },
    @{ Source = $sheetTwo; Relative = 'states\victory_backdrop.png'; X = 493; Y = 787; W = 426; H = 214; Alpha = $false },
    @{ Source = $sheetOne; Relative = 'misc\target_marker.png'; X = 972; Y = 868; W = 64; H = 63; Alpha = $true; Cyan = $true },
    @{ Source = $sheetOne; Relative = 'misc\hex_frame.png'; X = 1100; Y = 865; W = 60; H = 66; Alpha = $true; Cyan = $true },
    @{ Source = $sheetOne; Relative = 'misc\dot.png'; X = 1224; Y = 881; W = 35; H = 35; Alpha = $true; Cyan = $true },
    @{ Source = $sheetOne; Relative = 'misc\vline.png'; X = 1335; Y = 858; W = 18; H = 84; Alpha = $true; Cyan = $true },
    @{ Source = $sheetOne; Relative = 'misc\hline.png'; X = 1396; Y = 886; W = 115; H = 25; Alpha = $true; Cyan = $true }
)

$icons = @(
    @{ Name = 'create_lobby'; X = 694; Y = 391 },
    @{ Name = 'join_lobby'; X = 802; Y = 391 },
    @{ Name = 'settings'; X = 909; Y = 391 },
    @{ Name = 'quit'; X = 1017; Y = 391 },
    @{ Name = 'ready'; X = 1129; Y = 391 },
    @{ Name = 'cards'; X = 1230; Y = 391 },
    @{ Name = 'army'; X = 1333; Y = 391 },
    @{ Name = 'timer'; X = 1441; Y = 391 },
    @{ Name = 'connection'; X = 694; Y = 512 },
    @{ Name = 'spectator'; X = 802; Y = 512 },
    @{ Name = 'warning'; X = 908; Y = 512 }
)
foreach ($icon in $icons)
{
    $assets += @{ Source = $sheetOne; Relative = "icons\$($icon.Name).png"; X = $icon.X; Y = $icon.Y; W = 80; H = 80; Alpha = $true }
}

foreach ($asset in $assets)
{
    $destination = Join-Path $outputRoot $asset.Relative
    $directory = Split-Path -Parent $destination
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $cyanKey = if ($asset.ContainsKey('Cyan')) { [bool]$asset.Cyan } else { $false }
    [AtlasAssetExtractor]::Extract($asset.Source, $destination, $asset.X, $asset.Y, $asset.W, $asset.H, $asset.Alpha, $cyanKey)
}

Write-Output ("EXTRACTED_ASSETS={0}" -f $assets.Count)

# Подкраска картинки под насыщенную палитру кабинета: сочность (vibrance) и контраст.
# Сочность поднимает насыщенность блёклых цветов сильнее, чем уже ярких, поэтому кожа
# не уходит в оранжевый. Почти непрозрачная альфа (генератор отдаёт 253–254) становится 255,
# чтобы фигура не просвечивала.
#
# Пример:
#   powershell -File tools/art/boost_colors.ps1 -Source concepts/32_visitor_irena_fantasy.png `
#     -Out cases/test_day/art/visitor_irena.png

param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Out,
    # 0 — без изменений; 1 — серые цвета вдвое насыщеннее, насыщенные почти не меняются.
    [double]$Vibrance = 0.6,
    # Множитель отклонения от середины яркости: 1 — без изменений.
    [double]$Contrast = 1.1,
    # Альфа не ниже этой становится 255.
    [int]$OpaqueAlpha = 240
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class ColorBooster {
    const double Mid = 0.5;

    static double Clamp(double v) { return Math.Max(0.0, Math.Min(1.0, v)); }

    public static Bitmap Boost(Bitmap src, double vibrance, double contrast, int opaqueAlpha) {
        int w = src.Width, h = src.Height;
        var d = src.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var p = new byte[w * h * 4];
        for (int y = 0; y < h; y++) Marshal.Copy(d.Scan0 + y * d.Stride, p, y * w * 4, w * 4);
        src.UnlockBits(d);

        var c = new double[3];
        for (int i = 0; i < p.Length; i += 4) {
            if (p[i + 3] == 0) continue;
            if (p[i + 3] >= opaqueAlpha) p[i + 3] = 255;
            for (int k = 0; k < 3; k++) c[k] = p[i + k] / 255.0;
            double luma = 0.114 * c[0] + 0.587 * c[1] + 0.299 * c[2];
            double max = Math.Max(c[0], Math.Max(c[1], c[2]));
            double min = Math.Min(c[0], Math.Min(c[1], c[2]));
            double saturation = max > 0.0 ? (max - min) / max : 0.0;
            double gain = 1.0 + vibrance * (1.0 - saturation);
            for (int k = 0; k < 3; k++) {
                double v = luma + (c[k] - luma) * gain;
                v = Mid + (v - Mid) * contrast;
                p[i + k] = (byte)Math.Round(Clamp(v) * 255.0);
            }
        }

        var result = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        var r = result.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        for (int y = 0; y < h; y++) Marshal.Copy(p, y * w * 4, r.Scan0 + y * r.Stride, w * 4);
        result.UnlockBits(r);
        return result;
    }
}
"@

$src = New-Object System.Drawing.Bitmap (Resolve-Path $Source).Path
$result = [ColorBooster]::Boost($src, $Vibrance, $Contrast, $OpaqueAlpha)
$src.Dispose()
$outPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)
New-Item -ItemType Directory -Force ([System.IO.Path]::GetDirectoryName($outPath)) | Out-Null
$result.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$result.Dispose()
Write-Output $outPath

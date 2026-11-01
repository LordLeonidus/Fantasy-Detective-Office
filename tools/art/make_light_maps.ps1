# Карты света кабинета для спрайтов поверх комнаты (посетитель, предметы, тюль).
# Карта состояния — «кадр состояния ÷ дневной кадр» по каждому каналу, сильно размытая:
# насколько каждое место кадра светлее или темнее дня и какого оттенка. Значение записано
# делённым на 2 (байт 255 — вдвое светлее дня), шейдер light_map.gdshader умножает обратно.
# Кадры — то, что видно на экране целиком: небо, город и комната, сложенные вместе.
#
# Пример:
#   powershell -File tools/art/make_light_maps.ps1 -DayImage concepts/38_layered_day.png `
#     -StateImages concepts/38_layered_morning.png,concepts/38_layered_day.png,... `
#     -Names morning,day,sunset,dusk,night -OutDir office/art/light_maps

param(
    [Parameter(Mandatory = $true)][string]$DayImage,
    [Parameter(Mandatory = $true)][string[]]$StateImages,
    [Parameter(Mandatory = $true)][string[]]$Names,
    [Parameter(Mandatory = $true)][string]$OutDir,
    # Сколько клеток по ширине кадра: чем меньше, тем мягче свет и тем дальше
    # растекается свет из окна.
    [int]$Cells = 48,
    # Ширина готовой карты; высота — по пропорциям кадра. Шейдер растягивает её на сцену.
    [int]$MapWidth = 96,
    # Насколько оттенок света берётся из кадров: 0 — только яркость, 1 — отношение по каждому
    # каналу целиком. На насыщенных стенах отношение по каналам искажает оттенок (дерево
    # на фоне бирюзовой стены ночью зеленеет), поэтому оттенок приглушается.
    [double]$TintStrength = 0.5,
    # Степень для затемнения: где состояние темнее дня, яркость возводится в эту степень.
    # Нарисованные кадры затемняют предметы сильнее стен; 1 — как в кадрах, больше — глубже тень.
    [double]$ShadowDepth = 1.4
)

$ErrorActionPreference = "Stop"
if ($StateImages.Count -ne $Names.Count) { throw "Кадров и имён должно быть поровну" }

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;

public static class LightMapMaker {
    const double MapRange = 2.0;
    // Добавка к каналам, чтобы почти чёрные места дня не давали огромных отношений.
    const double Floor = 4.0;

    static byte[] Read(Bitmap b) {
        var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var a = new byte[d.Stride * b.Height];
        Marshal.Copy(d.Scan0, a, 0, a.Length);
        b.UnlockBits(d);
        return a;
    }

    static Bitmap Resize(Image src, int w, int h) {
        var r = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(r)) {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            using (var wrap = new ImageAttributes()) {
                wrap.SetWrapMode(WrapMode.TileFlipXY);
                g.DrawImage(src, new Rectangle(0, 0, w, h), 0, 0, src.Width, src.Height, GraphicsUnit.Pixel, wrap);
            }
        }
        return r;
    }

    static double Luma(byte[] p, int i) {
        return 0.114 * p[i] + 0.587 * p[i + 1] + 0.299 * p[i + 2];
    }

    public static Bitmap Make(Bitmap day, Bitmap state, int cells, int mapWidth, double tintStrength, double shadowDepth) {
        int rows = Math.Max(1, (int)Math.Round((double)cells * day.Height / day.Width));
        var a = Read(Resize(day, cells, rows));
        var s = Read(Resize(state, cells, rows));
        var ratio = new Bitmap(cells, rows, PixelFormat.Format32bppArgb);
        var q = new byte[a.Length];
        var channel = new double[3];
        for (int i = 0; i < a.Length; i += 4) {
            // Яркость — отношение яркостей; оттенок — отношение по каналам, приведённое
            // к единичной яркости и приглушённое к белому.
            double brightness = (Luma(s, i) + Floor) / (Luma(a, i) + Floor);
            if (brightness < 1.0) brightness = Math.Pow(brightness, shadowDepth);
            for (int c = 0; c < 3; c++) channel[c] = (s[i + c] + Floor) / (a[i + c] + Floor);
            double channelLuma = 0.114 * channel[0] + 0.587 * channel[1] + 0.299 * channel[2];
            for (int c = 0; c < 3; c++) {
                double tint = 1.0 + tintStrength * (channel[c] / channelLuma - 1.0);
                double r = brightness * tint;
                q[i + c] = (byte)Math.Round(Math.Max(0.0, Math.Min(MapRange, r)) / MapRange * 255.0);
            }
            q[i + 3] = 255;
        }
        var d = ratio.LockBits(new Rectangle(0, 0, cells, rows), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(q, 0, d.Scan0, q.Length);
        ratio.UnlockBits(d);
        int mapHeight = Math.Max(1, (int)Math.Round((double)mapWidth * day.Height / day.Width));
        return Resize(ratio, mapWidth, mapHeight);
    }
}
"@

$OutDir = (New-Item -ItemType Directory -Force $OutDir).FullName
$day = New-Object System.Drawing.Bitmap (Resolve-Path $DayImage).Path
for ($i = 0; $i -lt $StateImages.Count; $i++) {
    $state = New-Object System.Drawing.Bitmap (Resolve-Path $StateImages[$i]).Path
    $map = [LightMapMaker]::Make($day, $state, $Cells, $MapWidth, $TintStrength, $ShadowDepth)
    $out = Join-Path $OutDir ("light_map_{0}.png" -f $Names[$i])
    $map.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $map.Dispose()
    $state.Dispose()
    Write-Output $out
}
$day.Dispose()

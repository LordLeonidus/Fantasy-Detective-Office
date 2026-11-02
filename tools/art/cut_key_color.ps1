# Чистая вырезка слоя по цветовому ключу (пурпурный 255,0,255) без цветной каймы по краям.
#
# Режим ключа (по умолчанию) — из исходника генератора, где стёкла или небо залиты ключом:
# - прозрачными становятся только сплошные области ключа (цвет близок к ключу, область не мельче
#   MinKeyArea). Ключевой свет на предметах (пурпурный закат на подоконнике) не трогается;
# - полоса шириной EdgeWidth вокруг них — смесь ключа и соседнего цвета: доля непрозрачности
#   считается по ближайшему непрозрачному пикселю, цвет берётся у него. Если пиксель не похож
#   на такую смесь (свой оттенок), он остаётся непрозрачным.
# -Despill — убрать пурпурный отлив со всей картинки (так сделана оболочка комнаты; карты света
# посчитаны по этим цветам). Доля прозрачности считается по исходным цветам, до этой правки.
# Режим -KeepAlpha — у готовой вырезки прозрачность остаётся как есть, а цвет полупрозрачных
# и прозрачных пикселей берётся у ближайшего непрозрачного соседа.
#
# Примеры:
#   powershell -File tools/art/cut_key_color.ps1 -Source concepts/37_shell_dusk.png -Out office/art/room/office_room_dusk.png -Despill
#   powershell -File tools/art/cut_key_color.ps1 -Source office/art/city/office_city_day.png -Out office/art/city/office_city_day.png -KeepAlpha

param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Out,
    [switch]$KeepAlpha,
    [switch]$Despill,
    # Насколько цвет может отличаться от ключа (расстояние в RGB), чтобы считаться ключом.
    [double]$KeyTolerance = 40,
    # Меньшие области ключа не вырезаются: это блики, а не стекло или небо.
    [int]$MinKeyArea = 64,
    # Ширина полосы смешанных пикселей вокруг ключа.
    [int]$EdgeWidth = 2,
    # Пиксель полосы дальше этого от ключа — свой цвет, непрозрачный.
    [double]$OpaqueDistance = 200,
    # Насколько пиксель полосы может отличаться от смеси «ключ + сосед», чтобы считаться смесью.
    [double]$MixTolerance = 40
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class KeyCutter {
    const double KeyR = 255.0, KeyG = 0.0, KeyB = 255.0;
    static readonly int[] Dx = { -1, 0, 1, -1, 1, -1, 0, 1 };
    static readonly int[] Dy = { -1, -1, -1, 0, 0, 1, 1, 1 };

    static byte[] Read(Bitmap b) {
        var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var a = new byte[b.Width * b.Height * 4];
        for (int y = 0; y < b.Height; y++) Marshal.Copy(d.Scan0 + y * d.Stride, a, y * b.Width * 4, b.Width * 4);
        b.UnlockBits(d);
        return a;
    }

    static Bitmap Write(byte[] a, int w, int h) {
        var b = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        for (int y = 0; y < h; y++) Marshal.Copy(a, y * w * 4, d.Scan0 + y * d.Stride, w * 4);
        b.UnlockBits(d);
        return b;
    }

    static double KeyDistance(byte[] p, int i) {
        double r = p[i + 2] - KeyR, g = p[i + 1] - KeyG, b = p[i] - KeyB;
        return Math.Sqrt(r * r + g * g + b * b);
    }

    // Для каждого пикселя — индекс ближайшего (по шагам в 8 сторон) пикселя, где opaque[i].
    static int[] NearestOpaque(bool[] opaque, int w, int h) {
        var nearest = new int[w * h];
        var queue = new Queue<int>();
        for (int i = 0; i < nearest.Length; i++) {
            nearest[i] = opaque[i] ? i : -1;
            if (opaque[i]) queue.Enqueue(i);
        }
        while (queue.Count > 0) {
            int i = queue.Dequeue();
            int x = i % w, y = i / w;
            for (int k = 0; k < 8; k++) {
                int nx = x + Dx[k], ny = y + Dy[k];
                if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                int n = ny * w + nx;
                if (nearest[n] >= 0) continue;
                nearest[n] = nearest[i];
                queue.Enqueue(n);
            }
        }
        return nearest;
    }

    // Пиксели ключа, собранные в связные области не мельче minArea.
    static bool[] KeyAreas(byte[] p, int w, int h, double tolerance, int minArea) {
        var near = new bool[w * h];
        for (int i = 0; i < near.Length; i++) near[i] = KeyDistance(p, i * 4) < tolerance;
        var key = new bool[w * h];
        var seen = new bool[w * h];
        var area = new List<int>();
        var stack = new Stack<int>();
        for (int s = 0; s < near.Length; s++) {
            if (!near[s] || seen[s]) continue;
            area.Clear();
            stack.Push(s);
            seen[s] = true;
            while (stack.Count > 0) {
                int i = stack.Pop();
                area.Add(i);
                int x = i % w, y = i / w;
                for (int k = 0; k < 8; k++) {
                    int nx = x + Dx[k], ny = y + Dy[k];
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    int n = ny * w + nx;
                    if (!near[n] || seen[n]) continue;
                    seen[n] = true;
                    stack.Push(n);
                }
            }
            if (area.Count >= minArea) foreach (int i in area) key[i] = true;
        }
        return key;
    }

    // Расстояние в шагах от ключа, не дальше limit; дальше — int.MaxValue.
    static int[] StepsFromKey(bool[] key, int w, int h, int limit) {
        var steps = new int[w * h];
        var queue = new Queue<int>();
        for (int i = 0; i < steps.Length; i++) {
            steps[i] = key[i] ? 0 : int.MaxValue;
            if (key[i]) queue.Enqueue(i);
        }
        while (queue.Count > 0) {
            int i = queue.Dequeue();
            if (steps[i] >= limit) continue;
            int x = i % w, y = i / w;
            for (int k = 0; k < 8; k++) {
                int nx = x + Dx[k], ny = y + Dy[k];
                if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                int n = ny * w + nx;
                if (steps[n] != int.MaxValue) continue;
                steps[n] = steps[i] + 1;
                queue.Enqueue(n);
            }
        }
        return steps;
    }

    static void CopyColor(byte[] p, int to, int from) {
        p[to * 4] = p[from * 4];
        p[to * 4 + 1] = p[from * 4 + 1];
        p[to * 4 + 2] = p[from * 4 + 2];
    }

    // Убрать пурпурный отлив: R и B уменьшаются на то, на сколько оба выше G.
    static void Despill(byte[] p) {
        for (int i = 0; i < p.Length; i += 4) {
            int spill = Math.Min(p[i], p[i + 2]) - p[i + 1];
            if (spill <= 0) continue;
            p[i] = (byte)(p[i] - spill);
            p[i + 2] = (byte)(p[i + 2] - spill);
        }
    }

    public static Bitmap CutKey(Bitmap src, double tolerance, int minArea, int edgeWidth, double opaqueDistance, double mixTolerance, bool despill) {
        int w = src.Width, h = src.Height;
        var p = Read(src);
        var key = KeyAreas(p, w, h, tolerance, minArea);
        var steps = StepsFromKey(key, w, h, edgeWidth);
        var opaque = new bool[w * h];
        for (int i = 0; i < opaque.Length; i++) {
            bool edge = !key[i] && steps[i] <= edgeWidth;
            opaque[i] = !key[i] && (!edge || KeyDistance(p, i * 4) > opaqueDistance);
        }
        var nearest = NearestOpaque(opaque, w, h);
        var result = (byte[])p.Clone();
        if (despill) Despill(result);
        for (int i = 0; i < opaque.Length; i++) {
            if (opaque[i]) { result[i * 4 + 3] = 255; continue; }
            int n = nearest[i];
            if (n < 0) { result[i * 4 + 3] = 0; continue; }
            if (key[i]) { CopyColor(result, i, n); result[i * 4 + 3] = 0; continue; }
            // Пиксель полосы — смесь ключа K и соседа C: P = K + a (C - K).
            double cr = p[n * 4 + 2] - KeyR, cg = p[n * 4 + 1] - KeyG, cb = p[n * 4] - KeyB;
            double pr = p[i * 4 + 2] - KeyR, pg = p[i * 4 + 1] - KeyG, pb = p[i * 4] - KeyB;
            double len2 = cr * cr + cg * cg + cb * cb;
            double alpha = len2 > 0.0 ? Math.Max(0.0, Math.Min(1.0, (pr * cr + pg * cg + pb * cb) / len2)) : 1.0;
            double er = pr - alpha * cr, eg = pg - alpha * cg, eb = pb - alpha * cb;
            if (Math.Sqrt(er * er + eg * eg + eb * eb) > mixTolerance) { result[i * 4 + 3] = 255; continue; }
            CopyColor(result, i, n);
            result[i * 4 + 3] = (byte)Math.Round(alpha * 255.0);
        }
        return Write(result, w, h);
    }

    public static Bitmap FixEdges(Bitmap src) {
        int w = src.Width, h = src.Height;
        var p = Read(src);
        var opaque = new bool[w * h];
        for (int i = 0; i < opaque.Length; i++) opaque[i] = p[i * 4 + 3] == 255;
        var nearest = NearestOpaque(opaque, w, h);
        for (int i = 0; i < opaque.Length; i++) {
            if (!opaque[i] && nearest[i] >= 0) CopyColor(p, i, nearest[i]);
        }
        return Write(p, w, h);
    }
}
"@

$src = New-Object System.Drawing.Bitmap (Resolve-Path $Source).Path
if ($KeepAlpha) {
    $result = [KeyCutter]::FixEdges($src)
} else {
    $result = [KeyCutter]::CutKey($src, $KeyTolerance, $MinKeyArea, $EdgeWidth, $OpaqueDistance, $MixTolerance, $Despill.IsPresent)
}
# Исходник закрыт до записи: так можно перезаписать файл на месте.
$src.Dispose()
$outPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)
New-Item -ItemType Directory -Force ([System.IO.Path]::GetDirectoryName($outPath)) | Out-Null
$result.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$result.Dispose()
Write-Output $outPath

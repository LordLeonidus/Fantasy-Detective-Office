# Извлекает горящие окна домов за окном кабинета в отдельный слой.
# Сравнивает кадр с огнями и тот же кадр с тёмными окнами (совпадают до пикселя),
# находит каждое горящее окно отдельно и пишет две текстуры размером с кадр:
#   window_lights_color.png — цвет огней, альфа — маска;
#   window_lights_id.png    — номер окна (1..254) в красном канале, 0 — не окно.
# Порядок включения окон считает шейдер по номеру окна, поэтому номера здесь не случайны.
#
# Пример:
#   powershell -File tools/art/extract_window_lights.ps1 -LitImage concepts/19_office_night.png `
#     -DarkImage concepts/20_office_night_dark.png -OutDir office/art/window_lights

param(
    [Parameter(Mandatory = $true)][string]$LitImage,
    [Parameter(Mandatory = $true)][string]$DarkImage,
    [Parameter(Mandatory = $true)][string]$OutDir,
    # Область поиска (окно кабинета), пиксели исходного кадра.
    [int]$RegionLeft = 0,
    [int]$RegionTop = 0,
    [int]$RegionRight = 260,
    [int]$RegionBottom = 650,
    # Разница яркости, с которой пиксель начинает считаться огнём, и с которой он огонь полностью.
    # Значения по умолчанию подобраны на 19_office_night / 20_office_night_dark (64 окна).
    [int]$DiffStart = 10,
    [int]$DiffFull = 40,
    # Насколько огонь должен быть теплее (R - B), чтобы не ловить шум перерисовки.
    [int]$MinWarmth = 4,
    # На сколько пикселей расширить маску, чтобы куски одного окна слились в одно.
    # Больше 1 — соседние окна сливаются и загораются вместе.
    [int]$GrowRadius = 1
)

$ErrorActionPreference = "Stop"

$code = @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class WindowLightsExtractor
{
    static int[] ReadPixels(Bitmap bmp)
    {
        var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
        var data = bmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var pixels = new int[bmp.Width * bmp.Height];
        Marshal.Copy(data.Scan0, pixels, 0, pixels.Length);
        bmp.UnlockBits(data);
        return pixels;
    }

    static void WritePixels(Bitmap bmp, int[] pixels)
    {
        var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
        var data = bmp.LockBits(rect, ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(pixels, 0, data.Scan0, pixels.Length);
        bmp.UnlockBits(data);
    }

    static float Luma(int argb)
    {
        int r = (argb >> 16) & 255, g = (argb >> 8) & 255, b = argb & 255;
        return 0.299f * r + 0.587f * g + 0.114f * b;
    }

    public static int Extract(string litPath, string darkPath, string colorOut, string idOut,
        int left, int top, int right, int bottom,
        int diffStart, int diffFull, int minWarmth, int growRadius)
    {
        var lit = new Bitmap(litPath);
        var dark = new Bitmap(darkPath);
        if (lit.Width != dark.Width || lit.Height != dark.Height)
            throw new Exception("Размеры кадров не совпадают");
        int w = lit.Width, h = lit.Height;
        int[] litPx = ReadPixels(lit), darkPx = ReadPixels(dark);
        right = Math.Min(right, w); bottom = Math.Min(bottom, h);

        // Мягкая маска огня и её твёрдое ядро.
        var mask = new float[w * h];
        var core = new bool[w * h];
        for (int y = top; y < bottom; y++)
            for (int x = left; x < right; x++)
            {
                int i = y * w + x;
                int p = litPx[i];
                int warmth = ((p >> 16) & 255) - (p & 255);
                float diff = Luma(p) - Luma(darkPx[i]);
                if (warmth < minWarmth) continue;
                float m = (diff - diffStart) / (float)(diffFull - diffStart);
                m = Math.Max(0f, Math.Min(1f, m));
                mask[i] = m;
                core[i] = m > 0.3f;
            }

        // Расширение ядра, чтобы куски одного окна слились.
        var grown = new bool[w * h];
        for (int y = top; y < bottom; y++)
            for (int x = left; x < right; x++)
            {
                if (!core[y * w + x]) continue;
                for (int dy = -growRadius; dy <= growRadius; dy++)
                    for (int dx = -growRadius; dx <= growRadius; dx++)
                    {
                        int nx = x + dx, ny = y + dy;
                        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                        grown[ny * w + nx] = true;
                    }
            }

        // Связные области — отдельные окна.
        var label = new int[w * h];
        int count = 0;
        var stack = new Stack<int>();
        for (int i = 0; i < w * h; i++)
        {
            if (!grown[i] || label[i] != 0) continue;
            count++;
            int id = 1 + (count - 1) % 254;
            label[i] = id;
            stack.Push(i);
            while (stack.Count > 0)
            {
                int c = stack.Pop();
                int cx = c % w, cy = c / w;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++)
                    {
                        int nx = cx + dx, ny = cy + dy;
                        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                        int n = ny * w + nx;
                        if (grown[n] && label[n] == 0) { label[n] = id; stack.Push(n); }
                    }
            }
        }

        var colorPx = new int[w * h];
        var idPx = new int[w * h];
        for (int i = 0; i < w * h; i++)
        {
            int id = label[i];
            idPx[i] = unchecked((int)0xFF000000) | (id << 16) | (id << 8) | id;
            if (id == 0) continue;
            int alpha = (int)Math.Round(mask[i] * 255f);
            colorPx[i] = (alpha << 24) | (litPx[i] & 0x00FFFFFF);
        }

        var colorBmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        WritePixels(colorBmp, colorPx);
        colorBmp.Save(colorOut, ImageFormat.Png);
        var idBmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        WritePixels(idBmp, idPx);
        idBmp.Save(idOut, ImageFormat.Png);
        lit.Dispose(); dark.Dispose(); colorBmp.Dispose(); idBmp.Dispose();
        return count;
    }
}
"@

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition $code

New-Item -ItemType Directory -Force $OutDir | Out-Null
$lit = (Resolve-Path $LitImage).Path
$dark = (Resolve-Path $DarkImage).Path
$out = (Resolve-Path $OutDir).Path
$count = [WindowLightsExtractor]::Extract($lit, $dark,
    (Join-Path $out "window_lights_color.png"), (Join-Path $out "window_lights_id.png"),
    $RegionLeft, $RegionTop, $RegionRight, $RegionBottom,
    $DiffStart, $DiffFull, $MinWarmth, $GrowRadius)
Write-Output "Найдено окон: $count"

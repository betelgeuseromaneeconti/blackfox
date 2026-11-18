#Requires -Version 5.1
<#
.SYNOPSIS
Generates all BLACKFOX monochrome Kitsune icons and logos across Windows, Android, Android TV, Linux, macOS, and Web Dashboard.
Concept:
- Main Logo / Icon: A mysterious young male character with long flowing dark hair framing the face, wearing a traditional Japanese Kitsune fox mask, with restrained Victorian Gothic framing, rendered strictly in black, white, and grayscale.
- Small Tray / Status Icons: High-contrast monochrome Kitsune fox mask silhouette with monochrome state indicators (bright white dot for connected, hollow/gray dot for idle/asleep, exclamation badge for error, 4-stage corner/ear highlights while connecting).
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Root = Split-Path -Parent $PSScriptRoot
$AppDir = Join-Path $Root 'app'
$CoreDir = Join-Path $Root 'core'
$ResDir = Join-Path $AppDir 'android\app\src\main\res'

function New-PointF([float]$x, [float]$y, [float]$scale) {
    return [System.Drawing.PointF]::new($x * $scale, $y * $scale)
}

function Draw-BlackFoxCharacter([System.Drawing.Graphics]$g, [int]$size, [bool]$includeFrame = $true) {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $s = $size / 1000.0

    # Brushes & Pens (Strictly Monochrome: Black, White, Charcoal, Silver, Gray)
    $bPureBlack   = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 8, 8, 10))
    $bCharcoal    = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 22, 22, 26))
    $bDarkGray    = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 42, 42, 48))
    $bMidGray     = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 110, 110, 118))
    $bSilver      = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 195, 195, 202))
    $bBoneWhite   = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 244, 244, 246))
    $bPureWhite   = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 255, 255))

    $pThinSilver  = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(140, 220, 220, 225), [Math]::Max(1.0, 4.0 * $s))
    $pHairLight   = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(170, 165, 165, 175), [Math]::Max(1.0, 5.5 * $s))
    $pMaskLine    = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 28, 28, 32), [Math]::Max(1.2, 7.0 * $s))
    $pMaskDetail  = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 75, 75, 82), [Math]::Max(1.0, 5.0 * $s))

    $pad = [int](40 * $s)
    $body = $size - 2 * $pad
    $inPad = [int](64 * $s)
    $inBody = $size - 2 * $inPad
    if ($includeFrame) {
        # Victorian Gothic dark medallion background
        $g.FillEllipse($bPureBlack, $pad, $pad, $body, $body)
        $clipPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $clipPath.AddEllipse($pad, $pad, $body, $body)
        $g.SetClip($clipPath)
    }

    # 1. Shoulders / High Victorian Gothic Collar silhouette
    $collar = @(
        (New-PointF 210 920 $s),
        (New-PointF 270 760 $s),
        (New-PointF 370 710 $s),
        (New-PointF 500 790 $s),
        (New-PointF 630 710 $s),
        (New-PointF 730 760 $s),
        (New-PointF 790 920 $s)
    )
    $g.FillPolygon($bCharcoal, $collar)
    $g.DrawPolygon($pThinSilver, $collar)

    # 2. Long dark hair back volume falling naturally around the face and shoulders
    $hairBack = @(
        (New-PointF 500 160 $s),
        (New-PointF 330 200 $s),
        (New-PointF 235 350 $s),
        (New-PointF 195 560 $s),
        (New-PointF 180 780 $s),
        (New-PointF 240 890 $s),
        (New-PointF 310 830 $s),
        (New-PointF 350 910 $s),
        (New-PointF 500 860 $s),
        (New-PointF 650 910 $s),
        (New-PointF 690 830 $s),
        (New-PointF 760 890 $s),
        (New-PointF 820 780 $s),
        (New-PointF 805 560 $s),
        (New-PointF 765 350 $s),
        (New-PointF 670 200 $s)
    )
    $g.FillPolygon($bPureBlack, $hairBack)

    # 3. Masculine Lower Face / Jaw / Neck (visible slightly beneath the Kitsune mask chin)
    $jaw = @(
        (New-PointF 395 620 $s),
        (New-PointF 425 715 $s),
        (New-PointF 500 755 $s),
        (New-PointF 575 715 $s),
        (New-PointF 605 620 $s)
    )
    $g.FillPolygon($bMidGray, $jaw)
    $g.DrawLines($pThinSilver, $jaw)

    # 4. Traditional Japanese Kitsune Fox Mask
    # Left Fox Ear (Outer)
    $earLeft = @(
        (New-PointF 295 335 $s),
        (New-PointF 240 105 $s),
        (New-PointF 420 235 $s)
    )
    # Right Fox Ear (Outer)
    $earRight = @(
        (New-PointF 705 335 $s),
        (New-PointF 760 105 $s),
        (New-PointF 580 235 $s)
    )
    $g.FillPolygon($bBoneWhite, $earLeft)
    $g.FillPolygon($bBoneWhite, $earRight)
    $g.DrawPolygon($pMaskLine, $earLeft)
    $g.DrawPolygon($pMaskLine, $earRight)

    # Inner Fox Ear Shadows (Charcoal/Dark Gray)
    $earLeftIn = @(
        (New-PointF 312 310 $s),
        (New-PointF 272 152 $s),
        (New-PointF 395 245 $s)
    )
    $earRightIn = @(
        (New-PointF 688 310 $s),
        (New-PointF 728 152 $s),
        (New-PointF 605 245 $s)
    )
    $g.FillPolygon($bDarkGray, $earLeftIn)
    $g.FillPolygon($bDarkGray, $earRightIn)

    # Kitsune Mask Faceplate (Angular cheekbones, tapered fox muzzle)
    $maskFace = @(
        (New-PointF 500 210 $s),
        (New-PointF 390 235 $s),
        (New-PointF 290 330 $s),
        (New-PointF 270 465 $s),
        (New-PointF 335 585 $s),
        (New-PointF 440 675 $s),
        (New-PointF 500 715 $s),
        (New-PointF 560 675 $s),
        (New-PointF 665 585 $s),
        (New-PointF 730 465 $s),
        (New-PointF 710 330 $s),
        (New-PointF 610 235 $s)
    )
    $g.FillPolygon($bBoneWhite, $maskFace)

    # Subtle grayscale shading on right half of mask for 3D sculptural depth
    $maskShadow = @(
        (New-PointF 500 210 $s),
        (New-PointF 500 715 $s),
        (New-PointF 560 675 $s),
        (New-PointF 665 585 $s),
        (New-PointF 730 465 $s),
        (New-PointF 710 330 $s),
        (New-PointF 610 235 $s)
    )
    $g.FillPolygon($bSilver, $maskShadow)
    $g.DrawPolygon($pMaskLine, $maskFace)

    # Kitsune Forehead Diamond / Crescent Mark (Monochrome Charcoal)
    $foreheadMark = @(
        (New-PointF 500 255 $s),
        (New-PointF 522 315 $s),
        (New-PointF 500 375 $s),
        (New-PointF 478 315 $s)
    )
    $g.FillPolygon($bPureBlack, $foreheadMark)

    # Kitsune Nose Bridge & Muzzle Tip
    $g.DrawLine($pMaskDetail, (New-PointF 500 385 $s), (New-PointF 500 595 $s))
    $noseTip = @(
        (New-PointF 462 595 $s),
        (New-PointF 538 595 $s),
        (New-PointF 500 645 $s)
    )
    $g.FillPolygon($bPureBlack, $noseTip)

    # Kitsune Whisker / Cheek Markings (Monochrome)
    $g.DrawLine($pMaskDetail, (New-PointF 310 500 $s), (New-PointF 415 540 $s))
    $g.DrawLine($pMaskDetail, (New-PointF 330 545 $s), (New-PointF 425 575 $s))
    $g.DrawLine($pMaskDetail, (New-PointF 690 500 $s), (New-PointF 585 540 $s))
    $g.DrawLine($pMaskDetail, (New-PointF 670 545 $s), (New-PointF 575 575 $s))

    # Fierce Upturned Kitsune Slit Eyes
    $eyeLeft = @(
        (New-PointF 325 415 $s),
        (New-PointF 385 395 $s),
        (New-PointF 455 445 $s),
        (New-PointF 375 450 $s)
    )
    $eyeRight = @(
        (New-PointF 675 415 $s),
        (New-PointF 615 395 $s),
        (New-PointF 545 445 $s),
        (New-PointF 625 450 $s)
    )
    $g.FillPolygon($bPureBlack, $eyeLeft)
    $g.FillPolygon($bPureBlack, $eyeRight)

    # Mysterious white iris glint inside the dark eye slits
    $g.FillEllipse($bPureWhite, [float](382 * $s), [float](418 * $s), [float](18 * $s), [float](18 * $s))
    $g.FillEllipse($bPureWhite, [float](600 * $s), [float](418 * $s), [float](18 * $s), [float](18 * $s))

    # 5. Natural Long Dark Hair Strands Falling Across Forehead & Sides of the Mask
    $strandLeft1 = @(
        (New-PointF 390 215 $s),
        (New-PointF 320 340 $s),
        (New-PointF 275 540 $s),
        (New-PointF 245 780 $s),
        (New-PointF 295 660 $s),
        (New-PointF 345 410 $s)
    )
    $strandLeft2 = @(
        (New-PointF 455 205 $s),
        (New-PointF 415 320 $s),
        (New-PointF 395 415 $s),
        (New-PointF 440 315 $s)
    )
    $strandRight1 = @(
        (New-PointF 610 215 $s),
        (New-PointF 680 340 $s),
        (New-PointF 725 540 $s),
        (New-PointF 755 780 $s),
        (New-PointF 705 660 $s),
        (New-PointF 655 410 $s)
    )
    $strandRight2 = @(
        (New-PointF 545 205 $s),
        (New-PointF 585 320 $s),
        (New-PointF 605 415 $s),
        (New-PointF 560 315 $s)
    )
    $g.FillPolygon($bPureBlack, $strandLeft1)
    $g.FillPolygon($bPureBlack, $strandLeft2)
    $g.FillPolygon($bPureBlack, $strandRight1)
    $g.FillPolygon($bPureBlack, $strandRight2)

    # Subtle silver hair strand highlights
    $g.DrawLine($pHairLight, (New-PointF 355 260 $s), (New-PointF 275 610 $s))
    $g.DrawLine($pHairLight, (New-PointF 645 260 $s), (New-PointF 725 610 $s))
    $g.DrawLine($pHairLight, (New-PointF 255 390 $s), (New-PointF 220 740 $s))
    $g.DrawLine($pHairLight, (New-PointF 745 390 $s), (New-PointF 780 740 $s))

    if ($includeFrame) {
        $g.ResetClip()
        $pOuterRing = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(200, 235, 235, 240), [Math]::Max(1.5, 6.0 * $s))
        $pInnerRing = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(85, 200, 200, 210), [Math]::Max(1.0, 3.0 * $s))
        $g.DrawEllipse($pOuterRing, $pad, $pad, $body, $body)
        $g.DrawEllipse($pInnerRing, $inPad, $inPad, $inBody, $inBody)

        # Victorian Gothic cardinal diamond ornaments on frame
        foreach ($pt in @(@(500, 40), @(500, 960), @(40, 500), @(960, 500))) {
            $cx = $pt[0]; $cy = $pt[1]
            $d = @(
                (New-PointF $cx ($cy - 18) $s),
                (New-PointF ($cx + 12) $cy $s),
                (New-PointF $cx ($cy + 18) $s),
                (New-PointF ($cx - 12) $cy $s)
            )
            $g.FillPolygon($bBoneWhite, $d)
        }
    }
}

function Draw-TrayKitsune([int]$size, [string]$state = 'off', [int]$busyFrame = 0) {
    $bmp = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $s = $size / 100.0
    $tileBg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 18, 18, 22))
    $tileBorder = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(180, 220, 220, 225), [Math]::Max(1.0, 4.0 * $s))
    $g.FillEllipse($tileBg, [float](4 * $s), [float](4 * $s), [float](92 * $s), [float](92 * $s))
    $g.DrawEllipse($tileBorder, [float](4 * $s), [float](4 * $s), [float](92 * $s), [float](92 * $s))

    # Kitsune silhouette brightness depends on state (all monochrome)
    $alpha = if ($state -eq 'off') { 150 } elseif ($state -match 'idle|asleep') { 195 } else { 255 }
    $maskBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb($alpha, 250, 250, 252))
    $eyeBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 14, 14, 18))

    # Bold Kitsune silhouette readable down to 16x16
    $foxPoly = @(
        (New-PointF 24 16 $s),
        (New-PointF 40 30 $s),
        (New-PointF 60 30 $s),
        (New-PointF 76 16 $s),
        (New-PointF 78 48 $s),
        (New-PointF 68 68 $s),
        (New-PointF 50 84 $s),
        (New-PointF 32 68 $s),
        (New-PointF 22 48 $s)
    )
    $g.FillPolygon($maskBrush, $foxPoly)

    # Slit eyes
    $eyeL = @((New-PointF 29 48 $s), (New-PointF 44 53 $s), (New-PointF 33 56 $s))
    $eyeR = @((New-PointF 71 48 $s), (New-PointF 56 53 $s), (New-PointF 67 56 $s))
    $g.FillPolygon($eyeBrush, $eyeL)
    $g.FillPolygon($eyeBrush, $eyeR)

    # Monochrome Status Badge in bottom-right corner
    if ($busyFrame -gt 0) {
        $arcPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 255, 255, 255), [Math]::Max(1.5, 7.0 * $s))
        $startAngle = ($busyFrame - 1) * 90 - 90
        $g.DrawArc($arcPen, [float](6 * $s), [float](6 * $s), [float](88 * $s), [float](88 * $s), $startAngle, 90)
    } elseif ($state -in @('on', 'running', 'set')) {
        $bgDot = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 14, 14, 18))
        $fgDot = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
        $g.FillEllipse($bgDot, [float](62 * $s), [float](62 * $s), [float](32 * $s), [float](32 * $s))
        $g.FillEllipse($fgDot, [float](67 * $s), [float](67 * $s), [float](22 * $s), [float](22 * $s))
    } elseif ($state -in @('idle', 'running-asleep', 'set-asleep', 'waiting')) {
        $bgDot = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 14, 14, 18))
        $ringPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(230, 200, 200, 208), [Math]::Max(1.5, 5.0 * $s))
        $g.FillEllipse($bgDot, [float](62 * $s), [float](62 * $s), [float](32 * $s), [float](32 * $s))
        $g.DrawEllipse($ringPen, [float](67 * $s), [float](67 * $s), [float](22 * $s), [float](22 * $s))
    } elseif ($state -eq 'error') {
        $bgDot = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
        $fgMark = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 10, 10, 12))
        $g.FillEllipse($bgDot, [float](60 * $s), [float](60 * $s), [float](34 * $s), [float](34 * $s))
        $g.FillRectangle($fgMark, [float](74 * $s), [float](66 * $s), [float](6 * $s), [float](13 * $s))
        $g.FillRectangle($fgMark, [float](74 * $s), [float](82 * $s), [float](6 * $s), [float](5 * $s))
    }

    $g.Dispose()
    return $bmp
}

function New-MasterBitmap([int]$size, [bool]$includeFrame = $true, [bool]$opaqueBlack = $false) {
    $bmp = [System.Drawing.Bitmap]::new($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    if ($opaqueBlack) {
        $g.Clear([System.Drawing.Color]::FromArgb(255, 8, 8, 10))
    } else {
        $g.Clear([System.Drawing.Color]::Transparent)
    }
    Draw-BlackFoxCharacter -g $g -size $size -includeFrame $includeFrame
    $g.Dispose()
    return $bmp
}

function Save-MultiSizeIco([string]$path, [System.Drawing.Bitmap[]]$bitmaps) {
    $ms = [System.IO.MemoryStream]::new()
    $bw = [System.IO.BinaryWriter]::new($ms)

    $count = $bitmaps.Count
    # ICONDIR header
    $bw.Write([uint16]0)      # Reserved
    $bw.Write([uint16]1)      # Type: 1 = ICO
    $bw.Write([uint16]$count) # Image count

    $pngBuffers = New-Object byte[][] $count
    for ($i = 0; $i -lt $count; $i++) {
        $pms = [System.IO.MemoryStream]::new()
        $bitmaps[$i].Save($pms, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngBuffers[$i] = $pms.ToArray()
        $pms.Dispose()
    }

    $offset = 6 + (16 * $count)
    for ($i = 0; $i -lt $count; $i++) {
        $w = $bitmaps[$i].Width
        $h = $bitmaps[$i].Height
        $bw.Write([byte]$(if ($w -ge 256) { 0 } else { $w }))
        $bw.Write([byte]$(if ($h -ge 256) { 0 } else { $h }))
        $bw.Write([byte]0)     # Color palette
        $bw.Write([byte]0)     # Reserved
        $bw.Write([uint16]1)   # Color planes
        $bw.Write([uint16]32)  # Bits per pixel
        $bw.Write([uint32]$pngBuffers[$i].Length)
        $bw.Write([uint32]$offset)
        $offset += $pngBuffers[$i].Length
    }

    for ($i = 0; $i -lt $count; $i++) {
        $bw.Write($pngBuffers[$i])
    }

    $bw.Flush()
    $dir = Split-Path -Parent $path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [System.IO.File]::WriteAllBytes($path, $ms.ToArray())
    $bw.Dispose()
    $ms.Dispose()
}

# 1. Generate Main Application Logos & Desktop Icons
$winSizes = @(16, 20, 24, 32, 40, 48, 64, 128, 256)
$winBitmaps = foreach ($sz in $winSizes) {
    if ($sz -le 24) {
        Draw-TrayKitsune -size $sz -state 'off'
    } else {
        New-MasterBitmap -size $sz -includeFrame $true
    }
}
Save-MultiSizeIco -path (Join-Path $AppDir 'windows\runner\resources\app_icon.ico') -bitmaps $winBitmaps
Save-MultiSizeIco -path (Join-Path $CoreDir 'internal\desktop\appicon.ico') -bitmaps $winBitmaps
foreach ($b in $winBitmaps) { $b.Dispose() }

# Save PNG logos
$logo512 = New-MasterBitmap -size 512 -includeFrame $true
$logo512.Save((Join-Path $Root 'docs\images\logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$logo512.Dispose()

$logo256 = New-MasterBitmap -size 256 -includeFrame $true
$logo256.Save((Join-Path $AppDir 'assets\logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$logo256.Save((Join-Path $AppDir 'linux\runner\resources\app_icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$logo256.Dispose()

$logo192 = New-MasterBitmap -size 192 -includeFrame $true
$logo192.Save((Join-Path $CoreDir 'internal\service\web\icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$logo192.Dispose()

# macOS icons
$macFolder = Join-Path $AppDir 'macos\Runner\Assets.xcassets\AppIcon.appiconset'
if (Test-Path $macFolder) {
    foreach ($sz in @(16, 32, 64, 128, 256, 512, 1024)) {
        $mb = New-MasterBitmap -size $sz -includeFrame $true
        $mb.Save((Join-Path $macFolder "app_icon_$sz.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        $mb.Dispose()
    }
}

# 2. Android Launcher & Adaptive Icons
$densities = @{ 'mdpi' = 1.0; 'hdpi' = 1.5; 'xhdpi' = 2.0; 'xxhdpi' = 3.0; 'xxxhdpi' = 4.0 }
foreach ($entry in $densities.GetEnumerator()) {
    $dpi = $entry.Key
    $k = $entry.Value
    $folder = Join-Path $ResDir "mipmap-$dpi"
    New-Item -ItemType Directory -Force $folder | Out-Null

    $pxAdaptive = [int][Math]::Round(108 * $k)
    $fg = [System.Drawing.Bitmap]::new($pxAdaptive, $pxAdaptive, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gFg = [System.Drawing.Graphics]::FromImage($fg)
    $gFg.Clear([System.Drawing.Color]::Transparent)
    $innerSz = [int][Math]::Round($pxAdaptive * 0.66)
    $innerBmp = New-MasterBitmap -size $innerSz -includeFrame $false
    $offset = ($pxAdaptive - $innerSz) / 2
    $gFg.DrawImage($innerBmp, $offset, $offset, $innerSz, $innerSz)
    $gFg.Dispose()
    $innerBmp.Dispose()
    $fg.Save((Join-Path $folder 'ic_launcher_foreground.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $fg.Dispose()

    $bg = [System.Drawing.Bitmap]::new($pxAdaptive, $pxAdaptive, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gBg = [System.Drawing.Graphics]::FromImage($bg)
    $gBg.Clear([System.Drawing.Color]::FromArgb(255, 8, 8, 10))
    $gBg.Dispose()
    $bg.Save((Join-Path $folder 'ic_launcher_background.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $bg.Dispose()

    $pxLauncher = [int][Math]::Round(48 * $k)
    $launcher = New-MasterBitmap -size $pxLauncher -includeFrame $true
    $launcher.Save((Join-Path $folder 'ic_launcher.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $launcher.Dispose()
}

# 3. Android TV Banner (320x180 monochrome Victorian Gothic banner)
$tvBanner = [System.Drawing.Bitmap]::new(320, 180, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gTv = [System.Drawing.Graphics]::FromImage($tvBanner)
$gTv.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gTv.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$gTv.Clear([System.Drawing.Color]::FromArgb(255, 10, 10, 13))
$borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(90, 255, 255, 255), 1.5)
$gTv.DrawRectangle($borderPen, 6, 6, 308, 168)
$tvIcon = New-MasterBitmap -size 104 -includeFrame $true
$gTv.DrawImage($tvIcon, 18, 38, 104, 104)
$tvIcon.Dispose()
$fontTitle = [System.Drawing.Font]::new('Georgia', 18, [System.Drawing.FontStyle]::Bold)
$fontSub   = [System.Drawing.Font]::new('Segoe UI', 8.5, [System.Drawing.FontStyle]::Regular)
$gTv.DrawString('BLACKFOX', $fontTitle, [System.Drawing.Brushes]::White, 132, 64)
$gTv.DrawString('VICTORIAN GOTHIC VPN', $fontSub, [System.Drawing.Brushes]::Silver, 134, 98)
$fontTitle.Dispose()
$fontSub.Dispose()
$gTv.Dispose()
$tvFolder = Join-Path $ResDir 'drawable-xhdpi'
New-Item -ItemType Directory -Force $tvFolder | Out-Null
$tvBanner.Save((Join-Path $tvFolder 'banner.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$tvBanner.Dispose()

# 4. System Tray Icons (App & Core)
$traySizes = @(16, 20, 24, 32, 48, 64)
$appTrayDir = Join-Path $AppDir 'assets\tray'
New-Item -ItemType Directory -Force $appTrayDir | Out-Null
Get-ChildItem $appTrayDir -File -ErrorAction SilentlyContinue | Remove-Item -Force

$appTrayStates = @('off', 'on', 'idle', 'error', 'busy1', 'busy2', 'busy3', 'busy4')
foreach ($st in $appTrayStates) {
    $frame = if ($st -match '^busy(\d)$') { [int]$Matches[1] } else { 0 }
    $bitmaps = foreach ($sz in $traySizes) {
        Draw-TrayKitsune -size $sz -state $st -busyFrame $frame
    }
    Save-MultiSizeIco -path (Join-Path $appTrayDir "$st.ico") -bitmaps $bitmaps
    $png64 = Draw-TrayKitsune -size 64 -state $st -busyFrame $frame
    $png64.Save((Join-Path $appTrayDir "$st.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $png64.Dispose()
    foreach ($b in $bitmaps) { $b.Dispose() }
}

$coreTrayDir = Join-Path $CoreDir 'internal\desktop\tray'
New-Item -ItemType Directory -Force $coreTrayDir | Out-Null
$coreTrayStates = @('running', 'set', 'running-asleep', 'set-asleep', 'waiting', 'error', 'off')
foreach ($st in $coreTrayStates) {
    $frame = if ($st -eq 'waiting') { 1 } else { 0 }
    $bitmaps = foreach ($sz in $traySizes) {
        Draw-TrayKitsune -size $sz -state $st -busyFrame $frame
    }
    Save-MultiSizeIco -path (Join-Path $coreTrayDir "$st.ico") -bitmaps $bitmaps
    $png32 = Draw-TrayKitsune -size 32 -state $st -busyFrame $frame
    $png32.Save((Join-Path $coreTrayDir "$st.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $png32.Dispose()
    foreach ($b in $bitmaps) { $b.Dispose() }
}

Write-Host "Successfully generated all BLACKFOX monochrome Kitsune icons and logos."

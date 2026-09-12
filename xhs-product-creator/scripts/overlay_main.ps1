# overlay_main.ps1
# 在主图模板上叠加可编辑字段（自动调字号 + 一行显示）。
# 适用场景：用户的成品主图模板，需替换关键词位置（已用 Photoshop 把原字变成同色块覆盖）。
#
# 用法:
#   powershell -File overlay_main.ps1 -Template "卜诗上岸喵" -OutPath "C:\out\main.jpg" -Fields @{KEYWORD="新关键词"} -Format JPG -Quality 92
#
# 模板配置: ../assets/main-template/template-config.json
param(
  [Parameter(Mandatory=$true)][string]$Template,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [hashtable]$Fields = @{},
  [ValidateSet("PNG","JPG","WEBP")][string]$Format = "JPG",
  [ValidateRange(1,100)][int]$Quality = 92,
  [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

# 加载配置
if (-not $ConfigPath) {
  $ConfigPath = Join-Path $PSScriptRoot "..\assets\main-template\template-config.json"
}
$config = Get-Content -Raw -Encoding UTF8 $ConfigPath | ConvertFrom-Json

# alias map (use base64 to avoid bash encoding issues)
$b1 = [Convert]::FromBase64String("5Y2c6K+X5LiK5bK45Za1")  # 卜诗上岸喵
$b2 = [Convert]::FromBase64String("5Y2c6K+X6LWE5pCt5rC4")  # 卜诗资料库
$e1 = New-Object System.Text.UTF8Encoding $false
$e2 = New-Object System.Text.UTF8Encoding $false
$t1Name = $e1.GetString($b1)
$t2Name = $e2.GetString($b2)
$aliasMap = @{
  "shop1" = $t1Name
  "shop2" = $t2Name
}
if ($aliasMap.ContainsKey($Template)) {
  $Template = $aliasMap[$Template]
}

# 找模板
$tpl = $config.templates | Where-Object { $_.name -eq $Template -or $_.id -eq $Template } | Select-Object -First 1
if (-not $tpl) {
  Write-Error "未找到模板: $Template。可用模板: $($config.templates.name -join ', ')"
}

# 模板图片绝对路径
$tplImgPath = Join-Path $PSScriptRoot "..\assets\main-template\$($tpl.file)"
if (-not (Test-Path $tplImgPath)) {
  Write-Error "模板图片不存在: $tplImgPath"
}

# 加载模板
$baseImg = [System.Drawing.Image]::FromFile($tplImgPath)
$bmp = New-Object System.Drawing.Bitmap $baseImg.Width, $baseImg.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$g.DrawImage($baseImg, 0, 0, $baseImg.Width, $baseImg.Height)
$baseImg.Dispose()

# 叠加可编辑字段（自动调字号）
foreach ($f in $tpl.editable_fields) {
  $key = $f.name
  Write-Host ("[DBG] Field: " + $key) -ForegroundColor Magenta
  if (-not $Fields.ContainsKey($key)) {
    if ($f.required) {
      Write-Warning "模板 $Template 缺少必填字段: $key ($($f.label))"
    }
    continue
  }
  $value = [string]$Fields[$key]
  Write-Host ("[DBG] Value length: " + $value.Length + ", bytes: " + (($e1.GetBytes($value) | ForEach-Object { $_.ToString("X2") }) -join " ")) -ForegroundColor Magenta

  # 坐标直接用 actual 像素（配置即实际坐标）
  $realX = [int]$f.x
  $realY = [int]$f.y
  $realMaxWidth = if ($f.max_width) { [int]$f.max_width } else { [int]($bmp.Width - $realX - 20) }
  $realMaxFontSize = [int]$f.font_size
  $realMinFontSize = if ($f.min_font_size) { [int]$f.min_font_size } else { [int]20 }

  # 颜色
  $colorHex = $f.color.TrimStart('#')
  $r = [Convert]::ToInt32($colorHex.Substring(0,2), 16)
  $gg = [Convert]::ToInt32($colorHex.Substring(2,2), 16)
  $b = [Convert]::ToInt32($colorHex.Substring(4,2), 16)
  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($r, $gg, $b))

  # 字体族与粗细
  $fontFamily = if ($f.font_family) { $f.font_family } else { "Microsoft YaHei" }
  $fontStyle = if ($f.font_weight -eq "bold") { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }

  # 自动调字号：测量宽度，确保 ≤ realMaxWidth
  $fontSize = $realMaxFontSize
  $font = $null
  $textWidth = 0
  while ($fontSize -ge $realMinFontSize) {
    if ($font) { $font.Dispose() }
    $font = New-Object System.Drawing.Font $fontFamily, $fontSize, $fontStyle
    $measured = $g.MeasureString($value, $font)
    $textWidth = [int]$measured.Width
    if ($textWidth -le $realMaxWidth) { break }
    $fontSize -= 2
  }
  if (-not $font) {
    $font = New-Object System.Drawing.Font $fontFamily, $realMinFontSize, $fontStyle
    $textWidth = [int]($g.MeasureString($value, $font).Width)
  }

  # 水平对齐方式（默认 left，可选 center/right）
  $align = if ($f.align) { $f.align } else { "left" }
  $drawX = $realX
  if ($align -eq "center") {
    $drawX = $realX + [int](($realMaxWidth - $textWidth) / 2)
  } elseif ($align -eq "right") {
    $drawX = $realX + ($realMaxWidth - $textWidth)
  }

  Write-Host ("[DBG] before DrawString: drawX=" + $drawX + " realY=" + $realY + " fontSize=" + $fontSize + " brush=" + ($brush.GetType().FullName)) -ForegroundColor Magenta
  $g.DrawString($value, $font, $brush, $drawX, $realY)

    $dbgFontSize = $fontSize
    $dbgValueLen = $value.Length
    Write-Host ("  OK {0} 字号={1}px 宽={2}px (max {3}px)" -f $key, $dbgFontSize, $textWidth, $realMaxWidth) -ForegroundColor Cyan

  $font.Dispose()
  $brush.Dispose()
}

# 输出
$outDir = Split-Path $OutPath -Parent
if ($outDir -and -not (Test-Path $outDir)) {
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

switch ($Format) {
  "PNG"  { $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png) }
  "JPG"  {
    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" } | Select-Object -First 1
    $encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
    $qualityParam = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [int64]$Quality)
    $encParams.Param[0] = $qualityParam
    $bmp.Save($OutPath, $jpegCodec, $encParams)
  }
  "WEBP" {
    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Warning "System.Drawing 不支持 WEBP，已输出为 PNG"
  }
}

$g.Dispose()
$bmp.Dispose()

Write-Host ""
Write-Host "✅ 主图生成完成: $OutPath ($($tpl.name) · $Format · $($bmp.Width)×$($bmp.Height))" -ForegroundColor Green
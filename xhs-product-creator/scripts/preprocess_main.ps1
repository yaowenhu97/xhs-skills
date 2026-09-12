# preprocess_main.ps1
# 自动预处理主图模板：用同色矩形块覆盖"可编辑区域"的原字。
# 之后 overlay_main.ps1 就能在该位置叠加新关键词，不会有两层文字。
#
# 用法:
#   powershell -File preprocess_main.ps1 -Template "卜诗上岸喵" -BackupDir "C:\backup"
#
# ⚠️ 注意：覆盖后的图直接覆盖原文件！建议先用 -BackupDir 备份。
param(
  [Parameter(Mandatory=$true)][string]$Template,
  [string]$ConfigPath = "",
  [string]$BackupDir = ""
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
  Write-Error "未找到模板: $Template"
}

$tplImgPath = Join-Path $PSScriptRoot "..\assets\main-template\$($tpl.file)"
if (-not (Test-Path $tplImgPath)) {
  Write-Error "模板图片不存在: $tplImgPath"
}

# 备份
if ($BackupDir) {
  if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
  }
  $backupPath = Join-Path $BackupDir $tpl.file
  Copy-Item $tplImgPath $backupPath -Force
  Write-Host "📦 已备份原图到: $backupPath" -ForegroundColor Yellow
}

# 加载原图
$img = [System.Drawing.Image]::FromFile($tplImgPath)
$bmp = New-Object System.Drawing.Bitmap $img.Width, $img.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.DrawImage($img, 0, 0, $img.Width, $img.Height)
$img.Dispose()

# 逐个覆盖可编辑区域（坐标直接用 actual 像素）
foreach ($f in $tpl.editable_fields) {
  $realX = [int]$f.x
  $realY = [int]$f.y
  $realMaxW = if ($f.max_width) { [int]$f.max_width } else { [int]($bmp.Width - $realX - 20) }

  # 覆盖高度：优先用配置，否则按 font_size * 1.2
  $coverH = if ($f.cover_height) {
    [int]$f.cover_height
  } else {
    [int]([int]$f.font_size * 1.2)
  }

  # 颜色（优先用 preprocess_color，其次用 color）
  $coverColorHex = if ($f.preprocess_color) {
    $f.preprocess_color
  } else {
    $f.color
  }
  $colorHex = $coverColorHex.TrimStart('#')
  $r = [Convert]::ToInt32($colorHex.Substring(0,2), 16)
  $gg = [Convert]::ToInt32($colorHex.Substring(2,2), 16)
  $bb = [Convert]::ToInt32($colorHex.Substring(4,2), 16)
  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($r, $gg, $bb))

  # 用同色矩形覆盖
  $g.FillRectangle($brush, $realX, $realY, $realMaxW, $coverH)

  $brush.Dispose()

  Write-Host ("  🎨 覆盖区域 {0}: x={1}, y={2}, w={3}, h={4} (颜色 #{5})" -f $f.name, $realX, $realY, $realMaxW, $coverH, $colorHex) -ForegroundColor Cyan
}

# 保存覆盖后的图（按原格式）
$ext = [System.IO.Path]::GetExtension($tplImgPath).TrimStart('.')
switch ($ext.ToLower()) {
  "png"  { $bmp.Save($tplImgPath, [System.Drawing.Imaging.ImageFormat]::Png) }
  "jpg"  { $bmp.Save($tplImgPath, [System.Drawing.Imaging.ImageFormat]::Jpeg) }
  "jpeg" { $bmp.Save($tplImgPath, [System.Drawing.Imaging.ImageFormat]::Jpeg) }
  default { $bmp.Save($tplImgPath, [System.Drawing.Imaging.ImageFormat]::Png) }
}

$g.Dispose()
$bmp.Dispose()

Write-Host ""
Write-Host "✅ 模板已预处理: $tplImgPath" -ForegroundColor Green
Write-Host "💡 现在可用 overlay_main.ps1 在该位置叠加新关键词" -ForegroundColor Yellow
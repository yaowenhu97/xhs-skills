# render_image.ps1
# 用 Chrome headless 把"小红书笔记 HTML"按 ?p=1..N 截成多张 1080x1440 竖版图片。
# 支持 PNG / JPG / WEBP 三种输出格式。
#
# 用法:
#   powershell -File render_image.ps1 -HtmlDir "C:\path\to\html" [-OutDir "C:\path\out"] [-Format JPG] [-JpgQuality 92] [-Chrome "C:\...\chrome.exe"]
#
# 参数:
#   -HtmlDir     HTML 文件所在目录（必填）
#   -OutDir      输出目录，默认与 HtmlDir 同级
#   -Format      PNG (默认) | JPG | WEBP
#   -JpgQuality  JPG 质量 1-100，默认 92（仅 JPG 生效）
#   -Chrome      Chrome 路径，默认 "C:\Program Files\Google\Chrome\Application\chrome.exe"
#
# 示例（详情图全部 JPG）:
#   powershell -File render_image.ps1 -HtmlDir "C:\notes\html" -OutDir "C:\notes\jpg" -Format JPG
param(
  [Parameter(Mandatory=$true)][string]$HtmlDir,
  [string]$OutDir = "",
  [ValidateSet("PNG","JPG","WEBP")][string]$Format = "PNG",
  [ValidateRange(1,100)][int]$JpgQuality = 92,
  [string]$Chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
)

$ErrorActionPreference = "Stop"

if (-not $OutDir) { $OutDir = $HtmlDir }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# 临时目录（纯 ASCII，规避 file:// 中文路径问题）
$tmp = Join-Path $env:TEMP ("xhs_img_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

# 扩展名映射
$extMap = @{ PNG = "png"; JPG = "jpg"; WEBP = "webp" }
$ext = $extMap[$Format]

try {
  Get-ChildItem $HtmlDir -Filter "*.html" | ForEach-Object {
    $base = $_.BaseName
    $tmpHtml = Join-Path $tmp "$base.html"
    Copy-Item $_.FullName $tmpHtml -Force
    $content = Get-Content $tmpHtml -Raw -Encoding UTF8
    $pages = ([regex]::Matches($content, '<section class="page')).Count
    Write-Host ("=== {0} : {1} pages [{2}] ===" -f $base, $pages, $Format)
    for ($i = 0; $i -lt $pages; $i++) {
      $pageNum = $i + 1
      $imgOut = Join-Path $OutDir ("{0}_p{1}.{2}" -f $base, $pageNum, $ext)
      $tmpOut = Join-Path $tmp ("page_{0}.{1}" -f $pageNum, $ext)
      $uri = ("file:///{0}/{1}?p={2}" -f ($tmp -replace '\\','/'), ($base + ".html"), $pageNum)

      # Chrome 先输出到 tmp（避免中文路径问题），再 copy 到目标
      try {
        $chromeOutput = & $Chrome --headless=new --disable-gpu --no-sandbox --window-size=1080,1440 `
          --hide-scrollbars --default-background-color=FFFFFFFF `
          --screenshot=$tmpOut $uri 2>$null
        $LASTEXITCODE = 0
      } catch {
        Write-Warning ("Chrome 截图失败: " + $_.Exception.Message)
      }

      # 如果不是 PNG 且 Chrome 不会直接输出对应格式，则用 .NET 转码
      if ($Format -ne "PNG") {
        if (-not (Test-Path $tmpOut)) {
          # Chrome 没产出目标格式（如部分 Chrome 不支持 webp）→ 先截 PNG 再转
          $tmpPng = Join-Path $tmp ("page_{0}.png" -f $pageNum)
          try {
            & $Chrome --headless=new --disable-gpu --no-sandbox --window-size=1080,1440 `
              --hide-scrollbars --default-background-color=FFFFFFFF `
              --screenshot=$tmpPng $uri 2>$null
            $LASTEXITCODE = 0
          } catch {
            Write-Warning ("Chrome PNG 截图失败: " + $_.Exception.Message)
          }
          Add-Type -AssemblyName System.Drawing
          $img = [System.Drawing.Image]::FromFile($tmpPng)
          $codec = $null
          $params = [System.Drawing.Imaging.EncoderParameters]::new(1)
          if ($Format -eq "JPG") {
            $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
              Where-Object { $_.MimeType -eq "image/jpeg" }
            $param = [System.Drawing.Imaging.EncoderParameter]::new(
              [System.Drawing.Imaging.Encoder]::Quality, [int64]$JpgQuality)
            $params.Param[0] = $param
          } elseif ($Format -eq "WEBP") {
            # .NET 原生不支持 webp，降级输出 PNG 再提示用户
            Copy-Item $tmpPng $imgOut -Force
            Write-Warning "System.Drawing 不支持 WEBP 编码，已降级为 PNG"
            $img.Dispose()
            continue
          }
          $img.Save($imgOut, $codec, $params)
          $img.Dispose()
          Remove-Item $tmpPng -Force -ErrorAction SilentlyContinue
        } else {
          Copy-Item $tmpOut $imgOut -Force
        }
      } else {
        Copy-Item $tmpOut $imgOut -Force
      }

      $size = if (Test-Path $imgOut) { (Get-Item $imgOut).Length } else { 0 }
      Write-Host ("  {0}_p{1}.{2}  {3} bytes" -f $base, $pageNum, $ext, $size)
    }
  }
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Done. 输出格式: $Format · 输出目录: $OutDir" -ForegroundColor Green

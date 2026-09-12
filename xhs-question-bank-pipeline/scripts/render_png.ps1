# render_png.ps1
# 用 Chrome headless 把"小红书笔记 HTML"按 ?p=1..N 截成多张 1080x1440 竖版 PNG。
# 用法:
#   powershell -File render_png.ps1 -HtmlDir "C:\path\to\html文件" [-OutDir "C:\path\PNG"] [-Chrome "C:\Program Files\Google\Chrome\Application\chrome.exe"]
param(
  [Parameter(Mandatory=$true)][string]$HtmlDir,
  [string]$OutDir = "",
  [string]$Chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
)

$ErrorActionPreference = "Stop"

if (-not $OutDir) { $OutDir = $HtmlDir }  # 默认输出到同级
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# 临时目录（纯 ASCII，规避 file:// 中文路径问题）
$tmp = Join-Path $env:TEMP ("xhs_png_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

try {
  Get-ChildItem $HtmlDir -Filter "*.html" | ForEach-Object {
    $base = $_.BaseName
    $tmpHtml = Join-Path $tmp "$base.html"
    Copy-Item $_.FullName $tmpHtml -Force
    $content = Get-Content $tmpHtml -Raw -Encoding UTF8
    $pages = ([regex]::Matches($content, '<section class="page')).Count
    Write-Host ("=== {0} : {1} pages ===" -f $base, $pages)
    for ($i = 0; $i -lt $pages; $i++) {
      $pageNum = $i + 1
      $pngOut = Join-Path $OutDir ("{0}_p{1}.png" -f $base, $pageNum)
      $uri = ("file:///{0}/{1}?p={2}" -f ($tmp -replace '\\','/'), ($base + ".html"), $pageNum)
      & $Chrome --headless=new --disable-gpu --no-sandbox --window-size=1080,1440 `
        --hide-scrollbars --default-background-color=00000000 `
        --screenshot=$pngOut $uri 2>$null | Out-Null
      Write-Host ("  {0}_p{1}.png  {2} bytes" -f $base, $pageNum, (Get-Item $pngOut).Length)
    }
  }
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

Write-Host "Done. PNG 输出目录: $OutDir"

# package_zip.ps1
# 按 8.24.zip 规范打包商品数据包
param(
  [Parameter(Mandatory=$true)][string]$ItemsDir,
  [string]$OutZip = "",
  [int]$Batch = 1,
  [string]$TemplateVersion = "千川投流素材",
  [string]$ExcelTemplate = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression

# 决定输出 zip 路径
if (-not $OutZip) {
  $today = Get-Date -Format "yyyyMMdd"
  $desktop = [Environment]::GetFolderPath("Desktop")
  $OutZip = Join-Path $desktop ($today + ".zip")
}

# 创建临时打包目录
$tempDir = Join-Path $env:TEMP ("xhs_zip_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

try {
  $stamp = Get-Date -Format "yyyyMMdd"
  $rootName = [string]::Format("商品数据包_小红书{0}_{1}_第{2}批", $TemplateVersion, $stamp, $Batch)

  # 在临时目录下创建根目录包裹层
  $packRoot = Join-Path $tempDir $rootName
  New-Item -ItemType Directory -Force -Path $packRoot | Out-Null

  # 复制 Excel 模板
  if ($ExcelTemplate -and (Test-Path $ExcelTemplate)) {
    $excelName = "Excel版本商品模板.xlsx"
    Copy-Item $ExcelTemplate (Join-Path $packRoot $excelName) -Force
  }

  # 生成 README.md（完全用 string.Format 和数组拼接，避开 here-string 解析问题）
  $genTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $itemCountDir = (Get-ChildItem -Path $ItemsDir -Directory).Count

  # 单引号 here-string 但禁用中文外的所有变量
  $RT = @'
{0}
商品数据包说明

## 包信息
- 生成时间：{1}
- 模板版本：{2}
- 商品数量：{3}
- 包格式：千川投流素材

## 目录结构
```
{4}/
+-- Excel版本商品模板.xlsx          (千川商品上传模板)
+-- README.md                       (本说明)
+-- 自动生成记录.txt                (生成日志)
+-- {{单位名}}/
    +-- 商品图片/1.jpg               (主图-封面)
    +-- 小红书商品主图/1.jpg         (主图备用1)
    +-- 小红书商品主图/2.jpg         (主图备用2)
    +-- {{科目1}}/1.jpg                (详情图)
    +-- {{科目2}}/1.jpg
    +-- {{科目3}}/1.jpg
    +-- {{科目4}}/1.jpg
```

## 使用说明
1. 每个商品一个文件夹，文件夹名为商品单位名
2. 主图在「商品图片/」和「小红书商品主图/」目录下
3. 详情图按资料科目分类放在对应文件夹
4. 配合 Excel版本商品模板.xlsx 上传到千川
'@
  # 这里 RT 是个奇怪的变量名避免与变量冲突
  $readmeContent = [string]::Format($RT, "#", $genTime, $TemplateVersion, $itemCountDir, $rootName)
  [System.IO.File]::WriteAllText((Join-Path $packRoot "README.md"), $readmeContent, [System.Text.Encoding]::UTF8)

  # 生成 自动生成记录.txt
  $logGenTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logItemCount = (Get-ChildItem -Path $ItemsDir -Directory).Count

  $logLines = @()
  $logLines += "生成时间：" + $logGenTime
  $logLines += "模板版本：" + $TemplateVersion
  $logLines += "商品数量：" + $logItemCount
  $logLines += ""
  $logLines += "=== 商品列表 ==="

  # 复制商品目录
  $itemCount = 0
  foreach ($itemDir in (Get-ChildItem -Path $ItemsDir -Directory)) {
    $itemName = $itemDir.Name
    $destDir = Join-Path $packRoot $itemName
    Copy-Item -Recurse -Force $itemDir.FullName $destDir

    # 统计文件数
    $fileCount = (Get-ChildItem -Path $destDir -Recurse -File).Count
    $idx = $itemCount + 1
    $logLines += "[" + $idx + "] " + $itemName + " - " + $fileCount + " 个文件"
    $itemCount++
  }

  $logLines += ""
  $logLines += "=== 生成完成 ==="
  $logContent = ($logLines -join "`r`n")
  [System.IO.File]::WriteAllText((Join-Path $packRoot "自动生成记录.txt"), $logContent, [System.Text.Encoding]::UTF8)

  # 打包成 ZIP（让 $packRoot 本身作为 zip 内的根目录包裹层）
  if (Test-Path $OutZip) { Remove-Item $OutZip -Force }
  # 用 .NET ZipFile API 手动打包，可以包含根目录
  if (Test-Path $OutZip) { Remove-Item $OutZip -Force }
  $zipStream = [System.IO.File]::Create($OutZip)
  $zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
  $sourceDir = New-Object System.IO.DirectoryInfo($packRoot)
  # 添加根目录条目
  $zipArchive.CreateEntry($rootName + "/") | Out-Null
  foreach ($file in $sourceDir.GetFiles("*", [System.IO.SearchOption]::AllDirectories)) {
    $relativePath = $file.FullName.Substring($packRoot.Length + 1)
    # 使用正斜杠作为 zip 内的路径分隔符，加上根目录前缀
    $relativePath = ($rootName + "/" + $relativePath).Replace("\", "/")
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipArchive, $file.FullName, $relativePath, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
  }
  $zipArchive.Dispose()
  $zipStream.Dispose()

  Write-Host ""
  Write-Host "打包完成: $OutZip" -ForegroundColor Green
  Write-Host ("   商品数: " + $itemCount) -ForegroundColor Cyan
  $zipSize = [math]::Round((Get-Item $OutZip).Length / 1MB, 2)
  Write-Host ("   大小: " + $zipSize + " MB") -ForegroundColor Cyan

} finally {
  Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}
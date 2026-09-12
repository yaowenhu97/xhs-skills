# 小红书创作 skill 集

本仓库收录三个用于小红书内容生产与合规审查的 skill：

| 目录 | 用途 |
|---|---|
| `xhs-product-creator/` | 小红书商品笔记一站式创作助手。给一张商品图 + 基本信息，自动出 3:4 竖版爆款封面 + 5 张主图 + 3-6 张种草图 + 3-5 张详情图 + 爆款标题 + 正文文案 + 话题标签。内置小红书官方笔记/商品发布规则与扫描脚本。 |
| `xhs-question-bank-pipeline/` | 心社助手题库抓取 → 小红书笔记（HTML + PNG + 100 字文案 + 合规审查）流水线。生成竖版 3:4 笔记图（封面 + 内容页），输出合规可发布文案。 |
| `xhs-auto-package/` | 一键小红书商品包。关键词 → 抓题库目录 → 主图 → 详情图 → 规格图 → ZIP。面向千帆上架场景。 |

## 内置规则（2026-09-12 抓自官方）

- **笔记发布规范**（社区规范 + 官方广告禁用词 + 承诺保证 + 交易笔记细则）— `xhs-question-bank-pipeline/references/platform-rules.md`
- **千帆商品发布规则**（商品发布规范 + 电子资源类 + 出版物 + 滥发信息 + 质量总则）— `xhs-product-creator/references/qianfan-product-rules.md` 与 `xhs-auto-package/references/qianfan-product-rules.md`
- **薯条 + 聚光广告审核规则**（薯条服务协议 + 聚光《禁止推广目录》+ 聚光《【更新】教育行业规则》）— `xhs-question-bank-pipeline/references/shutiao-and-ad-rules.md` 与 `xhs-product-creator/references/shutiao-and-ad-rules.md`

## 快速用

以 `xhs-product-creator` 为例：

```powershell
# 单关键词
$env:KW = "黑龙江定向选调生"
python xhs-product-creator/scripts/make_package.py

# 批量
$env:KWFILE = "C:\Users\root\Desktop\关键词.txt"
$env:GROUP_NAME = "第1组"
python xhs-product-creator/scripts/make_package.py
```

发布前合规扫描：

```bash
python xhs-product-creator/scripts/platform_rule_scan.py "C:\path\to\笔记目录"
```

## 触发词

- 小红书商品、商品笔记、种草笔记、商品图、电商小红书、xhs product、千帆商品发布规则、商品合规、上架规则
- 心社助手、题库抓取、小红书笔记、考试笔记、合规审查、笔试题库、笔试备考、笔记发布规则、广告禁用词
- 商品包、一键商品、关键词做商品、自动商品包、生成商品包、详情图+主图+规格图

## 版本

- 同步日期：2026-09-12
- 三个 skill 的 `scripts/platform_rule_scan.py` 已三处同步（同一份词表，刻意复制不跨目录引用）

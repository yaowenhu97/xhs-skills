# reference · HTML 模板 + 心社助手抓取规则

> Part 1 用于生成小红书笔记 HTML，Part 2 用于抓取心社助手题库。

---

## Part 1 — 小红书笔记 HTML 模板（5 页 1080×1440 / 3:4）

### 完整 HTML 骨架

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>{考试名}·小红书笔记</title>
<style>
  @page { size: 1080px 1440px; margin: 0; }
  * { box-sizing: border-box; }
  html, body { margin:0; padding:0; font-family:"PingFang SC","Microsoft YaHei",sans-serif; color:#2b2b2b; background:{BG}; }
  .page { width:1080px; height:1440px; page-break-after:always; padding:32px; display:flex; flex-direction:column; position:relative; box-sizing:border-box; }
  .page:last-child { page-break-after:auto; }
  .meta-row { display:flex; justify-content:space-between; color:#556; font-size:16px; margin-bottom:18px; }
  .card { background:#fff; border-radius:20px; padding:32px 36px; box-shadow:0 6px 20px {SHADOW}; margin-bottom:20px; width:100%; }
  .card-h2 { font-size:32px; font-weight:800; margin:0 0 16px; color:{ACCENT}; display:flex; align-items:center; gap:10px; }
  .card-h2::before { content:""; width:7px; height:32px; background:{ACCENT}; border-radius:3px; }
  .header-tag { background:{ACCENT}; color:#fff; padding:10px 18px; border-radius:0 999px 999px 0; font-size:18px; font-weight:700; display:inline-block; margin-bottom:18px; }
  .pill { display:inline-block; background:{PILL}; color:{ACCENT}; padding:7px 15px; border-radius:8px; font-size:17px; font-weight:700; margin:0 6px 8px 0; }
  table { width:100%; border-collapse:collapse; font-size:18px; }
  table th, table td { border-bottom:1px dashed {BORDER}; padding:13px 9px; text-align:left; }
  table th { color:{ACCENT}; background:{HEAD}; }
  .group-list { padding:0; margin:0; list-style:none; }
  .group-list li { padding:15px 8px; border-bottom:1px dashed {BORDER}; font-size:19px; display:flex; align-items:center; gap:8px; }
  .group-list li::before { content:"📄"; font-size:16px; }
  .group-list li:last-child { border-bottom:none; }
  .group-title { font-size:26px; font-weight:800; color:{ACCENT}; margin:18px 0 8px; display:flex; align-items:center; gap:8px; }
  .group-title::before { content:"📁"; font-size:18px; }
  .group-count { display:inline-block; background:{PILL}; color:{ACCENT}; padding:3px 11px; border-radius:999px; font-size:15px; font-weight:700; margin-left:8px; }
  ul.checklist { padding-left:22px; line-height:1.9; font-size:19px; }
  ul.checklist li::marker { color:{ACCENT}; }
  .footer-note { margin-top:auto; text-align:center; color:#789; font-size:15px; padding-top:14px; }

  .page-cover { padding:32px; position:relative; }
  .cover { background:linear-gradient(175deg,{COV1} 0%,{COV2} 100%); color:#233; border-radius:20px; height:1376px; display:flex; flex-direction:column; justify-content:center; align-items:center; text-align:center; padding:60px 40px; box-sizing:border-box; border:1px solid {COVBORDER}; box-shadow:0 2px 12px rgba(0,0,0,.04); }
  .cover-tag { display:inline-block; background:#fff; color:{ACCENT}; border:1px solid {TAGBORDER}; padding:8px 18px; border-radius:999px; font-size:17px; font-weight:700; letter-spacing:2px; margin-bottom:10mm; }
  .cover h1 { font-size:70px; font-weight:900; margin:0 auto 5mm; line-height:1.15; color:{COVTITLE}; letter-spacing:1px; }
  .cover-divider { width:88px; height:3px; background:{ACCENT}; margin:0 auto 9mm; border-radius:2px; }
  .cover-sub { font-size:19px; color:#445; margin:0 auto 11mm; line-height:1.6; }
  .kpi-grid { display:grid; grid-template-columns:1fr 1fr; gap:8mm; width:100%; margin:8mm auto 11mm; }
  .kpi { background:#fff; border-radius:12px; padding:15mm 8mm 12mm; text-align:center; border-top:3px solid {ACCENT}; box-shadow:0 1px 4px rgba(0,0,0,.04); }
  .kpi-num { font-size:56px; font-weight:900; line-height:1; color:{ACCENT}; }
  .kpi-label { font-size:16px; color:#567; margin-top:3mm; }
  .registration { background:#fff; border-radius:14px; padding:13mm 9mm 11mm; width:100%; border:1px solid rgba(0,0,0,.05); margin-top:5mm; }
  .registration-title { font-size:14px; color:#889; letter-spacing:5px; margin-bottom:6mm; text-align:center; }
  .registration-row { display:grid; grid-template-columns:1fr auto 1fr; align-items:center; gap:5mm; max-width:80%; margin:0 auto; }
  .reg-time { text-align:center; }
  .reg-time-label { font-size:14px; color:#889; margin-bottom:3mm; }
  .reg-time-value { font-size:32px; font-weight:800; color:#233; white-space:nowrap; }
  .reg-arrow { color:{ACCENT}; font-size:28px; }
  .registration-note { font-size:17px; color:#445; margin-top:8mm; padding-top:7mm; line-height:1.9; text-align:left; border-top:1px dashed rgba(0,0,0,.08); }

  .page:not(.page-cover) { padding:36px 40px; display:flex; flex-direction:column; }
  .page:not(.page-cover) .meta-row { flex-shrink:0; }
  .page:not(.page-cover) .header-tag { flex-shrink:0; }
  .page:not(.page-cover) .card { flex:1 0 auto; display:flex; flex-direction:column; justify-content:center; }
  .page:not(.page-cover) .footer-note { margin-top:auto; flex-shrink:0; }
</style>
</head>
<body>

<!-- 第1页：封面 -->
<section class="page page-cover">
  <div class="cover">
    <div class="cover-tag">{标签}</div>
    <h1>{标题}</h1>
    <div class="cover-divider"></div>
    <div class="cover-sub">{副标题}</div>
    <div class="kpi-grid">
      <div class="kpi"><div class="kpi-num">{KPI1}</div><div class="kpi-label">{L1}</div></div>
      <div class="kpi"><div class="kpi-num">{KPI2}</div><div class="kpi-label">{L2}</div></div>
      <div class="kpi"><div class="kpi-num">{KPI3}</div><div class="kpi-label">{L3}</div></div>
      <div class="kpi"><div class="kpi-num">{KPI4}</div><div class="kpi-label">{L4}</div></div>
    </div>
    <div class="registration">
      <div class="registration-title">{报名时间段标题}</div>
      <div class="registration-row">
        <div class="reg-time"><div class="reg-time-label">{开始标签}</div><div class="reg-time-value">{开始值}</div></div>
        <div class="reg-arrow">→</div>
        <div class="reg-time"><div class="reg-time-label">{截止标签}</div><div class="reg-time-value">{截止值}</div></div>
      </div>
      <div class="registration-note">{备注1}<br>{备注2}<br>{备注3}</div>
    </div>
  </div>
</section>

<!-- 第2页：报名与条件 -->
<section class="page"> ... </section>
<!-- 第3页：笔试 -->
<section class="page"> ... </section>
<!-- 第4页：资料目录 -->
<section class="page"> ... </section>
<!-- 第5页：面试+建议 -->
<section class="page"> ... </section>

<!-- 截图 helper（必须保留在 </body> 前） -->
<script>(function(){var m=location.search.match(/[?&]p=(\d+)/);if(!m)return;var n=parseInt(m[1])-1;var ps=document.querySelectorAll('.page');ps.forEach(function(el,i){if(i!==n)el.style.setProperty('display','none','important');});})();</script>
</body>
</html>
```

### 主题色变量速查

| 变量 | 建议值 | 说明 |
|------|--------|------|
| `ACCENT` | 主色，如 `#2a5aa8`(蓝) / `#0e7a6b`(青绿) / `#a32638`(红) / `#1a7f4b`(绿) | 全局强调色 |
| `BG` | 页面底色，如 `#eef2f8` | 必须比封面浅 |
| `PILL` | 标签底色=ACCENT 浅色 | |
| `COV1/COV2` | 封面渐变两端 | |
| `COVTITLE` | 封面标题深色 | 比 ACCENT 深 |
| `SHADOW` | 卡片阴影，如 `rgba(40,80,160,.08)` | |
| `BORDER` | 表格/列表虚线色 |  |
| `HEAD` | 表头底色 |  |
| `TAGBORDER` | 标签边框 |  |
| `COVBORDER` | 封面外框 |  |

### 5 页内容模板

1. **封面**：标签 + 大标题 + 副标题 + 4 个 KPI + 报名时间段 + 3 条备注
2. **报名与条件**：时间线表（公告/报名/缴费/打印/笔试）+ 报考条件清单
3. **笔试**：科目 pill + 行测/申论/专业模块清单 + 合格线/占比
4. **资料目录**：group-title + group-list（按素材的资料模块分组），写"X 大分组 · Y 份 PDF"
5. **面试+建议**：面试形式 pill + 高频题型清单 + 备考建议 checklist + footer-note

每页底部 footer-note 写"题库编号 / 来源 / 备考核心"等。信息不足时写"以上为公告/往年整理，以官方为准"。

---

## Part 2 — 心社助手题库抓取规则

### 关键规则

- **只使用用户提供的完整关键词**，不缩写、不拆词、不去后缀
- **禁止降级搜索**：完整关键词无结果立即停下汇报，不要尝试变体
- Ctrl+K 调出全局搜索窗口 → Ctrl+V 粘贴完整关键词
- 暂停 2 秒观察搜索下拉/首页推荐卡片 → 按 Enter 确认
- **仅抓"刷题"和"资料"两个 Tab 的目录信息**
- **不下载**任何 PDF/PPTX/题目内容
- **不点击**"查看全部/预览/开始做题/下载"
- **子项 ID 若 DOM 未暴露，标 "-"**

### Markdown 输出格式

```markdown
# {题库名称} - 试卷与资料目录

---

## 基本信息
- **题库名称**：
- **题库编号**：
- **题库编码**：
- **来源省份**：
- **详情页 URL**：

---

## 试卷模块（刷题）

> {一句话统计}

### {一级分组 1 名称} [exercise-XXX]（X 题 / Y 项）

| # | 子项 ID | 子分类/试卷名称 | 题数 |
|---|--------|------------------|------|
| 1 | xxx | | | xxx |

### {一级分组 2 名称} ...

---

## 资料模块

> {一句话统计}

### {资料分组 1 名称} [material-XXX]（X 份）

| # | 资料 ID | 资料文件名 |
|---|--------|------------|
| 1 | xxx | xxx.pdf |

### {资料分组 2 名称} ...

---

- 抓取时间：2026-08-24
- 平台：心社助手（http://124.221.67.217）
- 抓取方式：Ctrl+K 搜索窗口 + 完整关键词粘贴 + Enter 确认
- 数据状态：仅抓取目录层，未进入任何最末级内容
- 登录账号：普通用户（题库处于未开通预览模式）
```

### 默认保存路径

`C:\Users\root\Desktop\笔记\素材\{题库名}.md`

### 关键词模式

- `2026年XXX公司笔试题库`
- `2027年XXX定向选调生笔试题库`
- `2026年XX区XX单位事业单位笔试题库`

### 异常处理

- 完整关键词无结果 → 立即停下汇报
- 登录失效 → 立即停下，重新登录
- 资料下架 → 末尾加 `⚠️ 抓取异常` 章节
- DOM 未暴露 ID → 填 "-"

---

## Part 3 — 端到端流水线图

```
Step 1 抓取 (可选) → Step 2 提取 → Step 3 HTML → Step 4 截图 → Step 5 文案 → Step 6 审查
   │                    │             │             │             │             │
   ↓                    ↓             ↓             ↓             ↓             ↓
题库.md ──→ 核心字段 ──→ .html ──→ .png 5张 ──→ 100字 ──→ 合规报告
（已有素材可跳过 Step 1）
```

依赖关系：Step 1 仅在用户提供关键词且未提供 .md 素材时执行；其余 5 步为标准流水线。

---

## Part 4 — 小红书禁发商品及信息合规（ID 1349）

> **全名**：《小红书禁发商品及信息管理规范》
> **生效**：2026-01-29 修订、2026-02-05 生效
> **适用范围**：小红书平台所有商家（笔记中若提及/推荐/介绍下列商品，均同样适用）
> **完整原文**：https://school.xiaohongshu.com/rule/detail/136/1349

**与笔记场景相关的快速避雷表**（21 大类中与笔记/招聘/考试场景可能交叉的高风险品类）：

| 类目 | 重点场景关键词 | 笔记处理 |
|------|---------------|----------|
| 九、医药、医疗器械、医疗服务、医美 | 在线诊疗、医美（双眼皮/热玛吉/超声刀/抽脂/胎盘素）、整形、减脂增高、偏方秘方、心理咨询、育儿课程、两性健康课程、处方药 | 不推荐/不评论；笔记仅做招聘报道、不涉及功效 |
| 十、欺诈、盗窃、作弊、骚扰他人 | 刷单、代考服务、未公开考试试卷答案、考试替考 | 笔记不提及、不提供 |
| 十二、金融 | 信用卡代刷、POS 机、虚拟货币、荐股软件、高利贷、私人贷款、套现 | 不介绍 |
| 十三、烟草 | 香烟、电子烟、草本雾化器、烟油烟弹 | 不出现 |
| 十五、交通、航空、铁路设备 | 航空器整机（飞机/直升机）、航空器配件/图纸、铁路专用设备、报废车辆五大总成、汽车安全气囊 | 笔记谈岗位招聘 OK，不能推荐产品 |
| 十七、网络游戏、账号、外挂私服 | 未经审批的游戏、点卡、外挂、私服、网盘账号 | 不提及 |
| **十八.5 小红书账号、仿冒小红书** | 小红书账号/店铺、仿小红书商品、小红书企业名录、小红书 logo/小红心/小红同款/惊喜盒子/薯条加热榜单 | **严格避雷**（与"薯条规范"§4.7 重合） |
| 十九、农药兽药 | 禁用限用农药、处方兽药、原料药 | 不提及 |
| 二十一.1 违规出版物/内部资料 | 盗印出版物、企业内部资料、党政类代写 | 不提及、不提供 |
| 二十一.2 不适宜的代办挂靠服务 | **代考（驾照/公务员考试/四六级/中高考）、代扣交通扣分、代办发票/指标/车牌、代抢火车票、代为刷医保卡、代办使馆认证** | 笔记不提及/不提供 |
| 二十一.3 不适宜线上服务 | 法律服务、法律咨询 | 笔记中如涉及需谨慎措辞 |

**面向场景的笔记避雷特别提示**：

1. 医疗/卫健委招聘笔记 → 不出现「胎盘素/热玛吉/超声刀/双眼皮/偏方/处方药/增高」等词，仅说"招聘/岗位/学历/资格"。
2. 公考/选调生/招聘考试笔记 → 不出现「代考/答案/包过/押题/密卷/阅卷老师/命题人/内部」。
3. 铁路/航空/交通招聘笔记 → 不出现「航空器整机/配件/铁路专用设备/报废车/安全气囊」等设备类词。
4. 财会类/国企类笔记 → 不出现「代办发票/指标/POS/信用卡代刷/套现」。
5. **所有笔记** → 不使用小红书 logo/小红心/小红同款/惊喜盒子/薯条加热/"小红书推荐"/"小红书安利"/仿冒小红书商品与账号。

**违规处罚梯度**（第七条）：

| 处罚对象 | 措施（从轻到重） |
|----------|----------------|
| 违规商品 | 限制发布 → 下架 → 冻结（封禁） |
| 违规店铺 | 公示警告 → 删除信息 → 冻结货款 → 延长账期 → 限制闪拍 → 关闭订单 → 限制流量/账号 → 限制参与活动 → 扣款 → 冻结店铺 |
| 严重者 | 损失赔偿 / 移交司法机关 |

**后台隐藏处罚**：以上处罚可叠加，多项同时发生时会累积扣分/账号评级。发布"代考/试题答案"类还可能上"刑事伴航"名单。

---

## Part 5 — 附加资源

- 薯条加热规范（在同环境中的 skill：`小红书薯条加热规范/SKILL.md`）提供完整的 13 个公考高危场景 + 红黄绿三级词表。本 Part 4 是「商家商品合规」层，与薯条规范互补：
  - **薯条规范** → 笔记内容、营销话术、广告导流
  - **本 Part 4（ID 1349）** → 商品/服务/类目是否可发
- 如笔记主题涉及以下类目（医美/法律/金融/赌博/烟酒/农药/铁路/航空/化妆品/医疗保健品），发布前**必须**双参：薯条规范 + ID 1349。

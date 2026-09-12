#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""一键商品包（批量+并行+跳过中转版）：
输入关键词列表 → ①并行抓目录（Chrome 9222 共享）②逐关键词渲染主图+详情图（直接写到 PROJ/{KW}/）
③复制 SKU ④三件套 ⑤打包 ZIP ⑥自动清理临时

用法（PowerShell）：
    $env:KWFILE = "关键词.txt"    # 每行一个关键词（推荐）
    或 $env:KW = "关键词1,关键词2"
    可选 $env:GROUP_NAME = "第1组"
    python .../xhs-auto-package/scripts/make_package.py
"""
import os, re, sys, subprocess, shutil, zipfile, concurrent.futures, time
from datetime import datetime
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

PY = r"C:\Users\root\AppData\Local\Programs\Python\Python312\python.exe"
SKILL = Path(r"C:\Users\root\.qoder-cn\skills\xhs-auto-package")
DIR_SKILL = Path(r"C:\Users\root\.qoder-cn\skills\xinshe-directory-render")
DESKTOP = Path(r"C:\Users\root\Desktop")

# 8.25 千帆批量上架根目录
PROJ = DESKTOP / "商品数据包_小红书千帆批量上架_20260825"

# SKU 子目录与对应规格图
SKU_SUBS = ["笔试+面试（下单后联系客服）", "笔试（下单后联系客服）", "时政包（下单后联系客服）", "面试（下单后联系客服）"]
SKU_SRCS = ["sku_bishi_mianshi.jpg", "sku_bishi.jpg", "sku_60min.jpg", "sku_mianshi.jpg"]
# 并行抓取并发数（Chrome 9222 共享）
FETCH_WORKERS = 5


def read_keywords():
    kwfile = os.environ.get("KWFILE")
    if kwfile and Path(kwfile).exists():
        kws = [s.strip() for s in Path(kwfile).read_text(encoding="utf-8-sig").splitlines() if s.strip()]
        if kws:
            return kws
    kw = os.environ.get("KW") or (sys.argv[1] if len(sys.argv) > 1 else "")
    if kw:
        parts = [s.strip() for s in kw.replace("；", ",").replace("，", ",").replace("、", ",").replace(";", ",").split(",") if s.strip()]
        if parts:
            return parts
    return ["黑龙江定向选调生"]


def _run_fetch(kw):
    """单个关键词抓取（线程安全：subprocess 独立进程，Chrome 9222 共享）。
    先去除通用前后缀，用核心词去心社助手搜索获取目录。
    当 USE_NEW_PAGE=1 时（fetch_parallel 并行模式），子进程 fetch_directory
    在已登录 context 上 new_page()，避免多 worker 抢 pages[0] 导致关键词叠加。"""
    core = strip_generic(kw)
    kenv = {**os.environ, "KW": core, "DIR_MD": str(DESKTOP / f"{core}_最终目录.md"), "USE_NEW_PAGE": "1"}
    subprocess.run([PY, str(DIR_SKILL / "scripts" / "fetch_directory.py")], env=kenv, timeout=180, capture_output=True, text=True, encoding="utf-8", errors="ignore")


def fetch_parallel(kws, max_workers=None):
    """并行抓取目录（多 worker 进程，每个 new_page 独立 tab）。
    内容多、子项多的词在并行下偶发丢子项，可用环境变量 FETCH_WORKERS=1 强制串行。"""
    import concurrent.futures
    if max_workers is None:
        try:
            max_workers = max(1, int(os.environ.get("FETCH_WORKERS", "3")))
        except ValueError:
            max_workers = 3
    print(f"[1] 抓取（ProcessPoolExecutor max_workers={max_workers}）...")
    need = [kw for kw in kws if not (DESKTOP / f"{strip_generic(kw)}_最终目录.md").exists()]
    have = [kw for kw in kws if kw not in need]
    if have:
        print(f"  [跳过已有目录] {len(have)} 个：{', '.join(have)}")
    t0 = time.time()
    with concurrent.futures.ProcessPoolExecutor(max_workers=max_workers) as ex:
        futs = {ex.submit(_run_fetch, kw): kw for kw in need}
        for f in concurrent.futures.as_completed(futs):
            kw = futs[f]
            try:
                f.result()
                print(f"  ✅ {kw}")
            except Exception as e:
                print(f"  ❌ {kw} {e}")
    print(f"  抓取阶段总耗时 {time.time()-t0:.1f}s")


GENERIC_SUFFIXES = ["招聘笔试真题库", "招聘笔试题库", "笔试真题库", "笔试题库", "考试题库", "笔试专练", "笔试题", "题库"]


def strip_generic(kw):
    """去掉通用前缀（年份）与通用后缀（笔试题库/题库等），返回商品核心名。
    例：2026年塔城书记员笔试题库 → 塔城书记员
       2027年上海定向选调生笔试题库 → 上海定向选调生
    """
    k = kw.strip()
    k = re.sub(r"^20\d{2}\s*年?", "", k)  # 去开头年份（如 2026年/2027）
    for suf in GENERIC_SUFFIXES:
        if k.endswith(suf):
            k = k[: -len(suf)]
            break
    return k.strip()


EMPTY_LIST = DESKTOP / "无数据商品清单.txt"


def is_empty_md(md_path):
    """判断目录 md 是否完全无数据（无任何 ### 小节与 - 条目）。"""
    if not md_path.exists():
        return True
    text = md_path.read_text(encoding="utf-8")
    n = sum(1 for l in text.splitlines() if l.startswith("### ") or l.startswith("- "))
    return n == 0


def record_empty(kw):
    """记录无数据关键词到清单（待去心社助手确认）。"""
    with open(EMPTY_LIST, "a", encoding="utf-8") as f:
        f.write(kw + "\n")


def build_one(kw):
    """为单个关键词：建子目录 → 合规 → 主图 → 详情图（全部直接写 PROJ/{核心词}/）。"""
    core = strip_generic(kw)
    print(f"\n===== 处理关键词：{kw}（商品名：{core}）=====")
    kenv = {**os.environ, "KW": core, "DIR_MD": str(DESKTOP / f"{core}_最终目录.md")}
    md_path = Path(kenv["DIR_MD"])
    if is_empty_md(md_path):
        print(f"    ⏭ 跳过（题库无数据）：{kw}")
        record_empty(kw)
        return False
    pdir = PROJ / core

    # 准备子目录骨架
    (pdir / "商品图片").mkdir(parents=True, exist_ok=True)
    (pdir / "电脑版商品详情图").mkdir(parents=True, exist_ok=True)
    for sub in SKU_SUBS:
        (pdir / sub).mkdir(parents=True, exist_ok=True)

    # 1.5 合规审查
    print("[1.5] 合规审查...")
    try:
        subprocess.run([PY, str(SKILL / "scripts" / "compliance_check.py")], env=kenv, timeout=30, capture_output=True, text=True, encoding="utf-8", errors="ignore")
    except Exception as e:
        print(f"  (合规失败: {e})")
    safe_md = Path(kenv["DIR_MD"]).with_name(f"{core}_最终目录_合规.md")
    if not safe_md.exists():
        # 合规审查必须通过（敏感词打码），未生成合规 md 则不出图，避免漏打码
        print(f"    ⏭ 合规审查未生成合规 md，跳过（未合规不出图）：{kw}")
        return False

    # 2. 主图 → pdir/商品图片/1.jpg（标题用核心词，跳过中转目录）
    print("[2] 主图...")
    try:
        subprocess.run([PY, str(SKILL / "scripts" / "render_main.py")],
                       env={**kenv, "KW": core, "OUT_DIR": str(pdir / "商品图片")}, timeout=60, capture_output=True, text=True, encoding="utf-8", errors="ignore")
    except Exception as e:
        print(f"  (主图失败: {e})")

    # 3. 详情图 → pdir/电脑版商品详情图/{1..N}.jpg（直接命名 1.jpg 符合千帆模板）
    print("[3] 详情图...")
    try:
        subprocess.run([PY, str(DIR_SKILL / "scripts" / "render_directory.py")],
                       env={**kenv, "OUT_DIR": str(pdir / "电脑版商品详情图"),
                            "NAME_FMT": "{idx}", "DIR_MD": str(safe_md)},
                       timeout=60, capture_output=True, text=True, encoding="utf-8", errors="ignore")
    except Exception as e:
        print(f"  (详情图失败: {e})")
    return True


def copy_skus(kws):
    """复制 SKU 图到每个商品 SKU 子目录。"""
    print("\n[3b] 复制 SKU 图...")
    for kw in kws:
        pdir = PROJ / strip_generic(kw)
        if not pdir.exists():
            continue
        for src, sub in zip(SKU_SRCS, SKU_SUBS):
            sp = SKILL / "assets" / src
            if sp.exists():
                shutil.copy(str(sp), str(pdir / sub / "1.jpg"))


def make_zip_path():
    """根据当天日期 + 桌面已有同名 ZIP 避让，生成唯一 ZIP 路径。
    格式：M.D.zip / M.D-1.zip / M.D-2.zip ...
    规则：
      - 桌面无同日期 ZIP → M.D.zip
      - 仅有 M.D.zip → M.D-1.zip
      - 已有 M.D.zip + M.D-1.zip → 取最大序号 + 1
    """
    today = datetime.now()
    base = f"{today.month}.{today.day}"  # 如 "8.26"
    max_seq = 0
    has_base = False
    for f in os.listdir(DESKTOP):
        m = re.match(rf"^{re.escape(base)}(-(\d+))?\.zip$", f)
        if not m:
            continue
        if m.group(2):
            max_seq = max(max_seq, int(m.group(2)))
        else:
            has_base = True
    if not has_base and max_seq == 0:
        return DESKTOP / f"{base}.zip"
    next_seq = max(max_seq + 1, 1 if has_base else 0)
    return DESKTOP / f"{base}-{next_seq}.zip"


def build_shared_files(kws):
    """生成共享的 Excel/ README/ 自动发货配置。"""
    print("[4] 生成共享的 Excel/README/自动发货...")
    import importlib.util
    _B = r"C:\Users\root\.codex\skills\商品制作\scripts\build.py"
    _spec = importlib.util.spec_from_file_location("goods_build", _B)
    _gb = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(_gb)
    try:
        core_kws = [strip_generic(k) for k in kws]
        _gb.build_excel(PROJ / "Excel发布商品模板.xlsx", core_kws)
        _gb.build_readme(PROJ / "README.md", f"千帆上架-批量", len(core_kws))
        _gb.build_autoship_config(PROJ / "自动发货配置.txt", f"千帆上架-批量", core_kws)
        print(f"  ✅ Excel/README/自动发货（含 {len(kws)} 个商品 × 4 SKU = {len(kws)*4} 行）")
    except Exception as e:
        print(f"  ⚠ 模板填充失败: {e}")


MAX_ZIP_MB = 50


def package(kws):
    """打包 ZIP（≤MAX_ZIP_MB，超过自动拆分为多个分卷）。
    按商品子目录大小贪心分组，每组 = 若干商品 + 该组商品的 Excel/README/自动发货，≤ MAX_ZIP_MB。"""
    print(f"[5] 打包 ZIP（≤{MAX_ZIP_MB}MB 自动拆分）...")
    limit = MAX_ZIP_MB * 1024 * 1024
    import importlib.util
    _B = r"C:\Users\root\.codex\skills\商品制作\scripts\build.py"
    _spec = importlib.util.spec_from_file_location("goods_build", _B)
    _gb = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(_gb)
    # 商品子目录及大小
    tri_sz = sum(f.stat().st_size for f in PROJ.iterdir() if f.is_file())
    prods = []
    for d in PROJ.iterdir():
        if not d.is_dir():
            continue
        sz = sum(f.stat().st_size for f in d.rglob("*") if f.is_file())
        prods.append((d.name, d, sz))
    prods.sort(key=lambda x: x[2], reverse=True)
    # 贪心分组：每组（商品 + 三件套）≤ limit
    batches = []
    cur, cur_sz = [], tri_sz
    for name, d, sz in prods:
        if cur and cur_sz + sz > limit:
            batches.append(cur)
            cur, cur_sz = [], tri_sz
        cur.append((name, d))
        cur_sz += sz
    if cur:
        batches.append(cur)
    zip_paths = []
    for batch in batches:
        core_batch = [strip_generic(name) for name, _ in batch]
        _gb.build_excel(PROJ / "Excel发布商品模板.xlsx", core_batch)
        _gb.build_readme(PROJ / "README.md", f"千帆上架-批量", len(core_batch))
        _gb.build_autoship_config(PROJ / "自动发货配置.txt", f"千帆上架-批量", core_batch)
        zp = make_zip_path()
        with zipfile.ZipFile(zp, "w", zipfile.ZIP_DEFLATED) as z:
            for f in PROJ.iterdir():
                if f.is_file():
                    z.write(f, f.name)
            for name, d in batch:
                for f in d.rglob("*"):
                    if f.is_file():
                        z.write(f, f"{name}/{f.relative_to(d)}".replace("\\", "/"))
        zip_paths.append(zp)
        print(f"  [OK] {zp.name}（{len(batch)} 商品，{zp.stat().st_size/1024/1024:.1f}MB）")
    print(f"  共 {len(batches)} 个分卷商品包，SKU 行 {len(kws)*4}")
    return zip_paths


def cleanup(kws, zip_paths):
    """打包后自动清理：每关键词的目录 md/合规 md + 源 PROJ 目录 + 日志；保留 ZIP 与 KWFILE。"""
    names = ", ".join(p.name for p in zip_paths)
    print(f"\n[6] 清理临时产物（保留 {names} + 关键词列表）...")
    removed = []
    for kw in kws:
        core = strip_generic(kw)
        for p in [
            DESKTOP / f"{core}_最终目录.md",
            DESKTOP / f"{core}_最终目录_合规.md",
        ]:
            if p.exists():
                p.unlink()
                removed.append(p.name)
    if PROJ.exists():
        shutil.rmtree(PROJ)
        removed.append(PROJ.name)
    log = DESKTOP / "_批量打包日志.txt"
    if log.exists():
        log.unlink()
        removed.append(log.name)
    print(f"    ✅ 已清理 {len(removed)} 项（仅保留 {names} 与关键词输入文件）")


def main():
    kws = read_keywords()
    print(f"=== 一键商品包（批量+并行）：共 {len(kws)} 个关键词 ===")
    # 0. 准备 PROJ
    if PROJ.exists():
        shutil.rmtree(PROJ, ignore_errors=True)
    PROJ.mkdir(parents=True)
    # 1. 并行抓取（多 worker 进程 + 独立 new_page，独立测试：3 词 275s → 25s，加速 10.82x，产物一致）
    fetch_parallel(kws)
    # 2. 逐关键词：建子目录 + 合规 + 主图 + 详情图（无数据跳过）
    valid_kws = []
    for kw in kws:
        if build_one(kw):
            valid_kws.append(kw)
    # 3. 复制 SKU 图
    copy_skus(valid_kws)
    # 4. 三件套
    build_shared_files(valid_kws)
    # 5. 打包（≤50MB 自动拆分）
    zip_paths = package(valid_kws)
    # 6. 自动清理
    cleanup(kws, zip_paths)


if __name__ == "__main__":
    main()
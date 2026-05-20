# EXAMPLES — 不假设 Dead Code

## 反例 1: "这个函数没人调,删了吧"

**Anti-pattern**:

AI 翻代码看到:
```python
def legacy_normalize_amount(x): ...
```

AI 行为(错误): 没看到本文件其他位置用,就直接 Edit 删掉。

后果: CI 失败,因为:
- `scripts/migration_v2.py` 在 import 它
- `tests/test_legacy_compat.py` 在测它
- 一个 cron job(`crontab` 里)调用 `scripts/normalize_old.py` 用到它

**Pattern (正确)**:

删前先搜:
```
$ rg -l "legacy_normalize_amount" --type=py
src/legacy.py
scripts/migration_v2.py
scripts/normalize_old.py
tests/test_legacy_compat.py

$ rg "legacy_normalize_amount" --type=py
src/legacy.py:12:def legacy_normalize_amount(x):
scripts/migration_v2.py:8:from src.legacy import legacy_normalize_amount
scripts/normalize_old.py:3:from src.legacy import legacy_normalize_amount
tests/test_legacy_compat.py:5:from src.legacy import legacy_normalize_amount
```

> 不是 dead code,有 3 个调用方 + 1 个测试。要删的话:
> (A) 同步删 4 个引用 + 测试 + 文档
> (B) 标 `@deprecated` 等下游清理
> (C) 不动
> 你倾向哪个? 我看到 cron 也在用,(A) 有线上风险。

---

## 反例 2: 新增文件忘了挂到项目清单

**Anti-pattern**:

任务: 加一个新模块 `src/auth/oauth.py`。

AI 行为(错误): 写完代码就完事。

后果:
- `__init__.py` 没 export → 外部 import 不到
- `pyproject.toml` 的 `packages` 没列 → wheel 打包丢失
- `mypy.ini` 没配置 → 类型检查跳过
- `requirements.txt` 没加新引入的 `authlib` 依赖 → 部署崩

**Pattern (正确)** 检查清单:

| 项目类型 | 新增源文件后必须同步的清单 |
|---|---|
| Python | `__init__.py` exports / `pyproject.toml` packages / `requirements.txt` 新依赖 / `mypy.ini` |
| Node/TS | `package.json` dependencies / `tsconfig.json` include / `index.ts` re-export |
| Go | `go.mod` (新依赖) / package import / `go.sum` |
| Rust | `Cargo.toml` dependencies / `lib.rs` mod / feature flags |

新增文件后,显式打勾这张表,再说"完成"。

---

## 反例 3: 多 agent 并行,各改各的,缓存打架

**Anti-pattern**:

主线程派两个 agent 并行:
- Agent A: 给 `config.py` 加字段 `feature_flag_x`
- Agent B: 给 `config.py` 加字段 `feature_flag_y`

两个 agent 都基于"最初的 config.py"做 Edit。

后果: A 先提交,把 `feature_flag_x` 加上。B 紧跟着提交时基于的是缓存的旧文件,Edit 会 **覆盖** A 的改动,`feature_flag_x` 丢了。

**Pattern (正确)**:

派任务时显式声明:
> 协议: 你在编辑 `config.py` **之前**,必须先用 Read 工具重新读这个文件最新内容(不要相信你上一轮看到的版本),再做 Edit。如果发现已有其他人加的字段,在合并基础上 append,不要覆盖。

或者更稳: 不让两个 agent 并行改同一文件,串行排队。改文件冲突的天花板是"工程师素质" + "VCS",不是"AI 直觉"。

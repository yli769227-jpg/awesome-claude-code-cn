# EXAMPLES — 测试即结论

## 反例(真实): 没查闭环就开工,459 行白干

**Anti-pattern**:

用户在 X 服务 issue #N(走 `feature → dev → main` 双分支策略的仓库)上说"修一下这条"。AI 立刻:

1. `gh issue view #N` 看到 state=OPEN
2. clone 仓库 → 切分支 → 写代码
3. 459 行实现 + 测试 + PR #M1

合到一半,顺手 `git log dev` 看下,发现 9 小时前已有 PR #M0 merged 到 dev,body 里写着 `Closes #N`——工作早就闭环了。AI 的 PR 是**纯重复工作**,只能 close + 删分支,白干 4 小时。

**问题**: AI 把 "issue state=OPEN" 当成了"工作没做"的证据。但 GitHub 的 `Closes #N` 自动闭环**只对 merge 到默认分支(main)生效**——base=dev 的 PR 即使写 `Closes #N` 也不会自动 close issue。"看上去 OPEN" ≠ "工作没做"。完成判定 = **可证伪的查重输出**,不是单看 issue state。

**Pattern (正确)**:

任何 issue triage / "修一下 X" 任务,**开工前**必须先跑:

```bash
gh pr list -R <owner>/<repo> --search "Closes #<n> in:body" --state all --limit 10
gh pr list -R <owner>/<repo> --search "<n>"               --state all --limit 10  # 兜底
git log dev --grep "Closes #<n>" --oneline                                          # 看 dev 分支
```

输出格式:

> ✅ 已查重: PR #M0 (MERGED to dev, 2026-05-12 02:19, commit `5d227bd`) 闭环 #N
> ❌ 无需重写实现
> ⚠️ issue 仍 OPEN 是因为 base=dev 不触发自动关 —— 走"审查意见 + 等用户验收 close"流程

**用户的反馈/品味**:

沉淀在 `feedback_check_existing_pr_before_issue_work`:**仓库自动化(self-heal bot / dispatcher)会在你看 issue 列表之后、动手之前的几小时里偷偷把活干了——不查重就动手是高频翻车点**。完成的定义不是写完代码,而是有可证伪的查重 / 测试 / 验收输出。

---

## 反例(真实): 修完直接 close,跳过监理

**Anti-pattern**:

AI 把 X 服务 issue #N 的实现合到 dev,跑了一遍 pytest 绿,立刻:

```bash
gh issue close N --reason completed
```

**问题**: "代码写完 + 测试绿" 不等于完成。CLAUDE.md 第 6 条"监理必选且有否决权"落地到 issue 治理 = 工程师不能既当裁判又当运动员,自我标 done 没用,必须**先在 issue 评论里写审查合格意见 + 等用户验收**,然后才能 close。直接 `gh issue close` = 跳过监理。

**Pattern (正确)**:

执行序列必须是:

1. `gh issue comment <n>` 写审查意见 —— 逐条对照 issue body 的 Acceptance Criteria,给出实际执行命令 + 输出证据(测试通过 / curl 输出 / grep 命中),用 ✅/❌/⚠️ 格式,末尾标"**待用户验收**"
2. 等用户回 `验收通过` / `close N` / `是` 等明确允许
3. 才 `gh issue close <n>`

如果走 PR merge 自动关(close keyword + base=main),把审查意见写到 PR 描述里,等价于评论审查。

**用户的反馈/品味**:

> "工程师不能既当裁判又当运动员,自我标 done 没用。"

沉淀在 `feedback_issue_close_requires_review`。完成 = **留下可审计的合格证据 + 用户验收**,不是 "pytest 绿"。

---

## 反例(通用): "应该没问题" 不是结论

**Anti-pattern**:

> AI: "我已经修复了 `parse_amount` 函数中的精度问题,改用了 `Decimal`。代码看起来没问题,逻辑也对。完成。"

**问题**: 没有跑测试,没有可证伪输出。"看起来"不是结论,是猜测。

**Pattern (正确)**:

> AI: 跑了 `pytest tests/test_parse_amount.py -v`,结果:
>
> ✅ 通过: 6/8 — 正常路径(整数 / 两位小数 / 大额) + 2 个边界(0.01 / 999999999.99)
> ❌ 失败: 1/8 — `test_negative_amount` 期望抛 ValueError,实际返回了 -100,需修
> ⚠️ 未覆盖: 输入为 `None` / 含千分位逗号 `1,234.56` 的场景,我没改这部分逻辑,暂不补
>
> 下一步: 修 ❌ 那条,你要我顺手补 ⚠️ 的两个 case 吗?

---

## 反例(通用): 测了不相关的东西凑数

**Anti-pattern**:

只改了 `auth.py` 的密码校验,但跑了全量 `pytest`,看到 1200 个 case 全绿就说"完成"。

**问题**: 1200 个 case 里只有 8 个跟 `auth.py` 相关,其他绿不绿跟这次改动没关系。结论虚胖。

**Pattern (正确)**:

> 改动靶向: `auth.py::verify_password`
>
> 跑了 `pytest tests/test_auth.py::test_verify_password -v` (8 个 case)
>
> ✅ 通过: 7/8 — 正确密码 / 错误密码 / 空密码 / 超长 / unicode / SQL 注入字符 / bcrypt hash 比对
> ❌ 失败: 1/8 — `test_timing_attack`,新逻辑对长短密码有 8ms 时间差,有侧信道风险
> ⚠️ 未覆盖: rate limit 路径未改,沿用旧测试
>
> 全量回归(1200 case)只在合并前跑,这一步不混入完成判定。

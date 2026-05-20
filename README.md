# awesome-claude-code-cn

> **Karpathy 告诉你 LLM 会犯什么错。我告诉你 LLM 在我这犯了什么错、我是怎么发现的、然后怎么治的。**

8 条铁律 · 真实反例 · 每天在用的中文 Claude Code 实战包。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-8_disciplines-blue.svg)](./skills/)
[![中文](https://img.shields.io/badge/lang-中文-red.svg)](README.md)

---

## 这个仓库不是什么

- ❌ 不是另一份"AI 编程提示词大全"
- ❌ 不是 Karpathy CLAUDE.md 的翻译
- ❌ 不是从 awesome-llm 抄过来的 list

## 这个仓库是什么

我每天用 Claude Code 写代码、审 PR、跑 agent 团队。这一年里 AI **真的在我这犯过的错**,我一条条沉淀成了 8 个 `discipline-*` skill,每个都带 `SKILL.md` (规则) + `EXAMPLES.md` (**真实反例对照**)。

不是抽象的"AI 应该这样那样",是 **"上周三 AI 这么搞砸了,我说了什么,以后怎么避"**。

---

## 镇仓的 8 条铁律 (discipline-*)

| Skill | 一句话 | 触发时刻 | 真实反例 |
|---|---|---|---|
| [`discipline-ask-before-act`](./skills/discipline-ask-before-act/) | 先问再动手 | 即将做非平凡变更前 | "谁让你关的?"—— AI 把状态陈述脑补成 close 授权 |
| [`discipline-test-is-truth`](./skills/discipline-test-is-truth/) | 测试即结论 | 即将声明任务完成前 | 没查闭环就开工,**459 行白干** |
| [`discipline-log-first`](./skills/discipline-log-first/) | 日志优先 | 即将写新模块前 | (通用反例) |
| [`discipline-check-versions`](./skills/discipline-check-versions/) | 先测炉温再铸剑 | 即将用某个 API 前 | macOS 本地 `npm install` 通了,Linux CI **必挂** |
| [`discipline-agent-team`](./skills/discipline-agent-team/) | Agent Team 协作 | 即将大批量改代码前 | (通用反例) |
| [`discipline-incremental-build`](./skills/discipline-incremental-build/) | 增量编译 + 接口变更协议 | 即将改 3+ 文件前 | (通用反例) |
| [`discipline-no-dead-code`](./skills/discipline-no-dead-code/) | 不假设 dead code | 即将删任何符号前 | (通用反例) |
| [`discipline-first-principles`](./skills/discipline-first-principles/) | 第一性原理 | 即将用"通常这样做"做理由前 | (通用反例) |

每条 skill 的 `EXAMPLES.md` 才是真正的精华 —— 标 **"反例(真实)"** 的都是脱敏后的实际事故。

---

## 让你最快入门的两段

**1. 如果你只读一个文件**:

[`skills/discipline-test-is-truth/EXAMPLES.md`](./skills/discipline-test-is-truth/EXAMPLES.md)

里面的第一个真实反例 —— "**没查闭环就开工,459 行白干**" —— 是我去年五月的真实事故。GitHub 的 `Closes #N` 自动闭环**只对 merge 到默认分支生效**,base=dev 的 PR 即使写 `Closes` 也不会自动关 issue。AI 凭 "state=OPEN" 拍脑袋开工,实现完才发现 9 小时前 PR 已经把活干完了。

修复办法在文末。

**2. 如何用这些 skill**:

把整个 `skills/` 目录拷到 `~/.claude/skills/`,Claude Code 会自动读 frontmatter 的 `description` 决定何时触发。

```bash
git clone https://github.com/yli769227-jpg/awesome-claude-code-cn.git
cp -r awesome-claude-code-cn/skills/discipline-* ~/.claude/skills/
```

然后在 `~/.claude/CLAUDE.md` 加几行触发说明:

```markdown
当你即将做非平凡的代码变更前 → 加载 ~/.claude/skills/discipline-ask-before-act/SKILL.md
当你即将声明任务完成 → 加载 ~/.claude/skills/discipline-test-is-truth/SKILL.md
...
```

---

## 为什么用中文写

中文社区里的 Claude Code 资源还是英文翻译居多。但 AI 跟你的对话本来就是中文的 —— skill 也应该是中文的。8 条铁律的 `EXAMPLES.md` 里保留了**当事人原话**(脱敏后),包括我当场怼 AI 的措辞("你怎么听不懂人话,老是擅自做决定")。这种语气只能用中文写,翻成英文就丢魂了。

---

## 路线图

- [x] 8 个核心 discipline + 真实反例
- [ ] 加入更多中文社区贡献的真实反例(欢迎 PR,见 [CONTRIBUTING.md](./CONTRIBUTING.md))
- [ ] 视频版:每个 discipline 拍 1 分钟"我是怎么被坑的"短片
- [ ] 配套 CLI 工具 `mcp-audit`(独立仓库,扫 Claude Code MCP 配置)

---

## 致谢

灵感来自:

- [Andrej Karpathy's tweet](https://x.com/karpathy/status/2015883857489522876) 关于 LLM coding pitfalls
- [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) —— 英文原版 CLAUDE.md
- [bytedance/deer-flow](https://github.com/bytedance/deer-flow) —— skills/ 目录拆分思路

---

## License

[MIT](LICENSE) —— 随便拿,但麻烦留个 star ⭐

---

> 如果你用上了这些 skill,觉得真的省了你的时间(尤其是省了你的怒气),
> 欢迎来 [Issues](https://github.com/yli769227-jpg/awesome-claude-code-cn/issues) 讲一下你被 AI 坑过的真实场景。每收到一条,我会沉淀成新的 `EXAMPLES.md` 反例,**署你的名字**。

# 贡献指南

最有价值的贡献是 **你被 AI 坑过的真实瞬间**。

## 怎么提一个"真实反例"

打开对应 discipline 的 `EXAMPLES.md`,在最顶部加一节:

```markdown
## 反例(真实): [一句话场景描述]

**Anti-pattern**:

> [脱敏后引用实际对话/代码片段]

**问题**: [那次为什么不对]

**Pattern (正确)**:

> [你后来怎么修的]

**反馈**: [当时你的原话,可以保留情绪]
```

### 脱敏要求

- ❌ 不能保留:具体客户名 / 内网域名 / 真实仓库名(私有项目)/ issue 编号 / 同事真名
- ✅ 可以保留:公开仓库名 / 通用技术名词 / 你自己的措辞 / 错误信息片段

### 选 discipline 的规则

如果你纠结这个反例属于哪条 discipline,以**纠正动作**为准,不是事故本身:

- 修了之后变成"先问一句" → `ask-before-act`
- 修了之后变成"跑测试 / 出三段式结论" → `test-is-truth`
- 修了之后变成"先 `node -v` / `pip show X`" → `check-versions`
- 修了之后变成"派 agent 不在主线程展开" → `agent-team`
- ……

## PR 接受标准

- ✅ 反例真实(可以泛化,但底层得是真事)
- ✅ 脱敏到位
- ✅ Pattern 部分给出**可执行的**修正步骤(命令/代码/查询),不是空话
- ✅ 把你的 GitHub handle 加到反例标题旁,或在 PR 描述里说明

我会在合并时把你的署名加到 `EXAMPLES.md`。

## 不接受的 PR

- ❌ 翻译/校对纯文字润色(欢迎直接 commit 到你的 fork,但本仓不接)
- ❌ 添加新的 discipline-* skill(8 个已经覆盖完整,新场景请挂到现有 discipline 下)
- ❌ 把英文社区的反例直接搬过来(不是中文社区的真实场景)
- ❌ 编造的"假设场景"(读者一眼能看出来)

## 其他

- 不要改 `SKILL.md` 的规则条款 —— 那是 CLAUDE.md 沉淀,不是 anti-pattern 库
- 不要往仓库加新目录 —— 范围锁死 8 个 discipline

有疑问开 [Discussion](https://github.com/yli769227-jpg/awesome-claude-code-cn/discussions)。

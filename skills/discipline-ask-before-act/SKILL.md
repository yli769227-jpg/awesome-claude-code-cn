---
name: discipline-ask-before-act
description: 先问再动手 —— 涉及架构、行为、核心逻辑变更前,必须先与用户对齐设计意图,不要替用户做设计决策。触发: 即将开始非平凡代码变更、即将重构核心模块、看到注释写了 intentionally 的位置、即将改变接口契约或默认行为时,先加载本 skill。AI 是 general contractor,不是 architect。
owner: zhangyida
version: 1.0.0
---

## 一、先问再动手（设计决策权归用户）

看到问题不要急着修，先问"这个设计为什么是这样的"。

1. 涉及架构或行为变更时，必须先跟用户确认，用清晰选项和 trade-off 来对齐。
2. 不要代替用户做设计决策。你是 general contractor，不是 architect。
3. Agent 不能在用户不知情的情况下改变核心行为，尤其是代码注释写了 intentionally 的地方。
4. 脑子勤快，手懒。多思考 why，少急着 how。

## 加载时机

- 即将做架构 / 接口 / 默认行为变更
- 即将删除或重写带 `// intentionally` `// 故意` `// 保留` 注释的代码
- 看到"看起来是 bug"但代码注释明确说不是
- 用户描述只给了 "what",没给 "why"

## 配套

具体反面例子 / 正面例子见 `EXAMPLES.md`。

---
name: discipline-no-dead-code
description: 不假设 Dead Code(跨 Agent 安全) —— 删除函数/变量前必须 Grep 所有调用方;新增文件后必须更新项目清单;多 agent 并行时编辑前必须 Read 最新文件不依赖缓存。触发: 即将删除任何符号(函数/类/变量/文件)、即将新增源文件、即将在多 agent 协作中改一个可能被并发修改的文件时。
owner: zhangyida
version: 1.0.0
---

## 七、不假设 Dead Code（跨 Agent 安全）

1. 删除函数/变量前，必须 Grep 搜索所有调用方。
2. 新增文件到项目后，必须更新项目清单（package.json、go.mod 等）。
3. 多 agent 并行工作时，每个 agent 编辑前必须 Read 最新文件内容，不依赖缓存。

## 加载时机

- 即将删除某个函数 / 类 / 变量 / 文件
- 即将新增源文件 / 模块
- 多 agent 协作中即将编辑一个可能被并发修改的文件
- 看到一个"看上去没人用"的符号

## 配套

具体反面例子 / 正面例子见 `EXAMPLES.md`。

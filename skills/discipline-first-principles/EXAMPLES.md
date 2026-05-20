# EXAMPLES — 第一性原理

## 反例 1: "通常微服务这么拆"

**Anti-pattern**:

用户: "我们要把这个系统拆成微服务"

AI 回答(错误): "通常按 DDD 拆,user-service / order-service / payment-service / notification-service / inventory-service。建议引入 Kafka + service mesh。"

**问题**: 没问当前规模、当前痛点、团队人数、运维能力。直接套行业默认。结果:
- 5 个服务但只有 3 个工程师 → 没人维护
- 没事务边界设计 → 跨服务一致性靠 retry,数据漂移
- service mesh 把 latency 拉高 5x,业务对延迟敏感

**Pattern (正确)**:

> 先把第一性事实摆出来:
> 1. **现状**: 单体,200 RPS,3 个工程师,部署 1 次/周,主要痛点是"前端改一行 CSS 要等后端 deploy"
> 2. **不可简化事实**:
>    - 痛点是 release 耦合,不是 scale 不动
>    - 团队 3 人,运维能力支撑不了 5+ 服务
>    - 数据一致性目前靠 DB 事务,业务高度依赖
> 3. **挑战默认假设**:
>    - "微服务" 是手段不是目的。痛点其实是"前后端 release 解耦"。
>    - 那真问题是 **deployment unit 切分**,不是 service boundary 切分。
> 4. **重推方案**:
>    - (A) 单体不动,前端独立 deploy(分离 CI) → 解决 80% 痛点,运维不变
>    - (B) 拆 2 个服务: web (前端 BFF) + core (业务),先验证拆分代价
>    - (C) 全套微服务 —— 暂不推荐,人手不够
>    我倾向 (A) → (B) 渐进。

---

## 反例 2: "REST 是行业默认,就用 REST"

**Anti-pattern**:

AI: "你们要做个内部数据同步管道,我建议 REST API + JSON,这是业界标准。"

**问题**: 没问数据量、是否实时、消费者数量、网络拓扑。

**Pattern (正确)**:

第一性约束:
- 数据量: 单日 10 亿条事件 → REST + JSON 序列化开销吃满 CPU
- 实时性: 端到端 < 1s → 同步 HTTP 拉模式无法满足
- 消费者: 7 个下游 → 每个都 poll 一遍源,N+1 问题
- 网络: 同 VPC 内,稳定低延迟

从约束推:
- "拉" 模式不行 → 要 "推"
- 多消费者 → 要 fan-out
- 高吞吐 → JSON 不行,要二进制(protobuf / avro)
- 低延迟 → 不要走 HTTP overhead

结论: Kafka + protobuf,不是 REST。
不是因为 "Kafka 是 best practice",是因为约束推到这里。

---

## 反例 3: "数据库都这么设计"

**Anti-pattern**:

> "用户表加 `created_at` / `updated_at` / `deleted_at`,软删除,这是 ORM 默认模式。"

**问题**: 没问业务是否真需要保留删除记录、查询模式是否能容忍每条 SQL 都带 `WHERE deleted_at IS NULL`。

**Pattern (正确)**:

> 不变式 / 业务事实:
> 1. 用户"删除"在产品上是不可逆操作(GDPR 要求物理删除)
> 2. 99% 查询是按 active 用户检索
> 3. 历史 / 审计已经在独立 `audit_log` 表里
>
> 挑战默认假设:
> - "软删除" 是为了 "误删可恢复 + 保留历史"
> - 但 GDPR 要求物理删,误删恢复需求由 audit_log 满足
> - 软删除反而带来:每条查询都要带 `deleted_at IS NULL` 过滤、索引冗余、误漏过滤泄漏数据
>
> 重推: 物理删除 + audit_log 记 `event=user_deleted, payload=<json>`。
> 不是因为 "soft delete 是反模式" 这种笼统话,是因为这个业务的约束推出这个结论。

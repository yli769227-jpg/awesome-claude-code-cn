# EXAMPLES — 增量编译验证 + 接口变更协议

## 反例 1: 连改 5 个 TS 文件,最后才 build,400 个错

**Anti-pattern**:

任务: "把项目里所有 `any` 替换成具体类型"

AI 行为(错误):
1. Edit `user.ts` (引入 `User` 类型)
2. Edit `order.ts` (引入 `Order` 类型,同时改 `user` 字段为 `User`)
3. Edit `payment.ts` (改了 `order` 字段为 `Order`)
4. Edit `report.ts` (改了一堆 `any[]` → `User[]`)
5. Edit `index.ts` (重新导出)
6. `tsc` → 输出 412 个错误,各文件互相 cascade

**问题**:
- 不知道哪个错是 root cause,哪个是 cascade
- 412 个错让人放弃 → "回滚吧" → 半天白干
- 错误信息互相掩盖,真正的类型设计 bug 看不出来

**Pattern (正确)**:

1. Edit `user.ts` → `tsc -p . --noEmit` → ✅ 0 错
2. Edit `order.ts` → `tsc` → ❌ 3 个错(都在 order.ts) → 当场修 → ✅
3. Edit `payment.ts` → `tsc` → ❌ 1 个错(因为 `order` 字段类型变了,需要更新 cast) → 当场修 → ✅
4. ...

每步都是 "可定位 + 可修复" 的小台阶,不会出现 412 个错的雪崩。

---

## 反例 2: 改了接口,忘了 mock 也要跟着改

**Anti-pattern**:

```go
// 接口定义改了
type Storage interface {
    Get(ctx context.Context, key string) ([]byte, error)
    // 新增
    GetWithTTL(ctx context.Context, key string) ([]byte, time.Duration, error)
}
```

AI 只改了 `RealStorage` 实现,跑 build → 编译过。
跑测试 → 一堆测试编译失败,因为 `MockStorage` / `FakeStorage` / `InMemStorage` 都没实现 `GetWithTTL`。

**问题**: build 编译过是因为生产代码不依赖 mock,但测试套件全挂。补救要返工。

**Pattern (正确)**:

1. **先搜**:
   ```
   $ rg -l "type \w+ struct" --type=go | xargs rg -l "func.*Get.*key string.*\[\]byte"
   storage/real.go
   storage/mock_test.go
   storage/inmem.go
   testutil/fake_storage.go
   ```
2. **列清单**:
   - storage/storage.go (接口定义)
   - storage/real.go (RealStorage)
   - storage/mock_test.go (MockStorage)
   - storage/inmem.go (InMemStorage)
   - testutil/fake_storage.go (FakeStorage)
3. **一次性全改**: 接口 + 4 个实现在同一次编辑批次完成
4. **立即验证**: `go build ./... && go test ./...` → ✅ 全过

---

## 反例 3: agent 子任务没要求"每文件 build"

**Anti-pattern**:

主线程派 agent: "把 `models/` 目录下所有 model 加 `created_at` 字段。"

agent 行为(错误): 一口气改了 12 个 model 文件,最后 build → 27 个错,因为 migration script 没同步生成,某些字段命名冲突。

**问题**: 派任务时没规定增量验证步骤,sub-agent 默认批量改。

**Pattern (正确)** 派任务模板:

> 任务: 给 `models/` 下所有 model 加 `created_at` 字段(`DateTime`, 默认 now)
>
> 协议:
> - 一次改一个 model 文件
> - 改完立即 `python -m pytest tests/test_<model>.py -x`,绿了才进下一个
> - 同时生成对应的 alembic migration
> - 全部改完后跑全量 `pytest`,输出 ✅/❌/⚠️
>
> 禁止: 批量改 12 个文件后才第一次跑测试

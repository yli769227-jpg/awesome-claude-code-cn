# EXAMPLES — 先问再动手

## 反例(真实): 把"状态观察"脑补成"close 授权"

**Anti-pattern**:

用户在审一个 X 服务的 issue,前面已经 close 过另一个编号 #N1(用户原话:"close N1"),AI 顺手按"用户应该是想都 close"心态做了下一步。半小时后用户瞥一眼说:

> "#N2 仍然 open"

AI 把这句话理解成"用户在催 close,授权我关",直接跑 `gh issue close N2 --reason completed`。

下一个 turn 用户立即质问:

> "谁让你关的?"

**问题**: 这是**状态陈述**,不是动作指令。AI 用上文 "close N1 那次允许了" 推理"这次也允许",等于**脑补意图**。不可逆动作(close / merge / push / send)的代价 >> 多问一句的代价,默认应该不动。

**Pattern (正确)**:

> "✅ 已确认 #N2 当前 state=OPEN。
> 我注意到上面 PR #X 已合并到 dev,实现可能已闭环这条 issue。
> 要我 close #N2 吗? (yes / 不动)"

等用户原话出现 `close N2` / `是` / `关掉` 等 explicit 授权词,才执行 close。

**用户的反馈/品味**:

> "你怎么听不懂人话,老是擅自做决定,这样会出大问题的。"

随后用户要求沉淀成规则:**explicit 授权词清单**仅包括 `是` / `yes` / `ok` / `close N` / `merge` / `push` / `发飞书` 这种命令式动词 + 对象。状态陈述 / 观察 / 提问 / 复述一律不算授权,默认就是不动。Memory 里这条记成 `feedback_no_intent_inference_for_actions`。

---

## 反例(真实): "开启模式" 被脑补成"立刻发"

**Anti-pattern**:

用户说"开启飞书"。AI 立刻追问:"好的,要发什么表格?标题是什么?要 @ 谁?发哪个群?"

**问题**: "开启 X" 是**模式切换**,只代表进入待命,不等同于"立刻执行该模式下的某个子能力"。AI 替用户做了"开启飞书 = 发表格"这个映射。飞书 skill 有多条能力线(发文本 / 发表格 / @ 成员 / 拉群成员),模式词是笼统入口,不指向任何一条。

**Pattern (正确)**:

> "飞书模式已开。要做什么? (发消息 / 发表格 / @ 谁 / 拉成员)"

然后停下等具体能力词("发表格 X" / "@ 张三 说 Y")再动。

**用户的反馈/品味**:

> "开启飞书不代表要发送表格,不要误解我的意思。"

沉淀规则:模式词 → 待命,能力词 → 执行,混合句("开启飞书然后 @ 张三")按后半段的能力词走。这条规则对**所有多能力 skill** 都适用(不只飞书),沉淀在 `feedback_mode_switch_vs_action`。

---

## 反例(真实): 对外通讯通道少了一次确认

**Anti-pattern**:

用户:"发飞书让大家知道 X 上线了。"

AI 立刻:跑脚本,把 payload 拼好直接 `send_message.py` 推到群里。

**问题**: 飞书群是真实对外通讯通道,发出无法撤回。AI 即使读懂了用户意图,也不能跳过"预览 + 二次确认"。误发一条对外消息的代价(信任损耗 + 通知所有人)远大于多问一句"要发吗?"的代价。

**Pattern (正确)**:

> "准备发到 [群名](chat_id=oc_xxx):
> > X 已上线,Y 时间窗口,详情见 Z
>
> @[张三](open_id=ou_xxx) @[李四](open_id=ou_yyy)
>
> 发? (是 / 否)"

等用户回 `是` / `发` / `yes` / `ok` 之一才真跑脚本。即使用户之前同意过"默认发送",一旦他再次声明这条规则就一直遵守——**规则优先级高于便捷性**。

**用户的反馈/品味**:

> "发送给飞书的消息必须进行二次确认,先发给我,给我两个选项,是或者否,只有我回答是才能发送。"

只读操作(拿 token / 列成员 / 查群)不需要二次确认,因为不对外产生内容。沉淀在 `feedback_feishu_confirm_before_send`。

---

## 反例(通用): 看到"奇怪"的代码就重写

**Anti-pattern**:

```python
def parse_amount(raw: str) -> int:
    # intentionally keep as int (cents), do NOT convert to float
    return int(raw.replace(".", ""))
```

AI: "这里用 int 处理金额很奇怪,我把它改成 `decimal.Decimal` 更合适。" 直接 Edit 改成 Decimal 提交。

**问题**: 注释明确写了 `intentionally`,这是用户为了避免浮点误差刻意做的选择。AI 没问就改,等于偷偷改了核心行为。

**Pattern (正确)**:

> "我注意到 `parse_amount` 注释写了 `intentionally keep as int (cents)`,但调用方在 `report.py:42` 又用 `/ 100` 还原成元。是想让我:
> (A) 保留 int 现状,仅修 report.py 的精度问题
> (B) 整体切到 Decimal,我列一下所有调用方
> (C) 不动,你想保留这个设计?
> 你倾向哪个?"

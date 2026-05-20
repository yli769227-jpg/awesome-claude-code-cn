# EXAMPLES — 日志优先

## 反例 1: 错误被默默吞掉,没人知道发生了什么

**Anti-pattern**:

```python
def fetch_user(user_id: str) -> dict | None:
    try:
        resp = httpx.get(f"{API}/users/{user_id}", timeout=5)
        return resp.json()
    except Exception:
        return None
```

**问题**: 出错时返回 `None`,调用方拿到空,但 **不知道是 404、timeout、还是 JSON 解析错**。生产事故时只能猜。

**Pattern (正确)**:

```python
import logging
log = logging.getLogger("user_api")

def fetch_user(user_id: str) -> dict | None:
    log.info("[user_api] fetch_user start user_id=%s", user_id)
    try:
        resp = httpx.get(f"{API}/users/{user_id}", timeout=5)
        log.info("[user_api] fetch_user resp status=%s len=%d",
                 resp.status_code, len(resp.content))
        resp.raise_for_status()
        return resp.json()
    except httpx.TimeoutException as e:
        log.error("[user_api] fetch_user TIMEOUT user_id=%s err=%s", user_id, e)
        return None
    except httpx.HTTPStatusError as e:
        log.error("[user_api] fetch_user HTTP_ERROR user_id=%s status=%s",
                  user_id, e.response.status_code)
        return None
    except Exception as e:
        log.exception("[user_api] fetch_user UNEXPECTED user_id=%s", user_id)
        return None
```

要点: 模块前缀 `[user_api]`、入参、出参摘要、错误分类 + 上下文。

---

## 反例 2: 状态机变化没日志,事后无法回放

**Anti-pattern**:

```python
class Order:
    def pay(self):
        if self.status == "pending":
            self.status = "paid"
    def ship(self):
        if self.status == "paid":
            self.status = "shipped"
```

**问题**: 用户投诉"我下了单为啥没发货",查 DB 看到 `status=pending`,但**不知道**中间是不是支付过又被改回去了、是哪个调用方触发的。

**Pattern (正确)**:

```python
class Order:
    def _transition(self, frm, to, actor):
        log.info("[order:%s] state %s -> %s by=%s ts=%s",
                 self.id, frm, to, actor, time.time())
        self.status = to

    def pay(self, actor="user"):
        if self.status != "pending":
            log.warning("[order:%s] pay rejected current=%s", self.id, self.status)
            return False
        self._transition("pending", "paid", actor)
        return True
```

要点: 状态机每次跃迁都打,带 actor + timestamp,出问题 grep `[order:12345]` 一行还原。

---

## 反例 3: 日志格式散乱,无法 grep

**Anti-pattern**:

```
2026-05-20 10:00:01 ok
2026-05-20 10:00:02 starting
2026-05-20 10:00:03 done
2026-05-20 10:00:04 error: something failed
```

**问题**: 没有模块前缀、没有操作名、没有 ID,出事根本 grep 不出来"用户 42 当时在干嘛"。

**Pattern (正确)**:

```
2026-05-20 10:00:01 [auth] login start user_id=42 ip=1.2.3.4
2026-05-20 10:00:02 [auth] login ok user_id=42 session=abc
2026-05-20 10:00:03 [order] create start user_id=42 sku=X
2026-05-20 10:00:04 [order] create FAIL user_id=42 sku=X err=InventoryEmpty
```

`grep "user_id=42" app.log` 即可还原该用户完整路径。

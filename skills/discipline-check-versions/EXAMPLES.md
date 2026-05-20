# EXAMPLES — 先测炉温,再铸剑

## 反例(真实): 本地 npm install 通了 ≠ Linux CI 也通

**Anti-pattern**:

用户在 ashare-mcp 加 web 前端。AI 在 macOS 本地跑:

```bash
npm install            # 通了, 0 errors
git add package-lock.json && git commit && git push
```

Linux CI 上 `npm ci` 立即挂:

```
Missing: @emnapi/core@1.10.0 from lock file
Missing: @emnapi/runtime@1.10.0 from lock file
```

AI 第一次 fix 用了 `npm install --package-lock-only`,push 后还是挂。第二次才查清楚:
- `@emnapi/*` 是**平台相关 optional 依赖**(`tinyglobby → fdir` 拉,Linux/Windows 才装,macOS 不装)
- `npm ci` 默认严格,lock 必须完整覆盖所有可能的 transitive
- 必须 `npm install --include=optional` 才把 lock 的 `packages` 字段补全

**问题**: AI 凭"npm install 通常这样"直接跑,没查 npm 在跨平台 + 严格 ci 场景下的实际行为。"本地通了"是本地版本 / 本地平台的炉温,不能直接搬到 Linux x64 容器里。涉及包管理器、Node 版本、平台后缀(`@emnapi/*` / `@rollup/*-linux-*` / `@swc/core-linux-*`) 的行为时,必须**先查这个版本/平台下的实际行为**,再写命令。

**Pattern (正确)**:

任何新建 Node 前端 + Linux CI 项目,初始锁 lock 时:

```bash
# 1. 先查炉温
node -v                     # 本地 + CI 是否一致
npm -v
cat .github/workflows/*.yml | grep "npm "  # CI 用 ci 还是 install

# 2. 一次性把 platform-optional deps 拉全
rm -rf node_modules package-lock.json
npm install --include=optional

# 3. 验证 lock 覆盖
grep -E "@emnapi|linux-x64|win32-x64" package-lock.json | head
```

看到 CI `npm ci` 报 `Missing: X from lock file` 且 X 是 `@emnapi/*` / `@rollup/*-linux-*` / `@swc/core-linux-*` 这种带平台后缀的包名 → 直接 `rm -rf node_modules package-lock.json && npm install --include=optional`,不要诊断 npm 版本或 node_modules cache。

**用户的反馈/品味**:

沉淀在 `feedback_npm_cross_platform_lock`:**本地环境 ≠ 远端环境**——CI 不要改成 `npm install` 绕过严格性,因为那样 lock 漂移就再也兜不住了,治本在本地 lock。同源问题: `feedback_gh_dual_account_push_fix`(本地 keychain active 账号 ≠ push 目标账号)。

---

## 反例(真实): 假设当前 gh active 账号就是 push 目标账号

**Anti-pattern**:

AI 跑 `/ai-think` 推博客到 yli769227-jpg/ai-thoughts,直接 `git push origin main`,撞错:

```
remote: Permission to yli769227-jpg/ai-thoughts.git denied to yao-li-0001
fatal: unable to access ...: The requested URL returned error: 403
```

AI 开始诊断 osxkeychain / credential.helper / `git config --list` —— 走错方向了。

**问题**: 用户的 `gh auth` 里同时登录了 `yao-li-0001` 和 `yli769227-jpg` 两个账号(都在 keyring 里)。git credential helper 用 gh 提供的 token,token 跟着**active 账号**走。某些 gh 操作 / 系统重启 / 其他终端切换会改变 active 账号——一旦 active 是 `yao-li-0001`,推 yli 账号下的仓库就被 GitHub 拒。AI 没先查"当前 active 是谁"就开始诊断 credential layer,等于不测炉温就铸剑。

**Pattern (正确)**:

看到报错文案明确写 `denied to yao-li-0001`(或其他非 yli 账号),目标仓库属于 `yli769227-jpg`,立即跑:

```bash
gh auth switch -u yli769227-jpg
gh auth setup-git
git push origin main
gh auth status            # 验证 yli769227-jpg 是 Active account: true
```

不要在 osxkeychain / credential.helper 上浪费时间排查。如果用户在做关键发布(如 `/ai-think` 推博客),**提前**跑一次 `gh auth status` 看一眼当前 active,可以避免这个坑。

特殊 case: `gh repo create yli769227-jpg/<repo> --source=. --push` 内部 fork 子进程跑 git push,继承的 credential helper 链跟主 shell 不一样,setup-git 改的配置不一定生效——这个 case 不要重试 setup-git,直接 token-in-URL 推一次,推完务必把 remote 改回干净 URL。

**用户的反馈/品味**:

沉淀在 `feedback_gh_dual_account_push_fix`。规则: **报错文案里出现具体身份(`denied to <user>`),先查身份是不是对的,再查 credential 层**。

---

## 反例(通用): 凭记忆写 Node fetch,实际版本不支持

**Anti-pattern**:

```js
const res = await fetch("https://api.example.com/x");
```

跑起来报 `ReferenceError: fetch is not defined`。

**问题**: AI 假设 `fetch` 在 Node 全局可用。但项目用的是 Node 16,`fetch` 在 Node 18+ 才默认 expose。

**Pattern (正确)**:

```
$ node -v
v16.20.0

$ cat package.json | grep node
"node": ">=16"
```

> Node 16,全局没有 fetch。三个选项:
> (A) 升级 Node 到 18+(影响 deploy)
> (B) 用 `node-fetch` 包(轻量)
> (C) 用 `axios` / `undici`(项目已装哪个?我看下 package.json)
>
> 我先 grep 一下你现在用什么 HTTP 客户端。

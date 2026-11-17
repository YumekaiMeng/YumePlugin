# Module Unloader

- 一个轻量级 FinaSU 插件，在开机尽可能早的阶段卸载指定的内核模块，并在后台每 30 分钟重新检测一次
- 没做混淆，太简单了没必要我20分钟多点就写好了。该说不说，写这个插件比magisk模块轻松多了，lua还是好用的
- 已上传至 FinaSU 官方仓库

## 功能特性

- **最早阶段卸载**：在 `post_fs_data` 回调中执行，这是启动过程中最早的阶段之一，因此列表中的模块会在开机后尽快被移除。
- **后台重复检测**：在 `service` 阶段启动守护任务，每 30 分钟（1800 秒）扫描一次模块列表，若模块被重新加载则再次卸载。
- **可编辑模块列表**：只需修改 `main.lua` 中的一个表即可增删或重命名模块。
- **手动触发**：提供插件 `action`，可随时手动执行一轮卸载。
- **多路径 `rmmod` 回退**：依次尝试 `/system/bin/rmmod`、`/sbin/rmmod`、`/usr/bin/rmmod`。

## 默认模块列表

| 模块 | 说明 |
|---|---|
| `oplus_secure_guard_new` | OPPO的oplus_secure_guard_new在未检测到解锁的情况下会反复杀死ksud，反复重启会导致异常卡顿 |
| `inte` | ACE内核模块，可能执行扫盘等异常操作 |


如需修改列表，编辑 `main.lua` 顶部的 `MODULES` 表即可：

```lua
local MODULES = {
    "模块名称",
}
```

## 文件结构

```
module_unloader/
├── plugin.json   # 插件清单与回调声明
└── main.lua      # 插件逻辑
```

- `plugin.json` 声明了 `callbacks: ["post_fs_data", "service"]` 以及 `has_action: true`。
- `main.lua` 实现了 `post_fs_data`、`service`、`action` 以及后台回调 `daemon_tick`。

## 工作原理

1. **`post_fs_data`**：在开机尽可能早的阶段，对 `MODULES` 中的每个模块执行一次卸载。
2. **`service`**：调用 `start_daemon("daemon_tick", 1800)`，每 30 分钟运行一次后台任务。
3. **`daemon_tick`**：执行一轮卸载后返回；由守护任务按计划重复调用，不会阻塞。

## 环境要求

- 运行 FinaSU 且已启用插件支持的设备。
- Root 权限以及卸载内核模块（`rmmod`）的权限。
- 目标模块必须可卸载：未编译进内核、未被其他模块占用，且 SELinux 策略允许。

> **注意**：即使模块已在列表中，`rmmod` 仍可能失败。失败信息会以 `warn` 级别写入日志，可通过插件日志查看结果。

## 安装方法

### 第一步：从 GitHub 下载源码 ZIP

1. 打开项目页面：`https://github.com/LyraVoid/FinaSU`
2. 点击页面右上角的绿色 **`Code`** 按钮。
3. 在弹出的菜单中选择 **`Download ZIP`**。
4. 浏览器会下载 `module_unloader.zip`。

### 第二步：在 FinaSU 管理器中安装

1. 打开设备上的 **FinaSU 管理器**。
2. 进入 **插件（Plugins）** 页面。
3. 点击 **从本地安装 / Install from local**。
4. 选择刚才下载的 `FinaSU-master.zip`。
5. 等待管理器解析并安装完成。
6. 在插件列表中确认 **Module Unloader** 已显示为启用状态；若未自动启用，手动开启即可


### 第三步：充气手机，并检查日志是否有Unloaded module字样

1. 打开设备上的 **FinaSU 管理器**。
2. 进入 **插件（Plugins）** 页面，观察有无

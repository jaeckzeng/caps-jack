# Caps Lock 键位映射工具

使用 AutoHotkey v2 实现 Caps Lock 键位映射，参考 [capslock-plus](https://github.com/wo52616111/capslock-plus) 实现。

## 功能说明

| 按键 | 功能 |
|------|------|
| **Caps Lock** | 切换中英文输入法（Ctrl+Space） |
| **Ctrl+Caps Lock** | 切换大小写锁定 |

## 特性

- 启动时自动请求管理员权限，确保在老软件中也能生效
- 使用 `SetStoreCapsLockMode False` 拦截 Caps Lock 原始行为
- 300ms 犹豫时间区分单按与组合键操作

## 安装与运行

### 1. 安装 AutoHotkey

1. 访问 [AutoHotkey 官网](https://www.autohotkey.com/)
2. 下载并安装 **AutoHotkey v2**（本脚本基于 v2 语法）

### 2. 运行脚本

- 双击 `caps-remap.ahk`
- 脚本会自动请求管理员权限，同意 UAC 提示即可
- 运行后系统托盘会出现 AutoHotkey 图标

### 3. 停止脚本

- 右键系统托盘中的 AutoHotkey 图标 → "Exit"

## 开机自启动

### 一键配置（推荐）

- **安装**：双击运行 `install-startup.bat`，自动创建计划任务
- **卸载**：双击运行 `uninstall-startup.bat`，移除计划任务

### 手动配置

1. 按 `Win+R`，输入 `shell:startup`，回车
2. 在此文件夹中创建 `caps-remap.ahk` 的快捷方式

## 技术说明

- 使用 `*CapsLock::` 热键（`*` 前缀确保 Ctrl 按住时也能触发）
- 使用 `SetStoreCapsLockMode False` 阻止 Caps Lock 状态被意外修改
- 使用 `SetCapsLockState` 直接控制大小写状态
- 使用 `/restart` 参数防止管理员提权导致的循环重启

## 文件说明

- `caps-remap.ahk` - 主脚本文件（AutoHotkey v2）
- `install-startup.bat` - 一键配置开机自启动
- `uninstall-startup.bat` - 一键移除开机自启动
- `README.md` - 本说明文档

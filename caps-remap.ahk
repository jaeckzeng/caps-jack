; =============================================================================
; Caps Lock 键位映射工具
; 参考 capslock-plus 实现
;
; 功能：
;   - 单独按下 Caps Lock：切换输入法（Ctrl+Space）
;   - Ctrl + Caps Lock：切换大小写锁定
;   - WindTerm 窗口激活时 Ctrl+Shift+Q：强杀并重启 WindTerm
;
; 使用方法：
;   1. 安装 AutoHotkey v2 (https://www.autohotkey.com/)
;   2. 双击运行此文件（会自动请求管理员权限）
;   3. 脚本在托盘区显示图标；右键 → Exit 可退出
;
; 启动流程（每次双击运行）：
;   非管理员进程 → UAC 提权并退出 → 管理员进程强杀旧实例 → 注册热键
; =============================================================================

#Requires AutoHotkey v2.0

; 不用 #SingleInstance Force：提权后脚本以管理员运行，普通权限新实例
; 无法用 Force 关闭旧实例，会卡在 “Could not close the previous instance” 对话框
#SingleInstance Off

; 放宽热键触发频率限制，避免 Caps Lock 快速连按被 AHK 忽略
A_MaxHotkeysPerInterval := 500

; -----------------------------------------------------------------------------
; 启动：管理员提权 + 替换旧实例
; -----------------------------------------------------------------------------

; 若当前非管理员，则用 UAC 启动提权副本并立即退出本进程
; /restart 参数标记「已是提权流程」，防止无限循环弹 UAC
full_command_line := DllCall("GetCommandLine", "str")
if !(A_IsAdmin || InStr(full_command_line, " /restart")) {
    try Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
    ExitApp
}

; 提权完成后，强杀仍在运行本脚本的其它 AutoHotkey 进程（含卡死的旧实例）
otherPids := GetOtherScriptPids()
for pid in otherPids
    RunWait("taskkill /f /pid " pid, , "Hide")
if otherPids.Length
    Sleep(300)  ; 等待进程完全退出、资源释放

; 安装键盘钩子（v2 用函数，非 v1 的 #InstallKeybdHook 指令）
; 配合 WindTerm 热键的 #UseHook / $ 前缀，在应用收到按键前抢先拦截
InstallKeybdHook()

; -----------------------------------------------------------------------------
; Caps Lock 重映射
; -----------------------------------------------------------------------------

; 阻止 Send 等操作意外改写 Caps Lock 的物理状态
SetStoreCapsLockMode False

; CapsLock2：区分「单独按下」与「作为组合键前缀按下」
;   1 = 可能是单按（300ms 内无其它键则确认）
;   0 = 已与其它键组合，或 300ms 定时器到期，不算单按
CapsLock2 := 1

; * 前缀：按住 Ctrl 时仍能触发（用于 Ctrl+Caps Lock 切换大小写）
*CapsLock::
{
    global CapsLock2
    ctrlHeld := GetKeyState("Ctrl", "P")

    ; 每次按下重置为「待确认单按」
    CapsLock2 := 1
    ; 300ms 后若未发生组合键，将 CapsLock2 置 0，单按逻辑不再执行
    SetTimer(clearCapsLock2, -300)

    ; 等待 Caps Lock 释放（阻塞直到松键）
    KeyWait("CapsLock")

    ; 定时器已触发 → 视为组合键场景，不做单按映射
    if !CapsLock2
        return

    ; Ctrl + Caps Lock：切换大小写锁定状态
    if ctrlHeld {
        SetCapsLockState(GetKeyState("CapsLock", "T") ? "Off" : "On")
        return
    }

    ; 单独 Caps Lock：先关掉 Caps 灯，再发送 Ctrl+Space 切换输入法
    SetCapsLockState("Off")
    Send("^{Space}")
}

; 300ms 犹豫时间到期：标记「不是单独按下 Caps Lock」
clearCapsLock2() {
    global CapsLock2
    CapsLock2 := 0
}

; -----------------------------------------------------------------------------
; WindTerm：Ctrl+Shift+Q 强杀并重启
; 仅在 WindTerm 为前台窗口时生效（#HotIf）
; -----------------------------------------------------------------------------

#HotIf isWindTermActive()
#UseHook              ; 强制键盘钩子，不用 RegisterHotKey，避免按键漏到 WindTerm
#InputLevel 1
$^+q::RestartWindTerm()  ; $ 前缀：钩子热键，拦截按键不向下传递
#InputLevel 0
#UseHook False
#HotIf

; 判断当前前台窗口是否属于 WindTerm 进程
isWindTermActive() {
    try
        return WinGetProcessName("A") = "WindTerm.exe"
    return false
}

; 从当前窗口进程读取路径 → 强杀 → 等待 → 同路径重启
RestartWindTerm() {
    try {
        hwnd := WinGetID("A")
        exePath := WinGetProcessPath(hwnd)   ; 自动获取安装路径，无需硬编码
        exeName := WinGetProcessName(hwnd)
        workDir := RegExReplace(exePath, "\\[^\\]+$", "")  ; exe 所在目录作工作目录
    } catch {
        MsgBox("无法获取 WindTerm 路径，重启失败。")
        return
    }

    RunWait("taskkill /f /im " exeName, , "Hide")  ; 强杀，释放串口等资源
    Sleep(500)

    if FileExist(exePath) {
        Run(exePath, workDir)
    } else {
        MsgBox("未找到 WindTerm 可执行文件：`n" exePath)
    }
}

; -----------------------------------------------------------------------------
; 工具函数
; -----------------------------------------------------------------------------

; 枚举本机 AutoHotkey 进程，返回命令行包含本脚本路径的其它 PID（不含当前进程）
GetOtherScriptPids() {
    pids := []
    myPid := DllCall("GetCurrentProcessId")
    script := StrLower(A_ScriptFullPath)
    try {
        for item in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name LIKE 'AutoHotkey%'") {
            if (item.ProcessId != myPid && InStr(StrLower(item.CommandLine), script))
                pids.Push(item.ProcessId)
        }
    }
    return pids
}

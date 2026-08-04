; Caps Lock 键位映射工具
; 参考 capslock-plus 实现
;
; 功能：
; - 单独按下 Caps Lock：切换输入法（Ctrl+Space）
; - Ctrl+Caps Lock：切换大小写
;
; 使用方法：
; 1. 安装 AutoHotkey v2 (https://www.autohotkey.com/)
; 2. 双击运行此文件
; 3. 脚本会在托盘区显示图标
; 4. 如需停止，右键托盘图标选择 Exit
;
; 注意：如果在某些软件中无效，请右键选择 "以管理员身份运行"

#Requires AutoHotkey v2.0
#SingleInstance Force

A_MaxHotkeysPerInterval := 500

; 自动请求管理员权限（使用 /restart 参数防止循环）
full_command_line := DllCall("GetCommandLine", "str")
if !(A_IsAdmin || InStr(full_command_line, " /restart")) {
    try Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
    ExitApp
}

SetStoreCapsLockMode False

CapsLock2 := 1

*CapsLock::
{
    global CapsLock2
    ctrlHeld := GetKeyState("Ctrl", "P")
    CapsLock2 := 1
    SetTimer(clearCapsLock2, -300)
    KeyWait("CapsLock")
    if !CapsLock2
        return
    if ctrlHeld {
        SetCapsLockState(GetKeyState("CapsLock", "T") ? "Off" : "On")
        return
    }
    SetCapsLockState("Off")
    Send("^{Space}")
}

clearCapsLock2() {
    global CapsLock2
    CapsLock2 := 0
}

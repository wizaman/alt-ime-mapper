; 左右 Alt キーの空打ちで IME の OFF/ON を切り替える

#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook() ; 直前のキー A_PriorKey を利用するため

; AHKがショートカットを処理する際に、Windowsが「Alt単体押し」と誤認しないためのマスクキー
A_MenuMaskKey := "vkE8"

; IMEの関数をまとめた最小構成の例 (v2専用)
class IME {
    /**
     * 現在フォーカスがあるコントロール、あるいはアクティブウィンドウのハンドルを返す
     * @returns {Ptr} 
     */
    static GetImeHandle() {
        dImeWnd := 0
        try {
            ; メモ帳などのモダンアプリ（UWP）対策：フォーカスされている子コントロールを優先
            hWnd := ControlGetFocus("A")
            if (hWnd) {
                dImeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hWnd, "Ptr")
            }
        }
        ; コントロールから取得できなかった場合、アクティブウィンドウで再試行
        if (!dImeWnd) {
            hWnd := WinExist("A")
            if (hWnd) {
                dImeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hWnd, "Ptr")
            }
        }
        return dImeWnd
    }

    ; IMEのON/OFF状態を取得
    static GetState() {
        dImeWnd := this.GetImeHandle()
        if !dImeWnd
            return 0
        ; WM_IME_CONTROL (0x283), IMC_GETOPENSTATUS (0x005)
        res := DllCall("user32\SendMessage", "Ptr", dImeWnd, "UInt", 0x283, "Ptr", 0x005, "Ptr", 0, "Ptr")
        return res
    }

    ; IMEをON(1)またはOFF(0)にする
    static SetState(state) {
        dImeWnd := this.GetImeHandle()
        if !dImeWnd
            return
        ; WM_IME_CONTROL (0x283), IMC_SETOPENSTATUS (0x006)
        DllCall("user32\SendMessage", "Ptr", dImeWnd, "UInt", 0x283, "Ptr", 0x006, "Ptr", state, "Ptr")
    }
}

; Alt単体押しによるメニューバーへのフォーカスをvkE8でブロック
~LAlt::Send "{Blind}{vkE8}"
~RAlt::Send "{Blind}{vkE8}"

; 左AltキーでIMEをOFFにする
~LAlt up:: {
    if (A_PriorKey == "LAlt") {
        IME.SetState(0) ; OFF
    }
}

; 右AltキーでIMEをONにする
~RAlt up:: {
    if (A_PriorKey == "RAlt") {
        IME.SetState(1) ; ON
    }
}

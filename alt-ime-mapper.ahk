; 左右 Alt キーの空打ちで IME の OFF/ON を切り替える

#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook() ; 直前のキー A_PriorKey を利用するため

; IME制御クラス
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

; Down 時は余計なことをせず、物理的な Alt Down だけをアプリに伝える
$LAlt::Send "{LAlt down}"
$RAlt::Send "{RAlt down}"

; 左AltキーでIMEをOFFにする
LAlt up:: {
    if (A_PriorKey == "LAlt") {
        ; Shiftキーを割り込んでメニューフォーカスを防止
        ; WPFアプリが仮想キーを処理しなかったため副作用が少ないShiftキーを採用している
        Send "{Blind}{LShift up}"

        IME.SetState(0) ; OFF
    }

    Send "{LAlt up}"
}

; 右AltキーでIMEをONにする
RAlt up:: {
    if (A_PriorKey == "RAlt") {
        ; Shiftキーを割り込んでメニューフォーカスを防止
        ; WPFアプリが仮想キーを処理しなかったため副作用が少ないShiftキーを採用している
        Send "{Blind}{RShift up}"

        IME.SetState(1) ; ON
    }

    Send "{RAlt up}"
}

package com.outo.app

import android.app.Activity
import android.os.Bundle
import com.outo.app.extensions.wrapAction

class TempActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        when (intent.action) {
            wrapAction("START") -> GlobalState.handleStart()
            wrapAction("STOP") -> GlobalState.handleStop()
            wrapAction("CHANGE") -> GlobalState.handleToggle()
        }
        finishAndRemoveTask()
    }
}

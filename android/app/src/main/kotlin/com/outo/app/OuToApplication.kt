package com.outo.app

import android.app.Application
import android.content.Context
import com.outo.app.common.GlobalState

class OuToApplication : Application() {
    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        GlobalState.init(this)
    }
}

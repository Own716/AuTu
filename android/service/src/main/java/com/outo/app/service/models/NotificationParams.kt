package com.outo.app.service.models

data class NotificationParams(
    val title: String = "AuTu",
    val stopText: String = "STOP",
    val onlyStatisticsProxy: Boolean = false,
    val showStopAction: Boolean = true,
)

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Dark Mode")
    statusText: MaterialThemeLoader.targetDark ? Translation.tr("Dark") : Translation.tr("Light")

    toggled: MaterialThemeLoader.targetDark
    icon: MaterialThemeLoader.targetDark ? "dark_mode" : "light_mode"
    
    mainAction: () => {
        MaterialThemeLoader.toggleLightDark();
    }

    tooltipText: Translation.tr("Dark Mode")
}

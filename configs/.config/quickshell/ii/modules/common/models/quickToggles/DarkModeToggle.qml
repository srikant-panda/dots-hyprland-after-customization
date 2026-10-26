import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Dark Mode")
    available: !MaterialThemeLoader.isSwitching
    statusText: MaterialThemeLoader.isSwitching ? Translation.tr("Switching...") : (MaterialThemeLoader.targetDark ? Translation.tr("Dark") : Translation.tr("Light"))

    toggled: MaterialThemeLoader.targetDark
    icon: MaterialThemeLoader.isSwitching ? "sync" : (MaterialThemeLoader.targetDark ? "dark_mode" : "light_mode")
    
    mainAction: () => {
        if (!MaterialThemeLoader.isSwitching) {
            MaterialThemeLoader.toggleLightDark();
        }
    }

    tooltipText: MaterialThemeLoader.isSwitching ? Translation.tr("Switching theme...") : Translation.tr("Dark Mode")
}

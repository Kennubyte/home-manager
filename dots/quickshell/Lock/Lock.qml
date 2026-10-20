pragma ComponentBehavior: Bound
import Quickshell.Wayland
import Quickshell.Io
import QtQuick.Controls
import QtQuick

Item {
    IpcHandler {
        target: "Locker"

        function lock() {
            sessionLock.locked = true
        }
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface{
            Image {
                source: "/home/ken/.config/quickshell/assets/Wallpaper"
                fillMode: Image.PreserveAspectCrop
                anchors.fill: parent
            }

            Button {
                anchors.centerIn: parent
                text: "Unlock"
                onClicked: sessionLock.locked = false
            }
        }
    }
}

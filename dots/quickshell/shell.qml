import QtQuick
import Quickshell
import "./Bar"
import "./Lock"

ShellRoot {
id: root

    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }

    Lock {}
}

import Quickshell
import QtQuick
import qs

Item {
    id: root

    height: Math.round(parent.height-8)
    implicitWidth: content.width + 16

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.primary

        Text {
            id: content
            anchors.centerIn: parent

            color: Colors.on_primary
            text: Qt.formatDateTime(clock.date, "hh:mm")
            font.pixelSize: 20
            font.family: "Geist"
        }
    }
}
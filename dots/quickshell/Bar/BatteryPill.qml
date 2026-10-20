import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.UPower
import qs

Item {
    id: root
    height: Math.round(parent.height-8)
    implicitWidth: 54

    // track
    property color bgColor: Colors.surface_container_highest
    property color bgTextColor: Colors.on_surface
    // normal
    property color fillColor: Colors.primary
    property color fillTextColor: Colors.on_primary
    // critical
    property color criticalColor: Colors.error
    property color criticalTextColor: Colors.on_error
    // charging
    property color chargingColor: Colors.tertiary
    property color chargingTextColor: Colors.on_tertiary

    property real level: (UPower.displayDevice.percentage * 100) * 1.25
    property real criticalLevel: 30
    property bool isCharging: UPower.displayDevice.state === UPowerDeviceState.Charging
    readonly property bool critical: level <= criticalLevel && !isCharging

    readonly property color activeColor: isCharging ? chargingColor
                                       : critical ? criticalColor
                                       : fillColor
    readonly property color activeTextColor: isCharging ? chargingTextColor
                                           : critical ? criticalTextColor
                                           : fillTextColor

    readonly property string label: `${isCharging ? "\udb85\udc0b" : ""}${Math.round(level)}`

    Rectangle {
        id: bg
        anchors.fill: parent
        color: root.bgColor
        radius: height / 2
        antialiasing: true
    }

    // text over the empty track
    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.bgTextColor
        font.pixelSize: 20
        font.family: "Geist"
    }

    // fill + its own copy of the text, masked to the pill
    Item {
        id: fillLayer
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        Rectangle {
            id: fill
            color: root.activeColor
            height: parent.height
            width: Math.round(parent.width * Math.min(root.level, 100) / 100)
            clip: true

            Behavior on color { ColorAnimation { duration: 200 } }

            Text {
                width: root.width
                height: root.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.label
                color: root.activeTextColor
                font.pixelSize: 20
                font.family: "Geist"

                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        anchors.margins: 0.5
        radius: height / 2
        antialiasing: true
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4
        visible: false
    }
}
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
  anchors {
    top: true
    left: true
    right: true
  }
  WlrLayershell.namespace: "qs-bar"

  color: "transparent"
  implicitHeight: 32

  // Background
  Rectangle {
    anchors.fill: parent
    color: "#0F0F0F"
    opacity: 0.25

    // Bottom border
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: "white"
    }
  }
  
  // Widgets
  RowLayout {
    anchors.centerIn: parent
    height: parent.height
    width: parent.width - 32

    ClockPill {
      Layout.alignment: Qt.AlignLeft
    }

    BatteryPill {
      Layout.alignment: Qt.AlignRight
    }
  }
}

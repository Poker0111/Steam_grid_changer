import QtQuick
import QtQuick.Controls

Window {
    id: progressRoot
    width: 450
    height: 180
    title: "Synchronizacja"
    color: "#1a1a1b"
    modality: Qt.ApplicationModal
    flags: Qt.Window | Qt.WindowTitleHint

    Column {
        anchors.centerIn: parent
        width: parent.width * 0.8
        spacing: 15

        Label {
            text: "Trwa skanowanie biblioteki Steam..."
            color: "white"
            font.pixelSize: 16
            anchors.horizontalCenter: parent.horizontalCenter
        }

        ProgressBar {
            id: control
            width: parent.width
            from: 0
            to: 1
            value: 0
            background: Rectangle {
                implicitHeight: 6
                color: "#333333"
                radius: 3
            }
            contentItem: Item {
                Rectangle {
                    width: control.visualPosition * parent.width
                    height: parent.height
                    color: "#1b92d1"
                    radius: 3
                }
            }

            Connections {
                target: steamGrid
                function onProgressChanged(p) {
                    control.value = p
                    if (p >= 1.0) closeTimer.start()
                }
            }

            Component.onCompleted: {
                if (control.value >= 1.0) closeTimer.start()
            }
        }

        Label {
            text: (control.value * 100).toFixed(0) + "%"
            color: "#888888"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Timer {
        id: closeTimer
        interval: 800
        onTriggered: progressRoot.close()
    }
}
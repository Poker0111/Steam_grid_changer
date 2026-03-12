import QtQuick
import QtQuick.Controls

Window {

    Theme { id: theme }

    id: progressRoot
    width: 375
    height: 150
    title: "Synchronizacja"
    color: theme.back_second
    modality: Qt.ApplicationModal
    flags: Qt.Window | Qt.WindowTitleHint | Qt.MSWindowsFixedSizeDialogHint

    

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
                implicitHeight: 8
                color: theme.frame
                radius: 3
            }
            contentItem: Item {
                Rectangle {
                    width: control.visualPosition * parent.width
                    height: parent.height
                    color: theme.border_cilick
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
            color: theme.font
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Timer {
        id: closeTimer
        interval: 800
        onTriggered: progressRoot.close()
    }
}
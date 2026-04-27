import QtQuick
import QtQuick.Controls

Window {
    id: progressRoot
    width: 375
    height: 150
    title: qsTr("Synchronizing")
    color: theme.back_second
    modality: Qt.ApplicationModal
    flags: Qt.Window | Qt.WindowTitleHint | Qt.MSWindowsFixedSizeDialogHint
    minimumWidth: width; maximumWidth: width
    minimumHeight: height; maximumHeight: height

    Theme { id: theme }
    Fonts { id: fonts }

    property var    messages:       []
    property int    _lastIndex:     -1
    property string currentMessage: ""

    function loadMessages() {
        var lang = steamGrid.currentLanguage
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            try {
                var data = JSON.parse(xhr.responseText)
                if (Array.isArray(data) && data.length > 0) {
                    messages = data
                    pickRandom()
                    return
                }
            } catch (e) {}
            messages = ["Loading..."]
            currentMessage = messages[0]
        }
        xhr.open("GET", "qrc:/SteamApp/resources/messages_" + lang + ".json")
        xhr.send()
    }

    function pickRandom() {
        if (messages.length === 0) return
        var idx
        do { idx = Math.floor(Math.random() * messages.length) }
        while (idx === _lastIndex && messages.length > 1)
        _lastIndex = idx
        currentMessage = messages[idx]
    }

    Component.onCompleted: {
        bar.value = 0
        loadMessages()
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: pickRandom()
    }

    Column {
        anchors.centerIn: parent
        width: parent.width * 0.8
        spacing: 15

        Label {
            id: messageLabel
            text: currentMessage
            color: "white"
            font.family: fonts.bold
            font.pixelSize: 14
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: messageLabel; property: "opacity"; to: 0; duration: 250 }
                    PropertyAction  { target: messageLabel; property: "text" }
                    NumberAnimation { target: messageLabel; property: "opacity"; to: 1; duration: 250 }
                }
            }
        }

        ProgressBar {
            id: bar
            width: parent.width
            from: 0; to: 1; value: 0

            background: Rectangle {
                implicitHeight: 8
                color: theme.frame
                radius: 3
            }

            contentItem: Item {
                Rectangle {
                    width: bar.visualPosition * parent.width
                    height: parent.height
                    color: theme.border_cilick
                    radius: 3
                    Rectangle {
                        anchors.fill: parent
                        color: "white"
                        opacity: 0.1
                        radius: 3
                    }
                }
            }

            Connections {
                target: steamGrid
                function onProgressChanged(p) {
                    bar.value = p
                    if (p >= 1.0) closeTimer.start()
                }
            }
        }

        Label {
            text: (bar.value * 100).toFixed(0) + "%"
            color: theme.font
            font.family: fonts.regular
            font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Timer {
        id: closeTimer
        interval: 1200
        onTriggered: progressRoot.close()
    }
}

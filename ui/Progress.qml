import QtQuick
import QtQuick.Controls

Window {
    id: progressRoot
    width: 375
    height: 150
    title: "Synchronizacja"
    color: theme.back_second
    modality: Qt.ApplicationModal
    
    flags: Qt.Window | Qt.WindowTitleHint | Qt.MSWindowsFixedSizeDialogHint
    minimumWidth: width
    maximumWidth: width
    minimumHeight: height
    maximumHeight: height

    Theme { id: theme }
    Fonts { id: styleFonts } 

    property var loadingMessages: [] 
    property string currentMessage: "Inicjalizacja..."

    function loadMessages() {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        if (Array.isArray(data)) {
                            loadingMessages = data;
                            pickRandomMessage();
                        }
                    } catch (e) {
                    }
                } 
            } 
        }
        xhr.open("GET", "qrc:/SteamApp/resources/messages.json");  
        xhr.send();
    }

    function pickRandomMessage() {
        if (loadingMessages.length > 1) {
            var index = Math.floor(Math.random() * loadingMessages.length);
            var newMessage = loadingMessages[index];
            if (newMessage === currentMessage) {
                pickRandomMessage(); 
            } else {
                currentMessage = newMessage;
            }
        } else if (loadingMessages.length === 1) {
            currentMessage = loadingMessages[0];
        }
    }

    Component.onCompleted: loadMessages()

    Timer {
        id: messageTimer
        interval: 3000 
        running: true
        repeat: true
        onTriggered: pickRandomMessage()
    }

    Column {
        anchors.centerIn: parent
        width: parent.width * 0.8
        spacing: 15

        Label {
            id: messageLabel
            text: currentMessage
            color: "white"
            font.family: styleFonts.bold
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: parent.width

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: messageLabel; property: "opacity"; to: 0; duration: 250 }
                    PropertyAction { target: messageLabel; property: "text" }
                    NumberAnimation { target: messageLabel; property: "opacity"; to: 1; duration: 250 }
                }
            }
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
                    control.value = p
                    if (p >= 1.0) closeTimer.start()
                }
            }
        }

        Label {
            text: (control.value * 100).toFixed(0) + "%"
            color: theme.font
            font.family: styleFonts.regular
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
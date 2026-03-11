import QtQuick
import QtQuick.Controls

Window {
    id: settingsRoot
    width: 450
    height: 350
    title: "Ustawienia"
    color: "#1a1a1b"
    modality: Qt.ApplicationModal

    Column {
        anchors.centerIn: parent
        spacing: 20
        width: parent.width * 0.8

        Label {
            text: "Konfiguracja SteamGrid"
            font.pixelSize: 20
            color: "white"
        }

        Column {
            width: parent.width
            spacing: 5
            Label { text: "API Key:"; color: "#afafaf" }
            TextField {
                id: apiKeyField
                width: parent.width
                text: steamGrid.apiKey
                selectByMouse: true
            }
        }

        Column {
            width: parent.width
            spacing: 5
            Label { text: "Ścieżka:"; color: "#afafaf" }
            TextField {
                id: pathField
                width: parent.width
                text: steamGrid.path
                selectByMouse: true
            }
        }

        Row {
            width: parent.width
            spacing: 10
            CsButton {
                btnText: "Anuluj"
                width: (parent.width - 10) / 2
                height: 48
                onClicked: settingsRoot.close()
            }
            CsButton {
                btnText: "Zapisz"
                width: (parent.width - 10) / 2
                height: 48
                onClicked: {
                    steamGrid.saveConfiguration(apiKeyField.text, pathField.text)
                    var comp = Qt.createComponent("Progress.qml")
                    if (comp.status === Component.Ready) {
                        comp.createObject(root).show()
                    }
                    settingsRoot.close()
                }
            }
        }
    }
}
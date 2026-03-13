import QtQuick
import QtQuick.Controls

Window {
    id: settingsRoot
    required property var themes
    width: 600
    height: 350
    minimumWidth: 400
    minimumHeight: 300
    title: "Ustawienia"
    color: themes.back_second
    modality: Qt.ApplicationModal

    Fonts { id: styleFonts }

    Column {
        anchors.centerIn: parent
        spacing: 20
        width: parent.width * 0.8

        Label {
    text: "Konfiguracja SteamGrid"
    font.family: styleFonts.bold
    font.pixelSize: 24 
    color: themes.font_click
    
    }

        Column {
            width: parent.width
            spacing: 5
            Label {
    text: "API Key:"
    font.family: styleFonts.regular
    font.pixelSize: 13 
    font.weight: Font.Medium
    color: themes.font // Nieco jaśniejszy szary niż #afafaf
    
    
    }
            TextField {
                id: apiKeyField
                width: parent.width
                text: steamGrid.apiKey
                selectByMouse: true
                height:35

                font.pixelSize: 14
                leftPadding: 10
                color: apiKeyField.activeFocus ? themes.font_click : themes.font

                background:Rectangle{
                    color: themes.textfield_c
                    radius:3
                    border.color: apiKeyField.activeFocus ? themes.font_hover : themes.border
                    border.width: 1
                }
                
            }
        }

        Column {
            width: parent.width
            spacing: 5
            Label {
    text: "Ścieżka:"
    font.family: styleFonts.regular
    font.pixelSize: 13
    font.weight: Font.Medium
    color: themes.font 
    
    
}
            TextField {
                id: pathField
                width: parent.width
                text: steamGrid.path
                selectByMouse: true
                height:35

                font.pixelSize: 14
                leftPadding: 10
                color: pathField.activeFocus ? themes.font_click : themes.font

                background:Rectangle{
                    color: themes.textfield_c
                    radius:3
                    border.color: pathField.activeFocus ? themes.font_hover : themes.border
                    border.width: 1
                }
                
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

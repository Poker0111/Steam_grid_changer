import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Window {
    id: root
    required property var themes

    width: 600
    height: 400
    minimumWidth: 400
    minimumHeight: 350
    title: qsTr("Settings")
    color: themes.back_second
    modality: Qt.ApplicationModal

    Fonts { id: fonts }

    FolderDialog{
        id:dialog
        title: qsTr("Chose Steam path")
        currentFolder:"file:///" + pathField.text
        onAccepted:{
            var path = selectedFolder.toString()
            path = path.replace("file:///", "")
            path = path.replace(/\//g, "\\")
            pathField.text = path
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 20
        width: parent.width * 0.8

        Label {
            text: qsTr("Settings")
            font.family: fonts.bold
            font.pixelSize: 24
            color: themes.font_click
        }

        Column {
            width: parent.width
            spacing: 5

            Label {
                text: qsTr("API Key")
                font.family: fonts.regular
                font.pixelSize: 13
                font.weight: Font.Medium
                color: "white"
            }

            TextField {
                id: apiKeyField
                width: parent.width
                height: 35
                text: steamGrid.apiKey
                selectByMouse: true
                font.pixelSize: 14
                leftPadding: 10
                color: activeFocus ? themes.font_click : themes.font
                background: Rectangle {
                    color: themes.textfield_c
                    radius: 3
                    border.width: 1
                    border.color: apiKeyField.activeFocus ? themes.font_hover : themes.border
                }
            }

            Label {
                text: qsTr("Get API key from steamgriddb.com → Preferences → API")
                font.family: fonts.regular
                font.pixelSize: 12
                color: themes.font
            }
        }

        Column {
            width: parent.width
            spacing: 5

            Label {
                text: qsTr("Steam Path")
                font.family: fonts.regular
                font.pixelSize: 13
                font.weight: Font.Medium
                color: "white"
            }

        RowLayout{
            width: parent.width
            spacing: 10

            TextField {
                id: pathField
                Layout.fillWidth: true
                height: 35
                text: steamGrid.path
                selectByMouse: true
                font.pixelSize: 14
                leftPadding: 10
                color: activeFocus ? themes.font_click : themes.font
                background: Rectangle {
                    color: themes.textfield_c
                    radius: 3
                    border.width: 1
                    border.color: pathField.activeFocus ? themes.font_hover : themes.border
                }
            }

            CsButton{
                Layout.preferredWidth: 35
                Layout.preferredHeight: 35
                onClicked: dialog.open()
            }
        }

            Label {
                text: qsTr("Example: C:\\Steam\\userdata\\USER_ID\\config")
                font.family: fonts.regular
                font.pixelSize: 12
                color: themes.font
            }
        }

        Row {
            width: parent.width
            spacing: 10

            Label {
                text: qsTr("Language")
                font.family: fonts.regular
                font.pixelSize: 13
                font.weight: Font.Medium
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }

            ComboBox {
                id: langCombo
                width: 160
                height: 35
                model: [
                    { text: "Polski",  code: "pl" },
                    { text: "English", code: "en" },
                    { text: "日本語",  code: "ja" }
                ]
                textRole: "text"

                Component.onCompleted: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].code === steamGrid.currentLanguage) {
                            currentIndex = i
                            break
                        }
                    }
                }

                background: Rectangle {
                    color: langCombo.down ? themes.button_click2
                         : langCombo.hovered ? themes.button_hover2
                         : themes.button2
                    radius: 2
                    border.width: 1
                    border.color: themes.frame
                }

                contentItem: Text {
                    leftPadding: 12
                    text: langCombo.displayText
                    font.pixelSize: 13
                    color: themes.font_hover
                    verticalAlignment: Text.AlignVCenter
                }

                delegate: ItemDelegate {
                    width: langCombo.width
                    background: Rectangle {
                        color: hovered ? themes.button_hover2 : themes.button2
                        border.color: themes.border
                        border.width: 1
                    }
                    contentItem: Text {
                        text: modelData.text
                        color: hovered ? "white" : themes.font
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 10

            CsButton {
                btnText: qsTr("Cancel")
                width: (parent.width - 10) / 2
                height: 48
                onClicked: root.close()
            }

            CsButton {
                btnText: qsTr("Save")
                width: (parent.width - 10) / 2
                height: 48
                onClicked: {
                    var selectedCode = langCombo.model[langCombo.currentIndex].code
                    steamGrid.setLanguage(selectedCode)
                    steamGrid.saveConfiguration(apiKeyField.text, pathField.text)
                    root.close()
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 900
    height: 600
    minimumWidth: 650
    minimumHeight: 400
    visible: true
    title: qsTr("SteamUI")

    Theme { id: theme }
    Fonts{id: fonts}

    background: Rectangle { color: theme.back }

    ListModel {
        id: types
        ListElement { key: "Grids" }
        ListElement { key: "Heroes" }
        ListElement { key: "Logos" }
        ListElement { key: "Icons" }
    }

    ListModel {
        id: allGamesModel
    }

    function updateModel() {
        allGamesModel.clear();
        var data = steamGrid.gamesModel; 
        for (var i = 0; i < data.length; i++) {
            allGamesModel.append(data[i]);
        }
    }

    Connections {
        target: steamGrid
        function onGamesModelChanged() {
            updateModel();
        }
        function onCacheExistsChanged() {
            //if (steamGrid.cacheExists) {
          //  }
        }
    }

    Component.onCompleted: {
        updateModel();
        steamGrid.init(); 
        if (!steamGrid.cacheExists) {
            settingsDialog.show();
        }
    }

    Settings {
        id: settingsDialog
        themes: theme
    }

    ListModel { id: suggestionsModel }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: searchrec
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            color: theme.back_second
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 15

                CsButton {
                    btnText: "Settings"
                    Layout.preferredWidth: 70
                    onClicked: settingsDialog.show()
                }

                CsButton { 
                    btnText: "Reload Library"
                    Layout.preferredWidth: 110
                    onClicked: {
                        var comp = Qt.createComponent("Progress.qml")
                        if (comp.status === Component.Ready) comp.createObject(root).show()
                        steamGrid.reload()
                    }
                }

                TextField {
                    id: field
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    placeholderText: "Search"
                    color: "white"
                    font.pixelSize: 14
                    placeholderTextColor: theme.font
                    leftPadding: 15
                    verticalAlignment: TextInput.AlignVCenter

                    background: Rectangle {
                        color: field.activeFocus ? theme.button_click : (field.hovered ? theme.button_hover : theme.button)
                        radius: 4
                        border.width: 1.5
                        border.color: field.activeFocus ? theme.border_cilick : (field.hovered ? theme.border_hoverd : theme.border)
                    }

                    onTextEdited: {
                        suggestionsModel.clear()
                        if (text.length > 0) {
                            for (var i = 0; i < allGamesModel.count; i++) {
                                var gameName = allGamesModel.get(i).title
                                if (gameName.toLowerCase().indexOf(text.toLowerCase()) !== -1) {
                                    suggestionsModel.append({ "title": gameName })
                                }
                            }
                        }
                        if (suggestionsModel.count > 0) suggestionsPopup.open()
                        else suggestionsPopup.close()
                    }

                    Popup {
                        id: suggestionsPopup
                        y: field.height + 2
                        width: field.width
                        padding: 1
                        focus: false
                        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
                        clip: true

                        // Animacja wejścia (Enter)
                        enter: Transition {
                            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150 }
                            NumberAnimation { property: "y"; from: field.height - 5; to: field.height + 2; duration: 150 }
                        }

                        background: Rectangle {
                            color: theme.back_second
                            border.width: 2
                            border.color: theme.border
                            radius: 4
                        }

                        contentItem: ListView {
                            id: listView
                            implicitHeight: Math.min(contentHeight, 200)
                            model: suggestionsModel
                            clip: true
                            
                            delegate: ItemDelegate {
                                width: listView.width
                                height: 35
                                background: Rectangle {
                                    color: hovered ? theme.button_hover : "transparent"
                                }
                                contentItem: Text {
                                    text: model.title
                                    color: hovered ? "white" : theme.font
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                    font.bold: true
                                }
                                onClicked: {
                                    field.text = model.title
                                    suggestionsPopup.close()
                                }
                            }

                            ScrollBar.vertical: ScrollBar {
                                id: scrollBar
                                policy: ScrollBar.AsNeeded
                                width: 12
                                background: Rectangle { color: "transparent" }
                                contentItem: Rectangle {
                                    implicitWidth: 6
                                    radius: 3
                                    color: theme.font 
                                    opacity: scrollBar.active ? (scrollBar.hovered || scrollBar.pressed ? 0.6 : 0.3) : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                }
                            }
                        }
                    }
                }

                ComboBox {
                    id: type
                    Layout.preferredWidth: 100 
                    Layout.preferredHeight: 32
                    hoverEnabled: true
                    model: types
                    textRole: "key"

                    background: Rectangle {
                        color: type.down ? theme.button_click2 : (type.hovered ? theme.button_hover2 : theme.button2)
                        radius: 2
                        border.width: 1
                        border.color: theme.frame
                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                    }

                    contentItem: Text {
                        leftPadding: 12
                        text: type.displayText
                        font.pixelSize: 13
                        font.bold: true
                        color: type.down ? theme.font_click : (type.hovered ? theme.font_hover : theme.font)
                        verticalAlignment: Text.AlignVCenter
                    }

                    delegate: ItemDelegate {
                        id: comboDelegate
                        width: type.width
                        highlighted: type.highlightedIndex === index
                        background: Rectangle {
                            color: hovered ? theme.button_hover2 : theme.button2
                            radius: 1
                            border.width: 1
                            border.color: theme.border
                        }
                        contentItem: Text {
                            text: model.key
                            color: comboDelegate.highlighted || comboDelegate.hovered ? "white" : theme.font
                            font.pixelSize: 13
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        Rectangle {
            id: coversArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: theme.back
            
        RowLayout{
            spacing:10
            /*test
            CsComponent{
                id:combo
                type: "grid"
                imageSource:"https://cdn2.steamgriddb.com/grid/e8a68217f2c512a63bac2f9244d9c1b5.png"
                }
                CsComponent{
                id:combo1
                type: "heroes"
                imageSource:"https://cdn2.steamgriddb.com/hero/09a824a09b7734ea1cfd2f9a34dedbfd.jpg"
                }
                CsComponent{
                id:combo2
                type: "icons"
                imageSource:"https://cdn2.steamgriddb.com/icon/6374e3ddc6da019b8d63d803662c47e7.png"
                }
                CsComponent{
                id:combo3
                type: "logos"
                imageSource:"https://cdn2.steamgriddb.com/logo/2b2e7393b05b5b52af65bf2ed7f4ad4f.png"
                }*/
                CsComponent{
                    id:combo4
                    type:"grid"
                    imageSource:"https://cdn2.steamgriddb.com/grid/51f993d243a0d38e4669ac0bc3f8df05.webp"
                }
            }
        }
    }
}
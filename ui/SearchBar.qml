import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: theme.back_second

    signal searchRequested(string gameId, string gameTitle, string imageType)
    signal settingsRequested()
    signal reloadRequested()

    property alias currentType: typeCombo.currentText

    function refreshSuggestions(text) {
        suggestionsModel.clear()
        if (text.length === 0) { suggestionsPopup.close(); return }
        for (var i = 0; i < allGamesModel.count; i++) {
            var g = allGamesModel.get(i)
            if (g.title.toLowerCase().indexOf(text.toLowerCase()) !== -1)
                suggestionsModel.append({ id: g.id, title: g.title })
        }
        suggestionsModel.count > 0 ? suggestionsPopup.open() : suggestionsPopup.close()
    }

    function triggerSearch(gameId, gameTitle) {
        suggestionsPopup.close()
        root.searchRequested(gameId, gameTitle, typeCombo.currentText)
    }

    ListModel { id: suggestionsModel }

    property string _lastId: ""
    property string _lastTitle: ""

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 15

        CsButton {
            iconSource: "qrc:/SteamApp/resources/set.svg"
            Layout.preferredWidth: 35
            Layout.preferredHeight: 35
            onClicked: root.settingsRequested()
        }

        CsButton {
            btnText: qsTr("Reload Library")
            Layout.preferredWidth: 110
            Layout.preferredHeight: 35
            onClicked: root.reloadRequested()
        }

        TextField {
            id: searchField
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            placeholderText: qsTr("Search")
            color: "white"
            font.pixelSize: 14
            placeholderTextColor: theme.font
            leftPadding: 15
            rightPadding: 45
            verticalAlignment: TextInput.AlignVCenter

            background: Rectangle {
                color: searchField.activeFocus ? theme.button_click : (searchField.hovered ? theme.button_hover : theme.button)
                radius: 4
                border.width: 1.5
                border.color: searchField.activeFocus ? theme.border_cilick : (searchField.hovered ? theme.border_hoverd : theme.border)
            }

            onTextEdited: root.refreshSuggestions(text)

            Keys.onReturnPressed: {
                for (var i = 0; i < suggestionsModel.count; i++) {
                    if (suggestionsModel.get(i).title.toLowerCase() === text.toLowerCase()) {
                        root.triggerSearch(suggestionsModel.get(i).id, suggestionsModel.get(i).title)
                        return
                    }
                }
                if (suggestionsModel.count > 0)
                    root.triggerSearch(suggestionsModel.get(0).id, suggestionsModel.get(0).title)
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                width: height
                color: theme.border_cilick
                radius: 3

                Image {
                    source: "qrc:/SteamApp/resources/loop.svg"
                    anchors.centerIn: parent
                    width: parent.width - 16
                    height: parent.height - 16
                    fillMode: Image.PreserveAspectFit
                    scale: loopMouse.containsMouse ? 1.25 : 1.0
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                }

                MouseArea {
                    id: loopMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        for (var i = 0; i < suggestionsModel.count; i++) {
                            if (suggestionsModel.get(i).title === searchField.text) {
                                root.triggerSearch(suggestionsModel.get(i).id, suggestionsModel.get(i).title)
                                return
                            }
                        }
                        if (suggestionsModel.count > 0)
                            root.triggerSearch(suggestionsModel.get(0).id, suggestionsModel.get(0).title)
                    }
                }
            }

            Popup {
                id: suggestionsPopup
                y: searchField.height + 2
                width: searchField.width
                padding: 1
                focus: false
                closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
                clip: true

                enter: Transition {
                    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150 }
                    NumberAnimation { property: "y"; from: searchField.height - 5; to: searchField.height + 2; duration: 150 }
                }

                background: Rectangle {
                    color: theme.back_second
                    border.width: 2
                    border.color: theme.border
                    radius: 4
                }

                contentItem: ListView {
                    id: suggList
                    implicitHeight: Math.min(contentHeight, 200)
                    model: suggestionsModel
                    clip: true

                    delegate: ItemDelegate {
                        width: suggList.width
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
                            searchField.text = model.title
                            root.triggerSearch(model.id, model.title)
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
            id: typeCombo
            Layout.preferredWidth: 100
            Layout.preferredHeight: 32
            hoverEnabled: true
            model: ["Grids", "Heroes", "Logos", "Icons"]

            onCurrentTextChanged: {
                if (root._lastId !== "")
                    root.searchRequested(root._lastId, root._lastTitle, currentText)
            }

            background: Rectangle {
                color: typeCombo.down ? theme.button_click2 : (typeCombo.hovered ? theme.button_hover2 : theme.button2)
                radius: 2
                border.width: 1
                border.color: theme.frame
                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
            }

            contentItem: Text {
                leftPadding: 12
                text: typeCombo.displayText
                font.pixelSize: 13
                font.bold: true
                color: typeCombo.down ? theme.font_click : (typeCombo.hovered ? theme.font_hover : theme.font)
                verticalAlignment: Text.AlignVCenter
            }

            delegate: ItemDelegate {
                id: comboDelegate
                width: typeCombo.width
                highlighted: typeCombo.highlightedIndex === index
                background: Rectangle {
                    color: hovered ? theme.button_hover2 : theme.button2
                    radius: 1
                    border.width: 1
                    border.color: theme.border
                }
                contentItem: Text {
                    text: modelData
                    color: comboDelegate.highlighted || comboDelegate.hovered ? "white" : theme.font
                    font.pixelSize: 13
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}

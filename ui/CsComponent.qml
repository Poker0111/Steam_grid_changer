import QtQuick
import QtQuick.Controls

Item {
    id: root

    property url    imageSource: ""
    property string btnText:     qsTr("DOWNLOAD")
    property string type:        "Grids"

    signal downloadClicked()

    Theme { id: theme }

    readonly property int imageAreaHeight: {
        if (type === "Grids")  return Math.round(width * 1.4)
        if (type === "Heroes") return Math.round(width * 0.5)
        if (type === "Icons")  return width
        if (type === "Logos")  return 130
        return width
    }

    Rectangle {
        id: cardBody
        anchors.fill: parent
        color: theme.textfield_c
        radius: 6
        border.width: 2
        border.color: hoverHandler.hovered ? theme.border_cilick : theme.textfield_c

        HoverHandler { id: hoverHandler }

        scale: hoverHandler.hovered ? 1.02 : 1.0
        Behavior on scale { NumberAnimation { duration: 150 } }

        Column {
            width: parent.width
            spacing: 0

            Rectangle {
                width: parent.width
                height: root.imageAreaHeight
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: type === "Logos" ? 8 : 12
                    color: type === "Icons" ? "#000000" : "transparent"
                    radius: 4
                    border.color: type === "Logos" ? "transparent" : theme.frame
                    border.width: 2
                    clip: true

                    BusyIndicator {
                        anchors.centerIn: parent
                        running: coverImage.status === Image.Loading
                        visible: running
                        scale: 0.6
                    }

                    AnimatedImage {
                        id: coverImage
                        anchors.fill: parent
                        source: root.imageSource
                        fillMode: (type === "Logos" || type === "Icons")
                                  ? Image.PreserveAspectFit
                                  : Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        playing: hoverHandler.hovered
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 52
                color: "transparent"

                CsButton {
                    width: parent.width - 20
                    height: 34
                    anchors.centerIn: parent
                    btnText: root.btnText
                    onClicked: root.downloadClicked()
                }
            }
        }
    }
}

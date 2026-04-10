import QtQuick
import QtQuick.Controls

Item {
    id: root

    property url   imageSource: ""
    property string btnText:    qsTr("DOWNLOAD")
    property string type:       "Grids"

    signal downloadClicked()

    Theme { id: theme }

    Rectangle {
        id: cardBody
        anchors.fill: parent
        color: theme.textfield_c
        radius: 6
        border.color: hoverHandler.hovered ? theme.border_cilick : theme.textfield_c
        border.width: 2

        HoverHandler { id: hoverHandler }

        scale: hoverHandler.hovered ? 1.02 : 1.0
        Behavior on scale { NumberAnimation { duration: 150 } }

        Column {
            id: mainColumn
            width: parent.width
            spacing: 0

            Rectangle {
                id: imageArea
                width: parent.width
                height: {
                    if (root.type === "Grids")  return width * 1.4
                    if (root.type === "Heroes") return width * 0.5
                    if (root.type === "Icons")  return width
                    if (root.type === "Logos") {
                        return coverImage.status === Image.Ready
                            ? Math.min(width * (coverImage.implicitHeight / coverImage.implicitWidth), 150)
                            : 100
                    }
                    return width
                }
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: root.type === "Logos" ? 5 : 12
                    color: root.type === "Icons" ? "#000000" : "transparent"
                    radius: 4
                    border.color: root.type === "Logos" ? "transparent" : theme.frame
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
                        fillMode: (root.type === "Logos" || root.type === "Icons")
                                  ? Image.PreserveAspectFit
                                  : Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        playing: hoverHandler.hovered
                        paused:  !hoverHandler.hovered
                    }
                }
            }


            Rectangle {
                width: parent.width
                height: 52
                color: "transparent"

                CsButton {
                    id: downloadBtn
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

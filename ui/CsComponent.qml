import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: {
        if (type === "Heroes") return 360;
        if (type === "Icons") return 160;
        if (type === "Logos") return 300;
        return 200; // grid
    }
    height: mainColumn.height

    property alias imageSource: coverImage.source
    property alias btnText: download.btnText
    property string type: "Grids" // "grid", "heroes", "icons", "logos"

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
                width: parent.width
                // POPRAWIONA LOGIKA WYSOKOŚCI:
                height: {
                    if (root.type === "Grids") return width * 1.4;
                    if (root.type === "Heroes") return width * 0.5;
                    if (root.type === "Icons") return width;
                    if (root.type === "Logos") {
                        return coverImage.status === Image.Ready 
                            ? Math.min(width * (coverImage.implicitHeight / coverImage.implicitWidth), 150)
                            : 100;
                    }
                    return width;
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

                    AnimatedImage {
                        id: coverImage
                        anchors.fill: parent
                        fillMode: (root.type === "Logos" || root.type === "Icons") 
                                  ? Image.PreserveAspectFit 
                                  : Image.PreserveAspectCrop
                        asynchronous: true
                        
                        playing: hoverHandler.hovered
                        currentFrame: playing ? currentFrame : 0 
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 60
                color: "transparent"

                CsButton {
                    id: download
                    width: parent.width - 24
                    height: 36
                    anchors.centerIn: parent
                    btnText: "DOWNLOAD"
                }
            }
        }
    }
}
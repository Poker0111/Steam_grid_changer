import QtQuick
import QtQuick.Controls

Item {
    id: root
    width: {
        if (type === "heroes") return 360;
        if (type === "icons") return 160;
        if (type === "logos") return 300;
        return 200; // grid
    }
    height: mainColumn.height

    property alias imageSource: coverImage.source
    property alias btnText: download.btnText
    property string type: "grid" // "grid", "heroes", "icons", "logos"

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
                    if (root.type === "grid") return width * 1.4;
                    if (root.type === "heroes") return width * 0.5;
                    if (root.type === "icons") return width;
                    if (root.type === "logos") {
                        return coverImage.status === Image.Ready 
                            ? Math.min(width * (coverImage.implicitHeight / coverImage.implicitWidth), 150)
                            : 100;
                    }
                    return width;
                }
                color: "transparent"
                
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: root.type === "logos" ? 5 : 12 // Mniejszy margines dla logos
                    color: root.type === "icons" ? "#000000" : "transparent" // Logos nie potrzebują czarnego tła
                    radius: 4
                    border.color: root.type === "logos" ? "transparent" : theme.frame
                    border.width: 2
                    clip: true

                    AnimatedImage {
                        id: coverImage
                        anchors.fill: parent
                        fillMode: (root.type === "logos" || root.type === "icons") 
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: control

    property string btnText: ""
    property url iconSource: ""

    property color colorNormal: theme.button2
    property color colorHover: theme.button_hover2
    property color colorClick: theme.button_click2

    property color textNormal: theme.font
    property color textHover: theme.font_hover
    property color textClick: theme.font_click

    Layout.preferredHeight: 32
    hoverEnabled: true

    background: Rectangle {
        color: control.pressed ? control.colorClick :
               (control.hovered ? control.colorHover : control.colorNormal)
        radius: 3
        border.color: theme.frame
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
    }

    contentItem: Item {
        
        Row {
            anchors.centerIn: parent
            spacing: 8
            height: parent.height

            Image {
                source: control.iconSource
                visible: control.iconSource.toString() !== ""
                
                height: control.height - 14
                width: height
                
                fillMode: Image.PreserveAspectFit
                anchors.verticalCenter: parent.verticalCenter
                opacity: control.pressed ? 0.7 : 1.0
            }

            Text {
                text: control.btnText
                visible: text !== ""
                color: control.pressed ? control.textClick :
                       (control.hovered ? control.textHover : control.textNormal)
                font.pixelSize: 13
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }
}
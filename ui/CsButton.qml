import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: control

    // Właściwości tekstu
    property string btnText: "Button"

    // Właściwości kolorów tła (przypisujemy domyślnie kolory z Twojego motywu)
    property color colorNormal: theme.button2
    property color colorHover: theme.button_hover2
    property color colorClick: theme.button_click2

    // Właściwości kolorów tekstu
    property color textNormal: theme.font
    property color textHover: theme.font_hover
    property color textClick: theme.font_click

    Layout.preferredHeight: 32
    hoverEnabled: true

    background: Rectangle {
        // Logika zmiany koloru tła
        color: control.pressed ? control.colorClick :
               (control.hovered ? control.colorHover : control.colorNormal)

        radius: 3
        border.color: theme.frame

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }

    contentItem: Text {
        text: control.btnText
        // Logika zmiany koloru tekstu
        color: control.pressed ? control.textClick :
               (control.hovered ? control.textHover : control.textNormal)

        font.pixelSize: 13
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        // Płynne przejście koloru tekstu też wygląda super
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}

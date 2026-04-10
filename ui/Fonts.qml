import QtQuick

QtObject {
    property FontLoader _regular: FontLoader { source: "qrc:/SteamApp/fonts/Inter.ttf" }
    property FontLoader _bold:    FontLoader { source: "qrc:/SteamApp/fonts/Inter-Bold.ttf" }

    readonly property string regular: _regular.status === FontLoader.Ready ? _regular.name : "Segoe UI"
    readonly property string bold:    _bold.status    === FontLoader.Ready ? _bold.name    : "Segoe UI"
}

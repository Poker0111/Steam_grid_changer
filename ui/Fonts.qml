import QtQuick

QtObject {
    id: fonts // Zmieniłem id na małe 'f', żeby nie myliło się z typem

    property FontLoader mainFontLoader: FontLoader {
        source: "qrc:/SteamApp/fonts/Inter.ttf"
    }
    property FontLoader boldFontLoader: FontLoader {
        source: "qrc:/SteamApp/fonts/Inter-Bold.ttf"
    }

    // POPRAWKA: Nazwy muszą się zgadzać z tymi powyżej!
    readonly property string regular: mainFontLoader.status === mainFontLoader.name
    readonly property string bold: boldFontLoader.status === boldFontLoader.name
}

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
    Fonts { id: fonts  }

    background: Rectangle { color: theme.back }

    ListModel { id: allGamesModel }

    function updateModel() {
        allGamesModel.clear()
        var data = steamGrid.gamesModel
        for (var i = 0; i < data.length; i++) allGamesModel.append(data[i])
    }

    function showProgress() {
        var comp = Qt.createComponent("Progress.qml")
        if (comp.status === Component.Ready) comp.createObject(root).show()
    }

    Connections {
        target: steamGrid
        function onGamesModelChanged() { updateModel() }
    }

    Component.onCompleted: {
        updateModel()
        if (!steamGrid.cacheExists) settingsDialog.show()
    }

    Settings { id: settingsDialog; themes: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        SearchBar {
            id: searchBar
            Layout.fillWidth: true
            Layout.preferredHeight: 70

            onSettingsRequested: settingsDialog.show()
            onReloadRequested:   { showProgress(); steamGrid.reload() }

            onSearchRequested: function(gameId, gameTitle, imageType) {
                searchBar._lastId    = gameId
                searchBar._lastTitle = gameTitle
                resultsGrid.steamAppId  = gameId      // ← przekaż do grida
                resultsGrid.imageType   = imageType
                steamGrid.searchImages(gameId, imageType)
            }
        }

        ResultsGrid {
            id: resultsGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            imageType:  searchBar.currentType
            steamAppId: ""   // wypełniane przez onSearchRequested
        }
    }
}

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.webcat.FolderListModel 1.0
import Nemo.Configuration 1.0
import "fmComponents"

Page {
    id: page
    allowedOrientations: Orientation.All

    property bool multiSelect: onlyFolders ? true : false
    property bool selectMode: false
    property bool onlyFolders: false
    property bool hiddenShow: false
    property string path:  _fm.getHome()
    property variant filter: [ "*" ]

    // Sorting
    property string sortType: qsTr("Name")
    property int _sortField: FolderListModel.Name
    //

    property bool _loaded: false

    property QtObject dataContainer

    signal fileOpen(string path);

   property var customPlaces: [
//       {
//           name: qsTr("Android Storage"),
//           path: _fm.getHome() + "/android_storage",
//           icon: "image://theme/icon-m-folder"
//       }
   ]


    ConfigurationGroup {
        id: customPlacesSettings
        path: "/apps/harbour-llsfileman" // DO NOT CHANGE to share custom places between apps
    }

    onCustomPlacesChanged: {
        saveCustomPlaces();
    }

    onPathChanged: {
        openFile(path);
    }

    onStatusChanged: {
        if (status == PageStatus.Active && !_loaded) {
            pageStack.pushAttached(Qt.resolvedUrl("fmComponents/PlacesPage.qml"),
                                   { "father": page })
            _loaded = true
        }
    }

    function openFile(path) {
        if (_fm.isFile(path)) {

            var mime = _fm.getMime(path);
            console.debug("[OpenDialog] Detected mimetype: " + mime);
            var mimeinfo = mime.toString().split("/");

            if(mimeinfo[0] === "video" || mimeinfo[0] === "audio")
            {
                mainWindow.openWithvPlayer(path,"");
                if (mainWindow.vPlayerExternal) {
                    mainWindow.infoBanner.parent = page
                    mainWindow.infoBanner.anchors.top = page.top
                    mainWindow.infoBanner.showText(qsTr("Opening..."))
                }
                return;
            }
            else if ((mimeinfo[1] === "html")  && dataContainer) {  // TODO: Check if this works for image files aswell
                dataContainer.url = path; // WTF this seems to work :P
                pageStack.pop(dataContainer, PageStackAction.Animated);
            }
            else if (mimeinfo[0] === "image" && dataContainer) {
                compoImgViewer.createObject (overlay, {
                                                 "source" : path,
                                             });
            } else {
                mainWindow.infoBanner.parent = page
                mainWindow.infoBanner.anchors.top = page.top
                mainWindow.infoBanner.showText(qsTr("Opening..."));
                Qt.openUrlExternally(path);
            }
        }
    }

    function saveCustomPlaces() {
        var customPlacesJson = JSON.stringify(customPlaces);
        //console.debug(customPlacesJson);
        customPlacesSettings.setValue("places",customPlacesJson);
    }

    FolderListModel {
        id: fileModel
        folder: path
        showDirsFirst: true
        showDotAndDotDot: false
        showOnlyReadable: true
        nameFilters: filter
        sortField: _sortField
    }

    // WORKAROUND showHidden buggy not refreshing
    FolderListModel {
        id: fileModelHidden
        folder: path
        showDirsFirst: true
        showDotAndDotDot: false
        showOnlyReadable: true
        nameFilters: filter
        sortField: _sortField
    }

    function humanSize(bytes) {
        var precision = 2;
        var kilobyte = 1024;
        var megabyte = kilobyte * 1024;
        var gigabyte = megabyte * 1024;
        var terabyte = gigabyte * 1024;

        if ((bytes >= 0) && (bytes < kilobyte)) {
            return bytes + ' B';

        } else if ((bytes >= kilobyte) && (bytes < megabyte)) {
            return (bytes / kilobyte).toFixed(precision) + ' KB';

        } else if ((bytes >= megabyte) && (bytes < gigabyte)) {
            return (bytes / megabyte).toFixed(precision) + ' MB';

        } else if ((bytes >= gigabyte) && (bytes < terabyte)) {
            return (bytes / gigabyte).toFixed(precision) + ' GB';

        } else if (bytes >= terabyte) {
            return (bytes / terabyte).toFixed(precision) + ' TB';

        } else {
            return bytes + ' B';
        }
    }

    function findBaseName(url) {
        var fileName = url.substring(url.lastIndexOf('/') + 1);
        return fileName;
    }

    function findFullPath(url) {
        url = url.toString();
        var fullPath = url.substring(url.lastIndexOf('://') + 3);
        return fullPath;
    }

    function updateSortType() {
        if (_sortField === FolderListModel.Name) sortType = qsTr("Name")
        else if (_sortField === FolderListModel.Time) sortType = qsTr("Time")
        else if (_sortField === FolderListModel.Size) sortType = qsTr("Size")
        else if (_sortField === FolderListModel.Type) sortType = qsTr("Type")
    }

    SilicaListView {
        id: view
        model: fileModel
        anchors.fill: parent

        header: PageHeader {
            title: findBaseName((path).toString())
            description: hiddenShow ? path + " [.*]" : path
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!hiddenShow) {
                        view.model = fileModelHidden
                        view.model.showHidden = true
                    }
                    else {
                        view.model = fileModel
                        view.model.showHidden = false
                    }
                    hiddenShow = !hiddenShow
                }
            }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Create Folder")
                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("helper/fmComponents/CreateDirDialog.qml"),
                                                { "path": findFullPath(fileModel.folder.toString()) })
                    dialog.accepted.connect(function() {
                        if (dialog.errorMessage !== "") {
                            console.debug(dialog.errorMessage)
                            infoBanner.parent = page
                            infoBanner.anchors.top = page.top
                            infoBanner.showText(dialog.errorMessage)
                        }
                    })
                }
            }
//            MenuItem {
//                text: qsTr("Show Filesystem Root")
//                onClicked: fileModel.folder = _fm.getRoot();
//            }
//            MenuItem {
//                text: qsTr("Show Home")
//                onClicked: fileModel.folder = _fm.getHome();
//            }
//            MenuItem {
//                text: qsTr("Show Android SDCard")
//                onClicked: fileModel.folder = _fm.getHome() + "/android_storage";
//            }
//            MenuItem {
//                text: qsTr("Show SDCard")
//                onClicked: fileModel.folder = _fm.getRoot() + "media/sdcard";
//            }
            MenuItem {
                text: qsTr("Sort by: ") + sortType
                onClicked: {
                    if (_sortField === FolderListModel.Name) _sortField = FolderListModel.Time
                    else if (_sortField === FolderListModel.Time) _sortField = FolderListModel.Size
                    else if (_sortField === FolderListModel.Size) _sortField = FolderListModel.Type
                    else if (_sortField === FolderListModel.Type) _sortField = FolderListModel.Name
                    updateSortType();
                }
            }
            MenuItem {
                text: qsTr("Add to places")
                onClicked: {
                    customPlaces.push(
                                {
                                    name: findBaseName(path),
                                    path: findFullPath(fileModel.folder.toString()),
                                    icon: "image://theme/icon-m-folder"
                                }
                                )
                    customPlacesChanged()
                }
                visible: findFullPath(fileModel.folder.toString()) !== _fm.getHome()
            }

            MenuItem {
                id: pasteMenuEntry
                visible: { if (_fm.sourceUrl != "" && _fm.sourceUrl != undefined) return true;
                    else return false
                }
                text: qsTr("Paste") + "(" + findBaseName(_fm.sourceUrl) + ")"
                onClicked: {
                    busyInd.running = true
                    _fm.copyFile(_fm.sourceUrl,findFullPath(fileModel.folder) + "/" + findBaseName(_fm.sourceUrl))
                }
            }
            MenuItem {
                text: qsTr("Properties")
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("fmComponents/FileProperties.qml"),
                                          {"path": findFullPath(fileModel.folder), dataContainer: dataContainer, "fileIcon": "image://theme/icon-m-folder", "fileSize": "4k",
                                           "fileModified": fileModel.fileModified, "fileIsDir": true, "father": page})
                    //console.debug("Path: " + findFullPath(fileModel.folder))
                }
            }
        }

//        delegate: BackgroundItem {
//            id: bgdelegate
//            width: parent.width
//            height: menuOpen ? contextMenu.height + delegate.height : delegate.height
//            property Item contextMenu
//            property bool menuOpen: contextMenu != null && contextMenu.parent === bgdelegate

//            function remove() {
//                var removal = removalComponent.createObject(bgdelegate)
//                var toDelPath = filePath
//                if (fileIsDir)
//                    removal.execute(delegate,qsTr("Deleting ") + fileName, function() { _fm.removeDir(toDelPath); })
//                else
//                    removal.execute(delegate,qsTr("Deleting ") + fileName, function() { _fm.remove(toDelPath); })
//            }

//            function copy() {
//                _fm.moveMode = false;
//                _fm.sourceUrl = filePath;
//                //console.debug(_fm.sourceUrl)
//            }

//            function move() {
//                _fm.moveMode = true;
//                _fm.sourceUrl = filePath;
//            }

//            ListItem {
//                id: delegate

//                contentHeight: fileLabel.height + fileInfo.height + Theme.paddingSmall
//                showMenuOnPressAndHold: false
//                menu: myMenu
//                visible : {
//                    if (onlyFolders && fileIsDir) return true
//                    else if (onlyFolders) return false
//                    else return true
//                }

//                function showContextMenu() {
//                    if (!contextMenu)
//                        contextMenu = myMenu.createObject(view)
//                    contextMenu.show(bgdelegate)
//                }

//                Image
//                {
//                    id: fileIcon
//                    anchors.left: parent.left
//                    anchors.leftMargin: Theme.paddingSmall
//                    anchors.verticalCenter: parent.verticalCenter
//                    source: {
//                        if (fileIsDir) "image://theme/icon-m-folder"
//                        else if (_fm.getMime(filePath).indexOf("video") !== -1) "image://theme/icon-m-file-video"
//                        else if (_fm.getMime(filePath).indexOf("audio") !== -1) "image://theme/icon-m-file-audio"
//                        else if (_fm.getMime(filePath).indexOf("image") !== -1) "image://theme/icon-m-file-image"
//                        else if (_fm.getMime(filePath).indexOf("text") !== -1) "image://theme/icon-m-file-document"
//                        else if (_fm.getMime(filePath).indexOf("pdf") !== -1) "image://theme/icon-m-file-pdf"
//                        else if (_fm.getMime(filePath).indexOf("android") !== -1) "image://theme/icon-m-file-apk"
//                        else if (_fm.getMime(filePath).indexOf("rpm") !== -1) "image://theme/icon-m-file-rpm"
//                        else "image://theme/icon-m-document"
//                    }
//                }

//                Label {
//                    id: fileLabel
//                    anchors.left: fileIcon.right
//                    anchors.leftMargin: Theme.paddingLarge
//                    anchors.top: fileInfo.text != "" ? parent.top : undefined
//                    anchors.verticalCenter: fileInfo.text == "" ? parent.verticalCenter : undefined
//                    text: fileName //+ (fileIsDir ? "/" : "")
//                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
//                    width: mSelect.visible ? parent.width - (fileIcon.width + Theme.paddingLarge + Theme.paddingSmall + mSelect.width) : parent.width - (fileIcon.width + Theme.paddingLarge + Theme.paddingSmall)
//                    truncationMode: TruncationMode.Fade
//                }
//                Label {
//                    id: fileInfo
//                    anchors.left: fileIcon.right
//                    anchors.leftMargin: Theme.paddingLarge
//                    anchors.top: fileLabel.bottom
//                    text: fileIsDir ? fileModified.toLocaleString() : humanSize(fileSize) + ", " + fileModified.toLocaleString()
//                    color: Theme.secondaryColor
//                    width: parent.width - fileIcon.width - (Theme.paddingLarge + Theme.paddingSmall + Theme.paddingLarge)
//                    truncationMode: TruncationMode.Fade
//                    font.pixelSize: Theme.fontSizeTiny
//                }
//                Switch {
//                    id: mSelect
//                    visible: fileIsDir && multiSelect && onlyFolders
//                    anchors.right: parent.right
//                    checked: false
//                    onClicked: {
//                        checked = !checked
//                        fileOpen(filePath);
//                        pageStack.pop();
//                    }
//                }

//                onClicked: {
//                    if(multiSelect)
//                    {
//                        mSelect.checked = !mSelect.checked
//                        return;
//                    }

//                    if (fileIsDir) {
//                        var anotherFM = pageStack.push(Qt.resolvedUrl("OpenDialog.qml"), {"path": filePath, "dataContainer": dataContainer, "selectMode": selectMode, "multiSelect": multiSelect});
//                        anotherFM.fileOpen.connect(fileOpen)
//                    } else {
//                        if (!selectMode) openFile(filePath)
//                        else {
//                            fileOpen(filePath);
//                            pageStack.pop(dataContainer);
//                        }
//                    }
//                }
//                onPressAndHold: showContextMenu()
//            }

//            Component {
//                id: removalComponent
//                RemorseItem {
//                    id: remorse
//                    onCanceled: destroy()
//                }
//            }

//            Component {
//                id: myMenu
//                ContextMenu {
//                    MenuItem {
//                        text: qsTr("Cut")
//                        onClicked: {
//                            bgdelegate.move();
//                        }
//                    }
//                    MenuItem {
//                        text: qsTr("Copy")
//                        onClicked: {
//                            bgdelegate.copy();
//                        }
//                    }
//                    MenuItem {
//                        text: qsTr("Delete")
//                        onClicked: {
//                            bgdelegate.remove();
//                        }
//                    }
//                    MenuItem {
//                        text: qsTr("Properties")
//                        onClicked: {
//                            pageStack.push(Qt.resolvedUrl("fmComponents/FileProperties.qml"), {"path": filePath, dataContainer: dataContainer, "fileIcon": fileIcon.source, "fileSize": humanSize(fileSize), "fileModified": fileModified, "fileIsDir": fileIsDir, "father": page})
//                        }
//                    }
//                }
//            }

//        }
        delegate: FileItemDelegate { id: bgdelegate }
        VerticalScrollDecorator { flickable: view }
    }
    Component.onCompleted: {
        updateSortType()
    }
    Connections {
        target: _fm
        onSourceUrlChanged: {
            if (_fm.sourceUrl != "" && _fm.sourceUrl != undefined) {
                pasteMenuEntry.visible = true;
            }
            else pasteMenuEntry.visible = false;
        }
        onCpResultChanged: {
            if (!_fm.cpResult) {
                var message = qsTr("Error pasting file ") + _fm.sourceUrl
                console.debug(message);
                mainWindow.infoBanner.parent = page
                mainWindow.infoBanner.anchors.top = page.top
                infoBanner.showText(message)
            }
            else {
                _fm.sourceUrl = "";
                var message = qsTr("File operation succeeded")
                console.debug(message);
                mainWindow.infoBanner.parent = page
                mainWindow.infoBanner.anchors.top = page.top
                infoBanner.showText(message)
            }
            busyInd.running = false;
        }
    }

    BusyIndicator {
        id: busyInd
        anchors.top: parent.top
        anchors.topMargin: Theme.paddingLarge
        anchors.left: parent.left
        anchors.leftMargin: Theme.paddingLarge
    }

    Component {
            id: compoImgViewer;

            TouchBlocker {
                id: blocker;
                anchors.fill: parent;

                property alias source : imgViewer.source;

                Rectangle {
                    color: Qt.rgba (1.0 - Theme.primaryColor.r, 1.0 - Theme.primaryColor.g, 1.0 - Theme.primaryColor.b, 0.85);
                    anchors.fill: parent;
                }
                ImageViewer {
                    id: imgViewer;
                    source: "";
                    active: true;
                    anchors.fill: parent;
                    onClicked: {
                        blocker.destroy ();
                    }

                    property var root : mainWindow; // NOTE : to avoid QML warnings because it' baldy coded...
                }
            }
        }

    Item {
        id: overlay;
        anchors.fill: page;
    }

}

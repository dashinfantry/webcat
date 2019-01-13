import QtQuick 2.0
import Sailfish.Silica 1.0
import "helper/otherComponents"

Page {
    id: downloadManager
    allowedOrientations: mainWindow.orient
    property string downloadUrl
    property string downloadName
    property string downLoc
    property QtObject dataContainer

    Component.onCompleted: {
        if (downloadUrl != "") {
            download();
        }
    }

    function download() {
        if (downloadName != "") {
            _manager.setDownloadName(downloadName);
        }
        downLoc = _manager.saveFileName(downloadUrl);
        if (downloadName === "") downloadName = downLoc.substring(downLoc.lastIndexOf('/')+1)
        _manager.downloadUrl(downloadUrl);
        console.debug("[DownloadManager.qml] downloadName = " + downloadName);
        downloadVisualModel.model.append({"name": downloadName, "url": downloadUrl, "downLocation": downLoc.toString()})
        downloadList.forceLayout();
    }

    VisualDataModel {
        id: downloadVisualModel
        model: mainWindow.downloadModel
        delegate: BackgroundItem {
            id: bgdelegate
            width: parent.width
            anchors.margins: Theme.paddingMedium
            height: menuOpen ? contextMenu.height + dname.height + durl.height + Theme.paddingLarge : dname.height + durl.height + Theme.paddingLarge
            property Item contextMenu
            property bool menuOpen: contextMenu != null && contextMenu.parent === bgdelegate

            function remove() {
                var removal = removalComponent.createObject(bgdelegate)
                removal.execute(bgdelegate,qsTr("Deleting ") + dname.text, function() { _fm.remove(downLocation); mainWindow.downloadModel.remove(index) })
            }

            function showContextMenu() {
                if (!contextMenu)
                    contextMenu = myMenu.createObject(downloadVisualModel)
                contextMenu.show(bgdelegate)
            }

            Label {
                id: dname
                text: name
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingSmall
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade
                width: parent.width - (Theme.paddingMedium)
            }
            Label {
                id: durl
                text: url
                anchors.top: dname.bottom
                anchors.topMargin: Theme.paddingSmall
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingLarge
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                truncationMode: TruncationMode.Fade
                width: parent.width - (Theme.paddingMedium)
            }
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                if (_fm.isFile(downLocation)) {

                    var mime = _fm.getMime(downLocation);
                    var mimeinfo = mime.toString().split("/");

                    if(mimeinfo[0] === "video")
                    {
                        mainWindow.openWithvPlayer(downLocation,"");
                        if (mainWindow.vPlayerExternal) {
                            mainWindow.infoBanner.parent = downloadManager
                            mainWindow.infoBanner.anchors.top = downloadManager.top
                            mainWindow.infoBanner.showText(qsTr("Opening..."))
                        }
                        return;
                    }  else if ((mimeinfo[1] === "html" || mimeinfo[0] === "image")  && dataContainer) {  // TODO: Check if this works for image files aswell
                        dataContainer.url = downLocation; // WTF this seems to work :P
                        pageStack.pop(dataContainer.parent, PageStackAction.Animated);
                    } else {
                        mainWindow.infoBanner.parent = downloadManager
                        mainWindow.infoBanner.anchors.top = downloadManager.top
                        mainWindow.infoBanner.showText(qsTr("Opening..."));
                        Qt.openUrlExternally(downLocation);
                    }
                }
            }
            onPressAndHold: showContextMenu()

            Component {
                id: removalComponent
                RemorseItem {
                    id: remorse
                    onCanceled: destroy()
                }
            }

            Component {
                id: myMenu
                ContextMenu {
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: {
                            bgdelegate.remove();
                        }
                    }
                }
            }
        } // delegate

    }

    Flickable {
        id: flick
        width:parent.width
        height: parent.height
        anchors.top: parent.top
        //        anchors.topMargin: Theme.paddingLarge * 3
        contentHeight: column1.height
        PullDownMenu {
            MenuItem {
                text: qsTr("Add Download")
                onClicked: pageStack.push(manualDownload);
            }
            MenuItem {
                text: qsTr("Show Downloadfolder")
                onClicked: {
                    if (dataContainer) pageStack.push(Qt.resolvedUrl("OpenDialog.qml"), {"dataContainer": dataContainer, "path": _fm.getHome()+ "/Downloads"});
                    else pageStack.push(Qt.resolvedUrl("OpenDialog.qml"), {"dataContainer": dataContainer, "path": _fm.getHome()+ "/Downloads"});
                }
            }
            MenuItem {
                text: qsTr("Clear Downloads")
                onClicked: downloadVisualModel.model.clear()
                visible: downloadVisualModel.count > 0
            }
        }

        Column {
            id: column1
            width: parent.width
            spacing: 15

            PageHeader {
                title: qsTr("Download Manager")
            }

            // A Container to group the url TextField with its download Button
            Component {
                id: manualDownload
                Page {

                    allowedOrientations: mainWindow.orient
                    Column {
                        width: parent.width
                        spacing: 15
                        // A standard TextField for the url address
                        PageHeader {
                            title: qsTr("Add Download")
                        }

                        TextField {
                            id: urlField
                            anchors.topMargin: 65
                            width:parent.width
                            inputMethodHints: Qt.ImhUrlCharactersOnly
                            onFocusChanged: if (focus == true) selectAll();

                            placeholderText: qsTr("Enter URL to download")

                            // Disable the control button upon text input
                            onTextChanged: {
                                downloadButton.enabled = (text != "")
                            }
                        }

                        Keys.onReturnPressed: downloadButton.clicked(undefined)
                        Keys.onEnterPressed: downloadButton.clicked(undefined)

                        Button {
                            id: downloadButton

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.topMargin: 50

                            text: qsTr("Download")

                            // Start download from url on click
                            onClicked: { downloadManager.downloadUrl = urlField.text ; downloadManager.download(); pageStack.pop() }
                        }
                    }
                }
            }
            //            TextArea {
            //                id: toDownload
            //                anchors.topMargin: 65
            //                text: downloadUrl
            //                width: parent.width
            //                height: parent.height / 2.5
            //                anchors.horizontalCenter: parent.horizontalCenter
            //                color: Theme.primaryColor
            //                font.pixelSize: Theme.fontSizeMedium
            //                readOnly: true
            //            }

            SectionHeader {
                text: qsTr("Download list")
            }

            SilicaListView {
                id: downloadList
                width: parent.width
                height: isPortrait ? parent.height / 2.75 : parent.height / 3.75
                model: downloadVisualModel
                clip: true
            }

//            SectionHeader {
//                text: qsTr("Current operation")
//            }

//            Label {
//                id: activeDownloadLabel
//                text: qsTr("Active Downloads: ") + (_manager.activeDownloads == 0 ? qsTr("none") : "1/" + _manager.totalDownloads)
//                color: Theme.primaryColor
//                anchors.left: parent.left
//                anchors.leftMargin: Theme.paddingMedium
//                font.pixelSize: _manager.activeDownloads == 0 ? Theme.fontSizeMedium : Theme.fontSizeSmall
//            }

            SectionHeader {
                text: qsTr("Details")
            }

            ValueButton {
                id: valStatus
                label: qsTr("Status")
                onClicked: {
                    pageStack.push(statusPage);
                }
            }

            ValueButton {
                id: valErrors
                label: qsTr("Errors")
                onClicked: {
                    pageStack.push(errorPage);
                }
            }

            Component {
                id: statusPage
                Page {
                    allowedOrientations: mainWindow.orient
                    PageHeader {
                        id: pheader
                        title: qsTr("Download Status")
                    }
                    // A standard TextArea for the download status output
                    TextArea {
                        width: parent.width
                        height: parent.height - pheader.height
                        anchors.top: pheader.bottom
                        readOnly: true

                        text: _manager.statusMessage

                        color: Theme.primaryColor
                    }
                }
            }

            Component {
                id: errorPage
                Page {
                    allowedOrientations: mainWindow.orient
                    PageHeader {
                        id: pheader
                        title: qsTr("Download Errors")
                    }
                    // A standard TextArea for the download status output
                    TextArea {
                        width: parent.width
                        height: parent.height - pheader.height
                        anchors.top: pheader.bottom
                        readOnly: true

                        text: _manager.errorMessage

                        color: Theme.primaryColor
                    }
                }
            }


            // TODO: Maybe handy when there is a download list
            //            Component {
            //                id: details
            //                Page {
            //                    Column {
            //                        width: parent.width
            //                        spacing: 15
            //                        PageHeader {
            //                            title: qsTr("Download Details")
            //                        }

            //                        Label {
            //                            anchors.topMargin: 65
            //                            text: qsTr("Status:")
            //                            color: Theme.primaryColor
            //                        }
            //                        // A standard TextArea for the download status output
            //                        TextArea {
            //                            width: parent.width
            //                            height: 145
            //                            readOnly: true

            //                            text: _manager.statusMessage

            //                            color: Theme.primaryColor
            //                        }
            //                        Label {
            //                            text: qsTr ("Errors:")
            //                            color: Theme.primaryColor
            //                        }
            //                        // A standard TextArea for displaying error output
            //                        TextArea {
            //                            width: parent.width
            //                            height: 125
            //                            readOnly: true

            //                            text: _manager.errorMessage
            //                            color: Theme.primaryColor
            //                        }
            //                    }
            //                }
            //            }
        }
    }
    DockedPanel {
        id: activeDownloadPanel

        width: parent.width
        height: activeDownloadColumn.height + Theme.paddingMedium

        dock: Dock.Bottom
        open: _manager.activeDownloads != 0

        Rectangle {
            anchors.fill: parent
            color: Theme.overlayBackgroundColor
            opacity: 0.8
        }

        Column {
            id: activeDownloadColumn

            width: parent.width
            spacing: Theme.paddingMedium

            Label {
                id: curDownloadLabel
                text: _manager.curName
                color: Theme.primaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeSmall
                truncationMode: TruncationMode.Fade
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                visible: {
                    if (_manager.activeDownloads != 0) return true
                    else false
                }
            }

            ProgressBar {
                width: parent.width
                maximumValue: _manager.progressTotal
                value: _manager.progressValue
                label: _manager.progressMessage
                visible: {
                    if (_manager.activeDownloads != 0) return true
                    else false
                }
            }

            Row {
                visible: {
                    if (_manager.activeDownloads != 0) return true
                    else false
                }
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge
                Button {
                    id: pauseButton
                    text: _manager.isPaused ? qsTr("Resume") : qsTr("Pause")
                    onClicked: {
                        if (!_manager.isPaused) _manager.pause();
                        else _manager.resume();
                    }
                }

                Button {
                    id: abortButton
                    text: qsTr("Abort")
                    onClicked: { _manager.downloadAbort(); }
                }
            }
        }

    }
}

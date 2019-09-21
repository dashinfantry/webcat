import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property string path
    property string newPath
    property string oldName
    property string errorMessage
    property string newName

    id: dialog
    allowedOrientations: Orientation.All
    canAccept: _newName.text !== ""

    onAccepted: {
        newPath = path.replace(oldName,_newName.text)
        newName = _newName.text
    }

    Component.onCompleted: {
        _newName.text = oldName
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right

            DialogHeader {
                id: dialogHeader
                title: qsTr("Rename")
                acceptText: qsTr("Rename")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: qsTr("Give a new name for") + "\n" + path
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
            }

            Separator {
                height: Theme.paddingLarge
                color: "transparent"
            }

            TextField {
                id: _newName
                width: parent.width
                placeholderText: qsTr("New name")
                label: qsTr("New name")
                focus: true

                // return key on virtual keyboard accepts the dialog
                EnterKey.enabled: _newName.text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: dialog.accept()
            }
        }
    }
}

/*
  Copyright (C) 2015 Leszek Lesner
  Contact: Leszek Lesner <leszek.lesner@web.de>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

// Long press contextmenu for link
Rectangle {
    id: contextMenu
    width: parent.width
    property alias contextLbl: contextLabel
    property alias imageLbl: imageLabel

    Behavior on height {
        NumberAnimation { target: contextMenu; property: "height"; duration: 350; easing.type: Easing.InOutQuad }
    }
    onHeightChanged: {
        if (height == 0) visible = false
    }

    gradient: Gradient {
        GradientStop { position: 0.0; color: isLightTheme ? "#e9e9e9" : "#262626" }
        GradientStop { position: 0.85; color: isLightTheme ? "#dfdfdf" : "#1F1F1F"}
    }
    opacity: 0.98

    TextField { // Allows copying
        id: contextLabel
        color: isLightTheme ? "black" : "white"
        readOnly: true
        anchors {
            top: parent.top; left: parent.left; right: parent.right;
            margins: 20; topMargin: 10; bottomMargin: 10;
        }
    }
    TextField { // Allows copying for images
        id: imageLabel
        color: isLightTheme ? "black" : "white"
        readOnly: true
        visible: contextLabel.text == ""
        anchors {
            top: parent.top; left: parent.left; right: parent.right;
            margins: 20; topMargin: 10; bottomMargin: 10;
        }
    }
}

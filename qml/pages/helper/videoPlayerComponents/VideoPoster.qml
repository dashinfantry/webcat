import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0

MouseArea {
    id: videoItem

    property MediaPlayer player
    property bool active
    property url source
    property string mimeType
    property int duration
    property int pressTime: 1
    onDurationChanged: positionSlider.maximumValue = duration
    property alias controls: controls
    property alias position: positionSlider.value
    signal playClicked;
    property alias _positionSlider: positionSlider
    property alias _maxTime: maxTime

    property bool transpose

    property bool playing: active && videoItem.player && videoItem.player.playbackState == MediaPlayer.PlayingState
    readonly property bool _loaded: active
                                    && videoItem.player
                                    && videoItem.player.status >= MediaPlayer.Loaded
                                    && videoItem.player.status < MediaPlayer.EndOfMedia

    function play() {
        videoItem.playClicked();
        videoItem.player.source = videoItem.source;
        videoItem.player.play();
    }

    function ffwd(seconds) {
        videoItem.player.seek((positionSlider.value*1000) + (seconds * 1000))
    }

    function rew(seconds) {
        videoItem.player.seek((positionSlider.value*1000) - (seconds * 1000))
    }

    Connections {
        target: videoItem._loaded ? videoItem.player : null

        onPositionChanged: positionSlider.value = videoItem.player.position / 1000
        onDurationChanged: positionSlider.maximumValue = videoItem.player.duration / 1000
    }

    onActiveChanged: {
        if (!active) {
            positionSlider.value = 0
        }
    }

    Item {
        id: controls
        width: videoItem.width
        height: videoItem.height
        property alias rew: rewRec
        property alias ffwd: ffwdRec

        opacity: 1.0
        Behavior on opacity { FadeAnimation { id: controlFade } }

        visible: videoItem.player || controlFade.running //(!videoItem.playing || controlFade.running)

        Rectangle {
            anchors.centerIn: parent
            width: playPauseImg.width + 64
            height: playPauseImg.height + 64
            color: isLightTheme ? "white" : "black"
            opacity: 0.4
            radius: width / 2
            border.color: isLightTheme ? "black" : "white"
            border.width: 2
        }

        Rectangle {
            id: ffwdRec
            anchors.centerIn: ffwdImg
            width: playPauseImg.width + Theme.iconSizeSmall
            height: playPauseImg.height + Theme.iconSizeSmall
            color: isLightTheme ? "white" : "black"
            opacity: 0.4
            radius: width / 2
            border.color: isLightTheme ? "black" : "white"
            border.width: 2
        }

        Rectangle {
            id: rewRec
            anchors.centerIn: rewImg
            width: playPauseImg.width + Theme.iconSizeSmall
            height: playPauseImg.height + Theme.iconSizeSmall
            color: isLightTheme ? "white" : "black"
            opacity: 0.4
            radius: width / 2
            border.color: isLightTheme ? "black" : "white"
            border.width: 2
        }

        Image {
            id: playPauseImg
            anchors.centerIn: parent
            source: {
                if (videoItem.player && (!videoItem.playing)) return "image://theme/icon-cover-play"
                else return "image://theme/icon-cover-pause"
            }
            width: height
            height: Theme.iconSizeMedium
            MouseArea {
                anchors.centerIn: parent
                width: parent.width + 64
                height: parent.height + 64
                enabled: !videoItem.playing
                onClicked: {
                    //console.debug("VideoItem.source length = " + videoItem.source.toString().length)
                    if (videoItem.source.toString().length !== 0) {
                        //console.debug("Yeah we have a video source")
                        videoItem.playClicked();
                        videoItem.player.source = videoItem.source;
                        videoItem.player.play();
                    }
                }
            }
        }

        Timer {
            id: pressTimer
            running: false;
            interval: 1500
            onTriggered: { stop() }
            triggeredOnStart: false
        }

        Image {
            id: ffwdImg
            anchors.verticalCenter: playPauseImg.verticalCenter
            anchors.left: playPauseImg.right
            anchors.leftMargin: Theme.paddingLarge * 2 + Theme.paddingMedium
            source: "image://theme/icon-m-enter-accept"
            width: Theme.iconSizeMedium
            height: width
            MouseArea {
                anchors.centerIn: parent
                width: parent.width + Theme.iconSizeMedium
                height: parent.height + Theme.iconSizeMedium
                enabled: { if (controls.opacity == 1.0) return true; else return false; }
                onClicked: {
                    //console.debug("VideoItem.source length = " + videoItem.source.toString().length)
                    if (videoItem.source.toString().length !== 0) {
                        if (!pressTimer.running) {
                            pressTime = 1;
                            pressTimer.start();
                            ffwd(10)
                        }
                        else {
                            pressTime += 1
                            forwardIndicator.visible = true
                            ffwd(10*pressTime)
                        }
                    }
                }
            }
        }

        Image {
            id: rewImg
            anchors.verticalCenter: playPauseImg.verticalCenter
            anchors.right: playPauseImg.left
            anchors.rightMargin: Theme.paddingLarge * 2 + Theme.paddingMedium
            source: "image://theme/icon-m-enter-accept"
            width: Theme.iconSizeMedium
            height: width
            mirror: true
            MouseArea {
                anchors.centerIn: parent
                width: parent.width + Theme.iconSizeMedium
                height: parent.height + Theme.iconSizeMedium
                enabled: { if (controls.opacity == 1.0) return true; else return false; }
                onClicked: {
                    //console.debug("VideoItem.source length = " + videoItem.source.toString().length)
                    if (videoItem.source.toString().length !== 0) {
                        if (!pressTimer.running) {
                            pressTime = 1;
                            pressTimer.start();
                            rew(5)
                        }
                        else {
                            pressTime += 1
                            backwardIndicator.visible = true
                            rew(5*pressTime)
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            enabled: { if (controls.opacity == 1.0) return true; else return false; }
            height: positionSlider.height + (2 * Theme.paddingLarge)
            //color: "black"
            //opacity: 0.5
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: isLightTheme ? "white" : "black" } //Theme.highlightColor} // Black seems to look and work better
            }
            Label {
                id: maxTime
                anchors.right: parent.right
                anchors.rightMargin: (2 * Theme.paddingLarge)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingLarge
                text: {
                    if (positionSlider.maximumValue > 3599) return Format.formatDuration(maximumValue, Formatter.DurationLong)
                    else return Format.formatDuration(positionSlider.maximumValue, Formatter.DurationShort)
                }
                visible: videoItem._loaded
            }

            Slider {
                id: positionSlider

                anchors {
                    left: parent.left;
                    right: {
                        if (maxTime.visible) maxTime.left
                        else parent.right;
                    }
                    bottom: parent.bottom
                }
                anchors.bottomMargin: Theme.paddingLarge + Theme.paddingMedium
                enabled: { if (controls.opacity == 1.0) return true; else return false; }
                height: Theme.itemSizeSmall
                width: {
                    if (maxTime.visible) parent.width - (maxTime.width)
                    else parent.width
                }
                handleVisible: down ? true : false
                minimumValue: 0

                valueText: {
                    if (value > 3599) return Format.formatDuration(value, Formatter.DurationLong)
                    else return Format.formatDuration(value, Formatter.DurationShort)
                }
                onReleased: {
                    if (videoItem.active) {
                        videoItem.player.source = videoItem.source
                        videoItem.player.seek(value * 1000)
                        //videoItem.player.pause()
                    }
                }
            }
        }
        Row {
            id: backwardIndicator
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.width / 2 - (playPauseImg.height + Theme.paddingLarge)
            visible: false
            spacing: -Theme.paddingLarge*2

            Image {
                id: prev1
                width: Theme.itemSizeLarge
                height: Theme.itemSizeLarge
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                source: "image://theme/icon-cover-play"

                transform: Rotation{
                    angle: 180
                    origin.x: prev1.width/2
                    origin.y: prev1.height/2
                }
            }
            Image {
                id: prev2
                width: Theme.itemSizeLarge
                height: Theme.itemSizeLarge
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                source: "image://theme/icon-cover-play"

                transform: Rotation{
                    angle: 180
                    origin.x: prev2.width/2
                    origin.y: prev2.height/2
                }
            }

            Timer {
                id: hideBackward
                interval: 300
                onTriggered: backwardIndicator.visible = false
            }

            onVisibleChanged: if (backwardIndicator.visible) hideBackward.start()
        }

        Row {
            id: forwardIndicator
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.width / 2 - (playPauseImg.height + Theme.paddingLarge)
            visible: false
            spacing: -Theme.paddingLarge*2

            Image {
                width: Theme.itemSizeLarge
                height: Theme.itemSizeLarge
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                source: "image://theme/icon-cover-play"

            }
            Image {
                width: Theme.itemSizeLarge
                height: Theme.itemSizeLarge
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                source: "image://theme/icon-cover-play"
            }

            Timer {
                id: hideForward
                interval: 300
                onTriggered: forwardIndicator.visible = false
            }

            onVisibleChanged: if (forwardIndicator.visible) hideForward.start()
        }
    }
}

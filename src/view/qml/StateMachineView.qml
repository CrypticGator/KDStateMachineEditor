/*
  StateMachineView.qml

  This file is part of the KDAB State Machine Editor Library.

  Copyright (C) 2014 Klarälvdalens Datakonsult AB, a KDAB Group company, info@kdab.com.
  All rights reserved.
  Author: Kevin Funk <kevin.funk@kdab.com>

  Licensees holding valid commercial KDAB State Machine Editor Library
  licenses may use this file in accordance with the KDAB State Machine Editor
  Library License Agreement provided with the Software.

  This file may be distributed and/or modified under the terms of the
  GNU Lesser General Public License version 2.1 as published by the
  Free Software Foundation and appearing in the file LICENSE.LGPL.txt included.

  This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
  WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

  Contact info@kdab.com if any conditions of this licensing are not
  clear to you.
*/

import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

import com.kdab.kdsme 1.0

import "qrc:///kdsme/qml/uml/"
import "qrc:///kdsme/qml/util/"
import "qrc:///kdsme/qml/util/theme.js" as Theme

import "util/constants.js" as Constants

Rectangle {
    id: root
    objectName: "stateMachineView"

    property var currentView: _quickView.view
    property var commandController: _quickView.commandController
    property var configurationController: _quickView.configurationController
    property var editController: _quickView.editController

    /// Whether we automatically move the content of the view-port in case the active region changes
    property bool followActiveRegion: false

    /// Scale factor of the scene
    property alias zoom: stateMachineScene.scale
    /// Whether we automatically collapse/expand states in case they're active or not
    property alias semanticZoom: semanticZoomManager.enabled

    color: Theme.viewBackgroundColor

    function fitInView() {
        _quickView.fitInView()
    }

    function centerOnActiveRegion() {
        var activeRegion = configurationController.activeRegion;
        if (activeRegion.width === 0)
            return;

        var width = stateMachineViewport.width;
        var height = stateMachineViewport.height;
        var centerPos = Qt.point(width/2, height/2);
        stateMachineViewport.contentX = activeRegion.x - (centerPos.x - activeRegion.width/2);
        stateMachineViewport.contentY = activeRegion.y - (centerPos.y - activeRegion.height/2);
    }

    SemanticZoomManager {
        id: semanticZoomManager

        configurationController: root.configurationController
    }

    ColumnLayout {
        id: topDock

        width: parent.width
        z: 1

        StateMachineViewToolBar {
            stateMachineView: root

            Layout.fillWidth: true
        }
    }

    ScrollView {
        id: centralContent

        anchors {
            top: topDock.bottom
            left: parent.left
            right: parent.right
            bottom: bottomDock.top
        }

        Flickable {
            id: stateMachineViewport
            objectName: "stateMachineViewport"

            anchors.fill: parent

            contentWidth: stateMachineScene.width * stateMachineScene.scale
            contentHeight: stateMachineScene.height * stateMachineScene.scale
            boundsBehavior: Flickable.StopAtBounds
            focus: true
            interactive: !editController.editModeEnabled

            onMovementStarted: {
                followActiveRegion = false;
            }

            StateMachineScene {
                id: stateMachineScene
                objectName: "stateMachineScene"

                currentView: root.currentView
                configurationController: root.configurationController
            }

            Connections {
                target: (root.followActiveRegion ? root.configurationController : null)
                onActiveRegionChanged: centerOnActiveRegion();
            }

            Behavior on contentX {
                enabled: root.followActiveRegion
                SmoothedAnimation { duration: 200 }
            }
            Behavior on contentY {
                enabled: root.followActiveRegion
                SmoothedAnimation { duration: 200 }
            }

            // TODO: Add PinchArea?
        }
    }

    MouseArea {
        id: mouseArea

        readonly property alias view: stateMachineViewport
        readonly property alias scene: stateMachineScene

        anchors.fill: centralContent

        propagateComposedEvents: true
        hoverEnabled: true
        onWheel: {
            followActiveRegion = false;

            if (wheel.modifiers & Qt.ControlModifier) {
                var nominalFactor = (wheel.angleDelta.y > 0 ? 1.1 : 0.9);
                var scale = Math.min(Math.max(scene.scale * nominalFactor, Constants.minimumZoomLevel), Constants.maximumZoomLevel);
                var factor = scale / scene.scale;

                // calculate offset, to move the contents when zooming in or out to stay at the mouse position
                var pos = Qt.point(mouseX, mouseY);
                var newPos = Qt.point(pos.x * factor, pos.y * factor)
                var offsetX = newPos.x - pos.x;
                var offsetY = newPos.y - pos.y;

                scene.scale = scale;
                view.contentX += offsetX;
                view.contentY += offsetY;
            } else {
                wheel.accepted = false
            }
        }
        onPressed: {
            mouse.accepted = false
        }
    }

    BirdEyeView {
        id: birdEyeView

        width: 200
        height: 200

        opacity: canMove
        visible: opacity != 0.0
        flickable: stateMachineViewport
        scene: stateMachineScene

        anchors {
            bottom: bottomDock.top
            right: parent.right
            margins: 20
        }

        Behavior on opacity {
            NumberAnimation { duration: 500 }
        }
    }

    ColumnLayout {
        id: bottomDock

        anchors.bottom: statusBar.top
        width: parent.width
        z: 1

        StateMachineDebugToolBar {
            visible: !editController.editModeEnabled && (root.configurationController ? root.configurationController.isRunning : false)
            Layout.fillWidth: true

            stateMachineView: root
        }
    }

    StatusBar {
        id: statusBar

        z: 1
        anchors.bottom: parent.bottom

        RowLayout {
            Label {
                property string label: (currentView && currentView.stateMachine ? currentView.stateMachine.label : "")
                text: qsTr("State Machine: ") + (label !== "" ? label : qsTr("<Unnamed>"))
            }
            Label { text: "|" }
            Label {
                text: qsTr("Zoom: ") + Math.round(stateMachineScene.scale * 100) + " %"
            }

            // Debugging

            /*
            Label { text: "|" }
            Label {
                text: ("Active region: " + (configurationController ? configurationController.activeRegion : "N/A"))
            }
            */
        }
    }
}
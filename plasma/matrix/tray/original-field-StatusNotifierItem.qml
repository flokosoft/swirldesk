/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>
    SPDX-License-Identifier: LGPL-2.0-or-later

    FIELD override based on KDE Plasma 6.3.5 StatusNotifierItem.qml.
*/

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

AbstractItem {
    id: taskIcon
    itemId: model.Id
    text: model.Title || model.ToolTipTitle
    mainText: inVisibleLayout || (model.ToolTipTitle !== "" && model.ToolTipTitle !== text) ? model.ToolTipTitle : ""
    subText: model.ToolTipSubTitle
    textFormat: Text.AutoText
    active: inVisibleLayout || text != mainText || subText.length > 0

    // FIELD 0.9.3.7 DIRECT SNI OVERRIDE
    // Plasma 6.3.5 exposes these stable StatusNotifier roles here. Matching is
    // deliberately simple and limited to Signal / Bitwarden.
    readonly property string fieldIdentity: (
        String(model.Id || "") + " "
        + String(model.Title || "") + " "
        + String(model.ToolTipTitle || "") + " "
        + String(model.ToolTipSubTitle || "") + " "
        + String(model.IconName || "")
    ).toLowerCase()

    readonly property bool fieldIsBitwarden:
        fieldIdentity.indexOf("bitwarden") !== -1
        || fieldIdentity.indexOf("com.bitwarden.desktop") !== -1

    readonly property bool fieldIsSignal:
        fieldIdentity.indexOf("signal") !== -1
        || fieldIdentity.indexOf("org.signal.signal") !== -1
        || fieldIdentity.indexOf("whispersystems") !== -1

    readonly property bool fieldHasOverride: fieldIsSignal || fieldIsBitwarden

    Kirigami.Icon {
        id: iconItem
        parent: taskIcon.iconContainer
        anchors.fill: iconItem.parent
        source: {
            if (taskIcon.fieldIsBitwarden) {
                return Qt.resolvedUrl("../../icons/field-vault.svg")
            }
            if (taskIcon.fieldIsSignal) {
                return Qt.resolvedUrl("../../icons/field-chat.svg")
            }
            if (model.status === PlasmaCore.Types.NeedsAttentionStatus) {
                if (model.AttentionIcon) {
                    return model.AttentionIcon
                }
                if (model.AttentionIconName) {
                    return model.AttentionIconName
                }
            }
            return model.Icon || model.IconName
        }

        // Only the two FIELD-owned vectors are forced through the mask path;
        // all unrelated tray items retain Plasma's normal rendering behavior.
        isMask: taskIcon.fieldHasOverride
        color: taskIcon.fieldHasOverride
            ? ((model.status === PlasmaCore.Types.NeedsAttentionStatus || taskIcon.containsMouse)
                ? "#a68a5b" : "#d9d3c3")
            : "transparent"
        active: !taskIcon.fieldHasOverride && taskIcon.containsMouse
    }
    onActivated: pos => {
        const service = model.Service;
        const operation = service.operationDescription("Activate");
        operation.x = pos.x; //mouseX
        operation.y = pos.y; //mouseY
        const job = service.startOperationCall(operation);
        job.finished.connect(() => {
            if (!job.result) {
                // On error try to invoke the context menu.
                // Workaround primarily for apps using libappindicator.
                openContextMenu(pos);
            }
        })
    }
    onContextMenu: mouse => {
        if (mouse === null) {
            openContextMenu(Plasmoid.popupPosition(taskIcon, taskIcon.width / 2, taskIcon.height / 2));
        } else {
            openContextMenu(Plasmoid.popupPosition(taskIcon, mouse.x, mouse.y));
        }
    }

    onClicked: mouse => {
        const pos = Plasmoid.popupPosition(taskIcon, mouse.x, mouse.y);
        switch (mouse.button) {
        case Qt.LeftButton:
            taskIcon.activated(pos)
            break;
        case Qt.RightButton:
            openContextMenu(pos);
            break;
        case Qt.MiddleButton:
            const service = model.Service;
            const operation = service.operationDescription("SecondaryActivate");
            operation.x = pos.x;
            operation.y = pos.y;
            service.startOperationCall(operation);
            break;
        }
    }
    function openContextMenu(pos = Qt.point(width/2, height/2)) {
        const service = model.Service;
        const operation = service.operationDescription("ContextMenu");
        operation.x = pos.x;
        operation.y = pos.y;

        const job = service.startOperationCall(operation);
        job.finished.connect(() => {
            Plasmoid.showStatusNotifierContextMenu(job, taskIcon);
        });
    }
    onWheel: wheel => {
        //don't send activateVertScroll with a delta of 0, some clients seem to break (kmix)
        if (wheel.angleDelta.y !== 0) {
            const service = model.Service;
            const operation = service.operationDescription("Scroll");
            operation.delta = wheel.angleDelta.y;
            operation.direction = "Vertical";
            service.startOperationCall(operation);
        }
        if (wheel.angleDelta.x !== 0) {
            const service = model.Service;
            const operation = service.operationDescription("Scroll");
            operation.delta = wheel.angleDelta.x;
            operation.direction = "Horizontal";
            service.startOperationCall(operation);
        }
    }
}

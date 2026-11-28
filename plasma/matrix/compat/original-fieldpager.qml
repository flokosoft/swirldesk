import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    implicitWidth: rail.implicitWidth + 8
    implicitHeight: 30
    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.minimumHeight: 30
    Layout.preferredHeight: 30

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    function sameDesktop(a, b) {
        return String(a) === String(b)
    }

    Row {
        id: rail
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: Math.min(6, virtualDesktopInfo.desktopIds.length)

            delegate: Rectangle {
                id: desktopButton
                width: 30
                height: 26
                color: mouse.containsMouse ? "#181b15" : "transparent"

                readonly property bool active: root.sameDesktop(
                    virtualDesktopInfo.currentDesktop,
                    virtualDesktopInfo.desktopIds[index]
                )

                Text {
                    anchors.centerIn: parent
                    text: desktopButton.active ? "[" + (index + 1) + "]" : String(index + 1)
                    color: desktopButton.active ? "#d9d3c3" : (mouse.containsMouse ? "#b3a06d" : "#8e7a58")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.weight: desktopButton.active ? Font.DemiBold : Font.Normal
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: desktopButton.active ? 20 : 0
                    height: 1
                    color: "#a68a5b"
                    visible: width > 0
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (virtualDesktopInfo.desktopIds.length > index) {
                            virtualDesktopInfo.requestActivate(virtualDesktopInfo.desktopIds[index])
                        }
                    }
                }
            }
        }
    }
}

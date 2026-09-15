import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kwin 3.0 as KWin

KWin.TabBoxSwitcher {
    id: tabBox

    function twoDigits(value) {
        return value < 10 ? "0" + value : String(value)
    }

    Instantiator {
        active: tabBox.visible

        delegate: PlasmaCore.Dialog {
            id: dialog
            location: PlasmaCore.Types.Floating
            visible: true
            flags: Qt.Popup | Qt.X11BypassWindowManagerHint

            x: tabBox.screenGeometry.x + Math.round((tabBox.screenGeometry.width - dialogMainItem.width) / 2)
            y: tabBox.screenGeometry.y + Math.round((tabBox.screenGeometry.height - dialogMainItem.height) / 2)

            mainItem: FocusScope {
                id: dialogMainItem
                focus: true
                width: Math.min(620, Math.round(tabBox.screenGeometry.width * 0.58))
                height: 76 + Math.max(1, Math.min(8, taskList.count)) * 34

                Rectangle {
                    anchors.fill: parent
                    color: "#0b0d0a"
                    border.width: 1
                    border.color: "#a68a5b"

                    Text {
                        x: 10
                        y: 10
                        height: 28
                        verticalAlignment: Text.AlignVCenter
                        text: "FIELD // TASKS"
                        color: "#a68a5b"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        y: 10
                        height: 28
                        verticalAlignment: Text.AlignVCenter
                        text: tabBox.twoDigits(taskList.currentIndex + 1) + " / " + tabBox.twoDigits(taskList.count)
                        color: "#8e7a58"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        renderType: Text.NativeRendering
                    }

                    Rectangle {
                        x: 10
                        y: 39
                        width: parent.width - 20
                        height: 1
                        color: "#544a38"
                    }

                    ListView {
                        id: taskList
                        objectName: "listView"
                        x: 10
                        y: 45
                        width: parent.width - 20
                        height: Math.max(1, Math.min(8, count)) * 34
                        model: tabBox.model
                        currentIndex: tabBox.currentIndex
                        clip: true
                        interactive: false
                        keyNavigationWraps: true
                        highlightMoveDuration: 0
                        highlightResizeDuration: 0

                        onCurrentIndexChanged: {
                            if (tabBox.currentIndex !== currentIndex) {
                                tabBox.currentIndex = currentIndex
                            }
                            if (currentIndex >= 0) {
                                positionViewAtIndex(currentIndex, ListView.Contain)
                            }
                        }

                        delegate: MouseArea {
                            width: taskList.width
                            height: 34
                            hoverEnabled: true

                            onClicked: tabBox.model.activate(index)

                            Rectangle {
                                anchors.fill: parent
                                color: index === taskList.currentIndex ? "#181b15" : "transparent"

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 2
                                    height: 22
                                    color: "#a68a5b"
                                    visible: index === taskList.currentIndex
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: desktopLabel.left
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (index === taskList.currentIndex ? "> " : "  ")
                                        + tabBox.twoDigits(index + 1)
                                        + " // " + model.caption
                                    color: index === taskList.currentIndex ? "#d9d3c3" : "#a9a393"
                                    elide: Text.ElideRight
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.weight: index === taskList.currentIndex ? Font.DemiBold : Font.Normal
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    id: desktopLabel
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tabBox.allDesktops && model.desktopName ? "WS " + model.desktopName : ""
                                    visible: text.length > 0
                                    color: "#8e7a58"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    renderType: Text.NativeRendering
                                }
                            }
                        }
                    }

                    Text {
                        x: 10
                        y: 51 + Math.max(1, Math.min(8, taskList.count)) * 34
                        width: parent.width - 20
                        height: 18
                        text: "ALT+TAB  SELECT  //  RELEASE ALT  EXEC"
                        color: "#6f695c"
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // Plasma 6 uses the root PlasmoidItem itself as the full
    // representation when no compact/full representation is declared.
    // This is all we need for a fixed text label in a panel.
    Layout.preferredWidth: fieldLabel.implicitWidth + 18
    Layout.minimumWidth: fieldLabel.implicitWidth + 18
    Layout.maximumWidth: fieldLabel.implicitWidth + 18

    PlasmaComponents.Label {
        id: fieldLabel
        anchors.centerIn: parent
        text: "FIELD //"
        color: "#b3a06d"
        font.family: "monospace"
        font.pixelSize: 12
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }
}

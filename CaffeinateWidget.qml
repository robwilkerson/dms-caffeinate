import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root
    pluginId: "caffeinate"
    pluginService: PluginService

    // Reactive states
    readonly property bool caffeinateActive: globalIsActive.value
    property string selectedDuration: {
        if (pluginData && pluginData.selectedDuration !== undefined && pluginData.selectedDuration !== null && pluginData.selectedDuration !== "undefined" && pluginData.selectedDuration !== "") {
            return pluginData.selectedDuration;
        }
        let def = pluginData?.defaultDuration ?? "infinity";
        def = def.trim().toLowerCase();
        if (def === "infinity" || def === "infinite" || def === "inf" || def === "") {
            return "infinity";
        }
        const mins = parseInt(def);
        if (!isNaN(mins) && mins > 0) {
            return (mins * 60).toString();
        }
        return "infinity";
    }
    readonly property int timeLeft: globalTimeLeft.value

    readonly property bool isAutoActive: globalIsAutoActive.value
    readonly property bool manualOverrideOff: globalManualOverrideOff.value

    PluginGlobalVar {
        id: globalIsActive
        varName: "isActive"
        defaultValue: false
    }

    PluginGlobalVar {
        id: globalTimeLeft
        varName: "timeLeft"
        defaultValue: 0
    }

    PluginGlobalVar {
        id: globalIsAutoActive
        varName: "isAutoActive"
        defaultValue: false
    }

    PluginGlobalVar {
        id: globalManualOverrideOff
        varName: "manualOverrideOff"
        defaultValue: false
    }

    // Sync settings
    property bool showToasts: (pluginData?.showToasts ?? true)
    property bool appAutomationEnabled: (pluginData?.appAutomationEnabled ?? false)
    property string autoAppsList: (pluginData?.autoAppsList ?? "mpv, vlc, zoom, Teams, discord, webcord, slack, spotify, obs")
    readonly property var parsedAutoApps: autoAppsList.split(",").map(a => a.trim().toLowerCase()).filter(Boolean)
    property bool fullscreenAwarenessEnabled: (pluginData?.fullscreenAwarenessEnabled ?? false)
    property bool batteryIntegrationEnabled: (pluginData?.batteryIntegrationEnabled ?? false)
    property int batteryLowThreshold: {
        const raw = pluginData?.batteryLowThreshold ?? "15";
        const val = parseInt(raw);
        return isNaN(val) ? 15 : val;
    }
    property bool deactivateOnManualLock: (pluginData?.deactivateOnManualLock ?? true)

    // Animated Coffee Cup component with steam and radial progress ring
    Component {
        id: animatedCoffeeCup
        Item {
            id: cupRoot
            width: 56
            height: 56
            
            // Radial progress ring
            RadialProgressRing {
                anchors.fill: parent
                radius: 25
                strokeWidth: 3
                color: Theme.primary
                active: root.caffeinateActive
                backgroundOpacityActive: 0.25
                backgroundOpacityInactive: 0.08
                angle: {
                    if (root.selectedDuration === "infinity") return 360;
                    const total = parseInt(root.selectedDuration);
                    if (isNaN(total) || total <= 0) return 360;
                    return 360 * (root.timeLeft / total);
                }
            }

            // Coffee Cup Icon
            CaffeinateMark {
                id: cupIcon
                size: 28
                markColor: root.caffeinateActive ? Theme.primary : Theme.surfaceText
                strokeWeight: 2.0
                anchors.centerIn: parent
            }

            // Steaming lines (active only). Anchored to the mug's ink rather than to the
            // mark's padded box, or the wisps would float clear of the cup.
            Item {
                id: steamContainer
                width: 24
                height: 16
                anchors.bottom: cupIcon.top
                anchors.horizontalCenter: cupIcon.horizontalCenter
                anchors.bottomMargin: -(cupIcon.inkTop + 2)
                visible: root.caffeinateActive

                Repeater {
                    model: 3
                    delegate: Shape {
                        id: steam
                        width: 6
                        height: 12
                        x: [3, 9, 15][index]
                        y: 4
                        opacity: 0
                        
                        ShapePath {
                            strokeColor: Theme.primary
                            strokeWidth: 1.5
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 3
                            startY: 12
                            PathQuad { x: 1; y: 6; controlX: 5; controlY: 9 }
                            PathQuad { x: 3; y: 0; controlX: -1; controlY: 3 }
                        }

                        SequentialAnimation {
                            running: steamContainer.visible
                            loops: Animation.Infinite
                            
                            PauseAnimation {
                                duration: index * 400
                            }
                            
                            ParallelAnimation {
                                NumberAnimation { target: steam; property: "y"; from: 4; to: -8; duration: 1200; easing.type: Easing.OutQuad }
                                SequentialAnimation {
                                    NumberAnimation { target: steam; property: "opacity"; from: 0; to: 0.7; duration: 400 }
                                    NumberAnimation { target: steam; property: "opacity"; from: 0.7; to: 0; duration: 800 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    property var durationOptions: {
        const rawPresets = pluginData?.presets ?? "5, 15, 30, 60, 120, infinity";
        const items = rawPresets.split(",").map(item => item.trim()).filter(Boolean);
        const result = [];
        for (const item of items) {
            if (item.toLowerCase() === "infinity" || item.toLowerCase() === "infinite" || item.toLowerCase() === "inf") {
                // "infinity" is the value, not a display string: it is passed straight to
                // `sleep` when the inhibitor starts and is persisted as selectedDuration.
                // Only the label is free to change.
                result.push({ label: I18n.tr("Forever"), value: "infinity" });
            } else {
                const mins = parseInt(item);
                if (!isNaN(mins) && mins > 0) {
                    let label = mins + " Min";
                    if (mins >= 60) {
                        const hrs = mins / 60;
                        if (hrs === 1) {
                            label = "1 Hour";
                        } else if (hrs === Math.round(hrs)) {
                            label = hrs + " Hours";
                        } else {
                            label = hrs.toFixed(1).replace(".0", "") + " Hours";
                        }
                    }
                    result.push({ label: label, value: (mins * 60).toString() });
                }
            }
        }
        return result.length > 0 ? result : [
            { label: "5 Min", value: "300" },
            { label: "15 Min", value: "900" },
            { label: "30 Min", value: "1800" },
            { label: "1 Hour", value: "3600" },
            { label: "2 Hours", value: "7200" },
            { label: I18n.tr("Forever"), value: "infinity" }
        ];
    }

    // Control Center Integration
    ccWidgetIcon: "local_cafe"
    ccWidgetPrimaryText: I18n.tr("Caffeinate")
    ccWidgetSecondaryText: {
        // Explicitly depend on caffeinateActive, selectedDuration, and timeLeft
        const active = root.caffeinateActive;
        const dur = root.selectedDuration;
        const remaining = root.timeLeft;

        if (!active) return I18n.tr("Inactive")
        if (dur === "infinity" || dur === "undefined" || !dur) return I18n.tr("Forever")
        if (remaining <= 0) return I18n.tr("Active")
        const mins = Math.ceil(remaining / 60)
        return mins + I18n.tr("m")
    }
    ccWidgetIsActive: caffeinateActive
    ccDetailHeight: {
        const rows = Math.ceil(durationOptions.length / 3);
        const headerHeight = 64 + Theme.spacingS;
        const gridHeight = rows * 48 + Math.max(0, rows - 1) * Theme.spacingS;
        const customInputHeight = 36 + Theme.spacingS;
        return headerHeight + gridHeight + customInputHeight + Theme.spacingM * 2;
    }

    readonly property color pillColor: caffeinateActive ? Theme.primary : Theme.surfaceText

    // All three sizes derive from barIconSize so the pill tracks bar thickness, iconScale,
    // and maximizeWidgetIcons the way native widgets do, rather than a fixed Theme.iconSize.
    //
    // The footprint stays constant across states; only what fills it changes. Idle draws a
    // bare glyph at the same -4 offset every other bar icon uses, so it sits among its
    // neighbours as an ordinary glyph. Active swaps in the ring at the full offset-0
    // diameter and shrinks the glyph to leave it room to orbit.
    readonly property real barPillIconSize: Theme.barIconSize(barThickness, 0, barConfig?.maximizeWidgetIcons, barConfig?.iconScale)
    readonly property real barIdleGlyphSize: Theme.barIconSize(barThickness, -4, barConfig?.maximizeWidgetIcons, barConfig?.iconScale)
    readonly property real barActiveGlyphSize: Math.round(barPillIconSize * Theme.iconSizeSmall / Theme.iconSize)

    // The ring means "counting down", so it appears only for a timed session: drawn at a
    // fixed 360 it would read as a progress bar that never moves. A session with no end
    // is carried by the accent colour alone.
    readonly property bool showCountdownRing: caffeinateActive && selectedDuration !== "infinity"

    function ringAngle() {
        if (selectedDuration === "infinity") return 360;
        const total = parseInt(selectedDuration);
        if (isNaN(total) || total <= 0) return 360;
        return 360 * (timeLeft / total);
    }

    // Both orientations are the same square glyph. The remaining time lives in the ring
    // and in the popout, so the pill never grows to hold a label and the bar layout stays
    // put whether or not a session is running.
    readonly property Component barPill: Component {
        Item {
            implicitWidth: root.barPillIconSize
            implicitHeight: root.barPillIconSize

            // Sibling of the glyph, not its parent: hiding the ring must not take the
            // mug with it.
            RadialProgressRing {
                anchors.fill: parent
                visible: root.showCountdownRing
                radius: root.barPillIconSize / 2 - strokeWidth - 1
                strokeWidth: 1.5
                color: root.pillColor
                active: root.caffeinateActive
                backgroundOpacityActive: 0.2
                angle: root.ringAngle()
            }

            CaffeinateMark {
                size: root.showCountdownRing ? root.barActiveGlyphSize : root.barIdleGlyphSize
                markColor: root.pillColor
                strokeWeight: 2.0
                anchors.centerIn: parent
            }
        }
    }

    horizontalBarPill: barPill
    verticalBarPill: barPill

    // Click action: always open duration picker popout (via null fallback)
    pillClickAction: null

    // Right click: quick toggle stay-awake with default duration
    pillRightClickAction: function() {
        toggleCaffeinate()
    }

    // Popout dimensions
    popoutWidth: 360
    popoutHeight: 0 // auto from content

    // Popout content: duration selector grid
    popoutContent: Component {
        PopoutComponent {
            id: popoutScope
            headerText: I18n.tr("Caffeinate")
            showCloseButton: true
            // Start the cursor on the selected preset rather than on whatever happens to be
            // first, and keep it unpainted until the keyboard is actually used — parked at a
            // fixed index it reads as a second kind of selection and muddies the border.
            property int currentIndex: Math.max(0, root.durationOptions.findIndex(o => String(o.value) === String(root.selectedDuration)))
            property bool keyboardActive: false

            // Keyboard navigation
            Keys.onPressed: function(event) {
                popoutScope.keyboardActive = true
                const cols = 3
                const count = root.durationOptions.length
                let idx = popoutScope.currentIndex
                if (event.key === Qt.Key_Right) {
                    idx = (idx + 1) % count
                    event.accepted = true
                } else if (event.key === Qt.Key_Left) {
                    idx = (idx - 1 + count) % count
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    idx = Math.min(idx + cols, count - 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    idx = Math.max(idx - cols, 0)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                    if (idx >= 0 && idx < count) {
                        root.selectDuration(root.durationOptions[idx].value)
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    closePopout()
                    event.accepted = true
                }
                if (event.accepted) {
                    popoutScope.currentIndex = idx
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingM
                leftPadding: Theme.spacingM
                rightPadding: Theme.spacingM

                Row {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: Theme.spacingM

                    Loader {
                        sourceComponent: animatedCoffeeCup
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - 56 - Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: root.statusHeadline()
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: root.statusSubline()
                            font.pixelSize: Theme.fontSizeSmall
                            color: root.caffeinateActive ? Theme.primary : Theme.surfaceVariantText
                        }
                    }
                }

                Grid {
                    id: durationGrid
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    columns: 3
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.durationOptions

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: (parent.width - Theme.spacingS * 2) / 3
                            height: 48
                            radius: Theme.cornerRadius
                            color: {
                                if (popoutScope.keyboardActive && popoutScope.currentIndex === index) return Theme.primaryPressed
                                if (optionMouseArea.containsMouse) return Theme.surfaceContainerHighest
                                return "transparent"
                            }
                            border.color: root.selectedDuration === modelData.value ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                            border.width: root.selectedDuration === modelData.value ? 2 : 1

                            MouseArea {
                                id: optionMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof popoutScope !== 'undefined') popoutScope.currentIndex = index
                                    root.selectDuration(modelData.value)
                                    if (typeof popoutScope !== 'undefined') closePopout()
                                }
                            }

                            StyledText {
                                text: modelData.label
                                color: root.selectedDuration === modelData.value ? Theme.primary : Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: root.selectedDuration === modelData.value ? Font.Medium : Font.Normal
                                anchors.centerIn: parent
                            }

                            Keys.onReturnPressed: function(event) {
                                popoutScope.currentIndex = index
                                root.selectDuration(modelData.value)
                                event.accepted = true
                            }
                            Keys.onSpacePressed: function(event) {
                                popoutScope.currentIndex = index
                                root.selectDuration(modelData.value)
                                event.accepted = true
                            }
                        }
                    }
                }

                Row {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: Theme.spacingS

                    DankTextField {
                        id: customTimeInput
                        width: parent.width - btnSet.width - Theme.spacingS
                        height: 36
                        placeholderText: I18n.tr("Custom minutes...")
                        validator: IntValidator { bottom: 1; top: 1440 }
                        
                        onAccepted: btnSet.clicked()
                    }

                    DankButton {
                        id: btnSet
                        text: I18n.tr("Set")
                        height: 36
                        onClicked: {
                            const mins = parseInt(customTimeInput.text.trim());
                            if (!isNaN(mins) && mins > 0) {
                                const value = (mins * 60).toString();
                                root.selectDuration(value);
                                customTimeInput.text = "";
                                closePopout();
                            }
                        }
                    }
                }

                // The picker can only start or re-time a session, never stop one, so
                // stopping needs somewhere obvious to live. Hidden while idle: there is
                // nothing to stop, and a dead control reads as a broken one.
                DankButton {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    text: I18n.tr("Decaffeinate")
                    iconName: "bedtime"
                    buttonHeight: 36
                    backgroundColor: Theme.surfaceContainerHighest
                    textColor: Theme.surfaceText
                    visible: root.caffeinateActive
                    onClicked: {
                        root.toggleCaffeinate();
                        closePopout();
                    }
                }
            }
        }
    }

    onCcWidgetToggled: {
        toggleCaffeinate()
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            globalTimeLeft.set(globalTimeLeft.value - 1);
            if (globalTimeLeft.value <= 0) {
                countdownTimer.stop();
                deactivateCaffeinate("timeout"); // Turn off caffeinate
            }
        }
    }

    // Sync with system state on startup
    Component.onCompleted: {
        Proc.runCommand("check-caffeinate-active", ["pgrep", "-f", "Caffeinate"], function(output, exitCode) {
            const isActive = (exitCode === 0 && output.trim() !== "");
            if (isActive) {
                globalIsActive.set(true);
                const expiration = pluginService ? pluginService.loadPluginState(pluginId, "expiration", 0) : 0;
                if (expiration > Date.now()) {
                    globalTimeLeft.set(Math.round((expiration - Date.now()) / 1000));
                    countdownTimer.start();
                }
                if (typeof SessionService !== "undefined") {
                    SessionService.enableIdleInhibit();
                }
            } else {
                globalIsActive.set(false);
                if (pluginService) {
                    pluginService.savePluginState(pluginId, "expiration", 0);
                }
            }
            // Trigger auto-checks after we sync caffeinate state!
            checkAutoActivation();
            checkBatteryStatus();
        })
    }

    // The two status lines read as one sentence: the headline says what is happening and
    // the subline completes it. Shared so the bar popout and the Control Center detail
    // cannot drift apart.
    function statusHeadline() {
        return caffeinateActive ? I18n.tr("Caffeinating...") : I18n.tr("Decaffeinated");
    }

    function statusSubline() {
        if (!caffeinateActive) return I18n.tr("Select a duration to caffeinate");
        if (selectedDuration === "infinity") return I18n.tr("Indefinitely");
        const mins = Math.ceil(timeLeft / 60);
        if (mins <= 0) return I18n.tr("for less than a minute");
        if (mins === 1) return I18n.tr("for one more minute");
        return I18n.tr("for another %1 minutes").arg(mins);
    }

    function formatDurationLabel(dur) {
        if (dur === "infinity") return I18n.tr("indefinitely");
        const secs = parseInt(dur);
        if (isNaN(secs) || secs <= 0) return dur;
        const mins = secs / 60;
        if (mins < 60) {
            return mins + " " + I18n.tr("minutes");
        }
        const hrs = mins / 60;
        if (hrs === 1) return I18n.tr("1 hour");
        return hrs.toFixed(1).replace(".0", "") + " " + I18n.tr("hours");
    }

    // What a preset click means: start a session when idle, re-time a running one when a
    // different preset is picked, and do nothing when the running preset is picked again.
    // Stopping is deliberately not here — that is the Decaffeinate button or a right-click
    // on the pill, so a stray click in the picker can never kill a session.
    function selectDuration(value) {
        if (caffeinateActive && String(selectedDuration) === String(value)) return;
        changeDuration(value);
        if (!caffeinateActive) toggleCaffeinate(value);
    }

    function changeDuration(newDuration) {
        if (newDuration === undefined || newDuration === null || newDuration === "undefined" || newDuration === "") return;
        selectedDuration = newDuration;
        if (pluginService) {
            pluginService.savePluginData(pluginId, "selectedDuration", newDuration);
        }

        if (caffeinateActive) {
            if (globalIsAutoActive.value) {
                globalIsAutoActive.set(false);
            }
            // Keep active, but update the duration!
            // 1. Kill the old process
            Proc.runCommand("deactivate-caffeinate", ["pkill", "-f", "Caffeinate"], null, 0);

            // 2. Start the new process with new duration
            const args = [
                "systemd-inhibit", 
                "--what=idle", 
                "--who=Caffeinate", 
                "--why=Manual stay awake override"
            ];
            if (newDuration === "infinity") {
                args.push("sleep", "infinity");
            } else {
                args.push("sleep", newDuration);
            }
            Quickshell.execDetached(args);

            // 3. Update timer
            countdownTimer.stop();
            if (newDuration !== "infinity") {
                const durationSecs = parseInt(newDuration);
                globalTimeLeft.set(durationSecs);
                const expiration = Date.now() + durationSecs * 1000;
                if (pluginService) {
                    pluginService.savePluginState(pluginId, "expiration", expiration);
                }
                countdownTimer.restart();
            } else {
                if (pluginService) {
                    pluginService.savePluginState(pluginId, "expiration", 0);
                }
            }

            if (showToasts) {
                ToastService?.showSuccess(I18n.tr("Duration updated: stay awake for ") + formatDurationLabel(newDuration) + ".")
            }

            if (typeof SessionService !== "undefined") {
                SessionService.enableIdleInhibit();
            }
        }
    }

    function deactivateCaffeinate(reason) {
        if (!globalIsActive.value) return;

        // Reset activation flags
        globalIsActive.set(false);
        globalIsAutoActive.set(false);

        // Determine if we need to set manual override off flag
        if (reason === "manual-toggle" && globalIsAutoActive.value) {
            globalManualOverrideOff.set(true);
        } else if (reason !== "preserve-override") {
            globalManualOverrideOff.set(false);
        }

        // Stop any running countdown
        countdownTimer.stop();

        // Clear stored expiration state
        if (pluginService) {
            pluginService.savePluginState(pluginId, "expiration", 0);
        }

        // Kill the inhibitor process
        Proc.runCommand("deactivate-caffeinate", ["pkill", "-f", "Caffeinate"], function(output, exitCode) {
            if (showToasts) {
                if (reason === "battery") {
                    ToastService?.showWarning(
                        I18n.tr("Low Battery"),
                        I18n.tr("Stay awake disabled to save power.")
                    );
                } else if (reason !== "lock" && reason !== "silent") {
                    ToastService?.showInfo(I18n.tr("Screen sleep is now allowed."));
                }
            }
        });

        // Allow the session to sleep again
        if (typeof SessionService !== "undefined") {
            SessionService.disableIdleInhibit();
        }
    }

    function toggleCaffeinate(duration) {
        if (batteryIntegrationEnabled && typeof BatteryService !== "undefined" && BatteryService.batteryAvailable && !BatteryService.isCharging && BatteryService.batteryLevel <= batteryLowThreshold) {
            if (!globalIsActive.value) {
                ToastService?.showWarning(
                    I18n.tr("Low Battery"),
                    I18n.tr("Cannot enable stay-awake when battery is low.")
                );
                return;
            }
        }

        let targetDuration = duration !== undefined ? duration : selectedDuration;
        if (targetDuration === undefined || targetDuration === null || targetDuration === "undefined" || targetDuration === "") {
            targetDuration = "infinity";
        }
        if (globalIsActive.value) {
            deactivateCaffeinate("manual-toggle");
        } else {
            // Activate
            const args = [
                "systemd-inhibit", 
                "--what=idle", 
                "--who=Caffeinate", 
                "--why=Manual stay awake override"
            ];
            if (targetDuration === "infinity") {
                args.push("sleep", "infinity");
            } else {
                args.push("sleep", targetDuration);
            }
            Quickshell.execDetached(args);
            
            if (targetDuration !== "infinity") {
                const durationSecs = parseInt(targetDuration);
                globalTimeLeft.set(durationSecs);
                const expiration = Date.now() + durationSecs * 1000;
                if (pluginService) {
                    pluginService.savePluginState(pluginId, "expiration", expiration);
                }
                countdownTimer.restart();
            } else {
                if (pluginService) {
                    pluginService.savePluginState(pluginId, "expiration", 0);
                }
            }

            globalIsActive.set(true);
            
            if (showToasts) {
                ToastService?.showSuccess(targetDuration === "infinity" ? I18n.tr("Screen will stay awake.") : I18n.tr("Screen will stay awake for ") + formatDurationLabel(targetDuration) + ".")
            }

            if (typeof SessionService !== "undefined") {
                SessionService.enableIdleInhibit();
            }
        }
    }

    function activateCaffeinateAuto(targetDuration) {
        if (batteryIntegrationEnabled && typeof BatteryService !== "undefined" && BatteryService.batteryAvailable && !BatteryService.isCharging && BatteryService.batteryLevel <= batteryLowThreshold) {
            return;
        }

        if (globalIsActive.value) return;

        const args = [
            "systemd-inhibit", 
            "--what=idle", 
            "--who=Caffeinate Auto", 
            "--why=Automated stay awake override"
        ];
        if (targetDuration === "infinity") {
            args.push("sleep", "infinity");
        } else {
            args.push("sleep", targetDuration);
        }
        Quickshell.execDetached(args);
        
        if (targetDuration !== "infinity") {
            const durationSecs = parseInt(targetDuration);
            globalTimeLeft.set(durationSecs);
            const expiration = Date.now() + durationSecs * 1000;
            if (pluginService) {
                pluginService.savePluginState(pluginId, "expiration", expiration);
            }
            countdownTimer.restart();
        } else {
            if (pluginService) {
                pluginService.savePluginState(pluginId, "expiration", 0);
            }
        }

        globalIsActive.set(true);
        globalIsAutoActive.set(true);
        
        if (showToasts) {
            ToastService?.showSuccess(I18n.tr("Screen will stay awake automatically."))
        }

        if (typeof SessionService !== "undefined") {
            SessionService.enableIdleInhibit();
        }
    }

    function deactivateCaffeinateAuto() {
        deactivateCaffeinate("auto");
    }

    function checkAutoActivation() {
        let shouldActivate = false;

        // 1. App Automation
        if (appAutomationEnabled) {
            const apps = parsedAutoApps;
            if (apps.length > 0 && typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels?.values) {
                for (const toplevel of ToplevelManager.toplevels.values) {
                    const appId = (toplevel.appId || "").toLowerCase();
                    const title = (toplevel.title || "").toLowerCase();
                    
                    const matches = apps.some(app => {
                        return appId.includes(app) || title.includes(app);
                    });
                    
                    if (matches) {
                        shouldActivate = true;
                        break;
                    }
                }
            }
        }

        // 2. Full Screen Awareness
        if (!shouldActivate && fullscreenAwarenessEnabled) {
            if (typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels?.values) {
                for (const toplevel of ToplevelManager.toplevels.values) {
                    if (toplevel.fullscreen && toplevel.activated) {
                        shouldActivate = true;
                        break;
                    }
                }
            }
        }

        if (shouldActivate) {
            if (!globalIsActive.value) {
                if (!globalManualOverrideOff.value) {
                    activateCaffeinateAuto("infinity");
                }
            }
        } else {
            globalManualOverrideOff.set(false);
            if (globalIsAutoActive.value) {
                deactivateCaffeinateAuto();
            }
        }
    }

    function checkBatteryStatus() {
        if (!batteryIntegrationEnabled) return;
        if (typeof BatteryService === "undefined" || !BatteryService.batteryAvailable) return;
        
        if (!BatteryService.isCharging && BatteryService.batteryLevel <= batteryLowThreshold) {
            deactivateCaffeinate("battery");
        }
    }

    onAppAutomationEnabledChanged: checkAutoActivation()
    onAutoAppsListChanged: checkAutoActivation()
    onFullscreenAwarenessEnabledChanged: checkAutoActivation()
    onBatteryIntegrationEnabledChanged: {
        checkBatteryStatus();
        checkAutoActivation();
    }
    onBatteryLowThresholdChanged: checkBatteryStatus()

    Connections {
        target: (typeof ToplevelManager !== "undefined") ? ToplevelManager : null
        ignoreUnknownSignals: true
        function onActiveToplevelChanged() {
            checkAutoActivation();
        }
    }

    Connections {
        target: (typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels) ? ToplevelManager.toplevels : null
        ignoreUnknownSignals: true
        function onValuesChanged() {
            checkAutoActivation();
        }
    }

    Connections {
        target: (typeof CompositorService !== "undefined") ? CompositorService : null
        ignoreUnknownSignals: true
        function onToplevelsChanged() {
            checkAutoActivation();
        }
    }

    Connections {
        target: (typeof BatteryService !== "undefined") ? BatteryService : null
        ignoreUnknownSignals: true
        function onBatteryLevelChanged() {
            checkBatteryStatus();
        }
        function onIsChargingChanged() {
            checkBatteryStatus();
        }
    }

    Connections {
        target: (typeof SessionService !== "undefined") ? SessionService : null
        ignoreUnknownSignals: true
        function onLockedChanged() {
            if (SessionService.locked && deactivateOnManualLock && globalIsActive.value) {
                deactivateCaffeinate("lock");
            }
        }
    }

    Timer {
        id: autoCheckTimer
        interval: 2000
        repeat: true
        running: appAutomationEnabled || fullscreenAwarenessEnabled || batteryIntegrationEnabled
        onTriggered: {
            checkAutoActivation();
            checkBatteryStatus();
        }
    }

    ccDetailContent: Component {
        Rectangle {
            id: detailRoot
            implicitHeight: detailColumn.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh
            border.width: 0

            Column {
                id: detailColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    bottomPadding: Theme.spacingXS

                    Loader {
                        sourceComponent: animatedCoffeeCup
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - 56 - Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: root.statusHeadline()
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: root.statusSubline()
                            font.pixelSize: Theme.fontSizeSmall
                            color: root.caffeinateActive ? Theme.primary : Theme.surfaceVariantText
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 3
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.durationOptions

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: (parent.width - Theme.spacingS * 2) / 3
                            height: 48
                            radius: Theme.cornerRadius
                            color: optionMouseArea.containsMouse
                                ? Theme.surfaceContainerHighest
                                : "transparent"
                            border.color: root.selectedDuration === modelData.value ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                            border.width: root.selectedDuration === modelData.value ? 2 : 1

                            MouseArea {
                                id: optionMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectDuration(modelData.value)
                            }

                            StyledText {
                                text: modelData.label
                                color: root.selectedDuration === modelData.value ? Theme.primary : Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: root.selectedDuration === modelData.value ? Font.Medium : Font.Normal
                                anchors.centerIn: parent
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    topPadding: Theme.spacingXS

                    DankTextField {
                        id: customTimeInputCC
                        width: parent.width - btnSetCC.width - Theme.spacingS
                        height: 36
                        placeholderText: I18n.tr("Custom minutes...")
                        validator: IntValidator { bottom: 1; top: 1440 }
                        
                        onAccepted: btnSetCC.clicked()
                    }

                    DankButton {
                        id: btnSetCC
                        text: I18n.tr("Set")
                        height: 36
                        onClicked: {
                            const mins = parseInt(customTimeInputCC.text.trim());
                            if (!isNaN(mins) && mins > 0) {
                                const value = (mins * 60).toString();
                                root.selectDuration(value);
                                customTimeInputCC.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}

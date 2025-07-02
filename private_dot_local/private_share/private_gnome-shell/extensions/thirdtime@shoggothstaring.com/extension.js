/* extension.js
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import GObject from 'gi://GObject';
import St from 'gi://St';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio'; // Needed for spawn_sync
import Clutter from 'gi://Clutter'; // <-- Added import

import {Extension, gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const UPDATE_INTERVAL_SECONDS = 1;
let DEBT_THRESHOLD_SECONDS = -60;

// Function to read WORK_COEFFICIENT from $HOME/.config/nthtime
function readWorkCoefficient() {
    const configFilePath = GLib.build_filenamev([GLib.get_home_dir(), '.config', 'nthtime']);
    try {
        const file = Gio.File.new_for_path(configFilePath);
        const [ok, content] = file.load_contents(null);
        if (ok) {
            const coefficient = parseInt(content.toString().trim(), 10);
            if (!isNaN(coefficient) && coefficient > 0) { return coefficient; // Return the valid coefficient
            }
        }
    } catch (e) {
        log(`Failed to read WORK_COEFFICIENT from ${configFilePath}: ${e}`);
    }
    return 3; // Default value if reading fails or invalid
}

let WORK_COEFFICIENT = readWorkCoefficient(); // Read from config file

function runTimewarriorSync(args) {
    try {
        // Construct the command array
        let command = ['timew'];
        command.push(...args);

        // GLib.spawn_sync with correct number of arguments
        let [ok, stdout, stderr, exitStatus] = GLib.spawn_sync(
            null, // working directory
            command, // argv
            null, // envp
            GLib.SpawnFlags.SEARCH_PATH, // flags
            null // child_setup
        );

        if (!ok || exitStatus !== 0) {
            log(`Timewarrior error (${exitStatus}): ${stderr ? new TextDecoder().decode(stderr) : 'Unknown error'}`);
            return "";
        }

        return new TextDecoder().decode(stdout).trim();

    } catch (e) {
        log(`Failed to run timewarrior: ${e}`);
        return "";
    }
}
// Helper to get total seconds from timewarrior summary
function getSecondsFromTag(tag) {
    const command = ['summary',  tag];
    const output = runTimewarriorSync(command);
    if (output === null || output === "" || output.includes('No filtered data found')) {
        log(`No valid output for tag "${tag}", returning 0 seconds`);
        return 0;
    }
    // Extract the last line, which contains the total time (e.g., "1:01:12")
    const lines = output.split('\n');
    const totalLine = lines[lines.length - 1].trim();
    // Parse HH:MM:SS format
    const timeMatch = totalLine.match(/(\d+):(\d+):(\d+)/);
    if (!timeMatch) {
        log(`Failed to parse total time for tag "${tag}": ${totalLine}`);
        return 0;
    }
    const hours = parseInt(timeMatch[1], 10);
    const minutes = parseInt(timeMatch[2], 10);
    const seconds = parseInt(timeMatch[3], 10);
    const totalSeconds = hours * 3600 + minutes * 60 + seconds;
    return totalSeconds;
}
// Helper to get current tracking state
function getCurrentState(output) {
    if (output === null) {
        return 'unknown'; // Error or not installed
    }

    if (output.includes('work')) {
        return 'working';
    } else if (output.includes('rest')) {
        return 'resting';
    } else if (output.includes('There is no active time tracking.')) {
        return 'unknown';
    } else {
         // Might be a summary or other output if not tracking
         // Re-check with 'get' for a more specific check
         const activeOutput = runTimewarriorSync(['get', 'dom.active.json']);
         if (activeOutput && activeOutput.includes('"tags":["work"')) {
             return 'working';
         } else if (activeOutput && activeOutput.includes('"tags":["rest"')) {
             return 'resting';
         }
         return 'unknown';
    }
}

// Helper to format seconds to MM:SS
function formatSeconds(totalSeconds) {
    const isNegative = totalSeconds < 0;
    if (isNegative) {
        totalSeconds = -totalSeconds;
    }

    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;

    const sign = isNegative ? '-' : '';
    const mm = String(minutes).padStart(2, '0');
    const ss = String(seconds).padStart(2, '0');

    return `${sign}${mm}:${ss}`;
}


const RestEquityIndicator = GObject.registerClass(
class RestEquityIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.5, _('Rest Equity Timer'));

        this._label = new St.Label({
            text: _('...'),
            y_align: Clutter.ActorAlign.CENTER,
            style_class: 'rest-equity-label',
        });
        this.add_child(this._label);

        this._timeoutId = null;
        this._updateLoop(); // Start the update loop
    }
    _updateData() {
        const workTime = getSecondsFromTag('work');
        const restTime = getSecondsFromTag('rest');
        const output = runTimewarriorSync([]);
        const currentState = getCurrentState(output);

        const restEquity = Math.round(workTime / WORK_COEFFICIENT - restTime);
        const newText = formatSeconds(restEquity) + output.split('\n')[0] + " ";

        this._label.set_text(newText);

        // Remove previous styles
        this._label.remove_style_class_name('rest-equity-working');
        this._label.remove_style_class_name('rest-equity-resting');
        this._label.remove_style_class_name('rest-equity-unknown');
        this._label.remove_style_class_name('rest-equity-debt');

        // Apply new style based on priority
        if (restEquity < DEBT_THRESHOLD_SECONDS) {
            this._label.add_style_class_name('rest-equity-debt');
        } else if (currentState === 'working') {
            this._label.add_style_class_name('rest-equity-working');
        } else if (currentState === 'resting') {
            this._label.add_style_class_name('rest-equity-resting');
        } else {
            this._label.add_style_class_name('rest-equity-unknown');
        }

        // log(`Updated: W=${workTime}s, R=${restTime}s, Eq=${restEquity}s (${newText}), State=${currentState}`);
    }

    _updateLoop() {
        this._updateData(); // Update immediately

        // Schedule the next update
        this._timeoutId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT,
            UPDATE_INTERVAL_SECONDS,
            () => {
                this._updateData();
                return GLib.SOURCE_CONTINUE; // Keep the timer running
            }
        );
    }

    destroy() {
        if (this._timeoutId) {
            GLib.Source.remove(this._timeoutId);
            this._timeoutId = null;
        }
        super.destroy();
    }
});

export default class TimewarriorRestEquityExtension extends Extension {
    enable() {
        this._indicator = new RestEquityIndicator();
        Main.panel.addToStatusArea(this.uuid, this._indicator);
    }

    disable() {
        this._indicator.destroy();
        this._indicator = null;
    }
}

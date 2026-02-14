/* capture.vala
 *
 * Copyright 2026 Vasiliy Doylov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class EyeNeko.Elements.Capture : NekoTee.TeeChild {
    static construct {
        set_static_metadata ("CaptureTeeChild",
                             "Sink",
                             "Child of NekoTee that captures some frames and handle EOS",
                             "nekocwd@mainlining.org");

        add_static_pad_template (
        {
            "sink",
            Gst.PadDirection.SINK,
            Gst.PadPresence.ALWAYS,
            { null, "ANY" }
        });
    }
    public bool detach_on_eos { get; set; default = false; }

    static void bin2sink (Gst.Bin bin) {
        var first_element = (Gst.Element) bin.get_child_by_index (bin.get_children_count () - 1);
        bin.add_pad (new Gst.GhostPad ("sink", first_element.get_static_pad ("sink")));
    }

    public Capture (Gst.Bin bin, string name) {
        bin.name = "%s Pipeline".printf (name);
        bin2sink (bin);
        base (name, bin);
    }

    public Capture.from_string (string pipeline, string name) {
        // TODO: add error handling
        var bin = (Gst.Bin) Gst.parse_launch (pipeline);
        this(bin, name);
    }

    public void send_eos () {
        element.send_event (new Gst.Event.eos ());
    }

    public override bool post_message (owned Gst.Message message) {
        if (message.type == EOS) {
            GLib.message ("%s EOS catched2 :)", message.src.name);
            return false;
        }
        return base.post_message (message);
    }

    public override void handle_message (owned Gst.Message message) {
        if (message.type == EOS) {
            debug ("%s: %s EOS catched", name, message.src.name);
            if (detach_on_eos)
                Idle.add_once (() => detach ());
            return;
        }
        base.handle_message (message);
    }
}

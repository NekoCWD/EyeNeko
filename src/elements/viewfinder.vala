/* viewfinder.vala
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

public class EyeNeko.Elements.Viewfinder : Capture {
    static construct {
        set_static_metadata ("ViewfinderTeeChild",
                             "Sink",
                             "Child of NekoTee that display things on gtk4paintable",
                             "nekocwd@mainlining.org");

        add_static_pad_template (
        {
            "sink",
            Gst.PadDirection.SINK,
            Gst.PadPresence.ALWAYS,
            { null, "ANY" }
        });
    }
    public Gdk.Paintable paintable { get; construct; }
    public Viewfinder () {
        dynamic var vf = Gst.ElementFactory.make ("gtk4paintablesink", "Viewfinder Element");
        dynamic var elem = vf;
        dynamic Gdk.Paintable? pa = vf.paintable;
        if (pa.gl_context == null) {
            warning_once ("GL acceleration is not available! Performance will be bad");
        } else {
            elem = Gst.ElementFactory.make ("glsinkbin");
            elem.sink = vf;
        }

        Object (element : elem, name: "Viewfinder", paintable: pa, detach_on_eos: false);
    }
}

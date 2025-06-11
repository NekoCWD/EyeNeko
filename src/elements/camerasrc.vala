/* downscale.vala
 *
 * Copyright 2025 Vasiliy Doylov <nekocwd@mainlining.org>
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

public class EyeNeko.Elements.CameraSrc : BinBase {
    public Gst.Element source = null;
    public Gst.Element capsfilter = Gst.ElementFactory.make ("capsfilter", "capsfilter");
    public Gst.Element decodebin = Gst.ElementFactory.make ("decodebin3", "decoder");
    public Gst.Element identity = Gst.ElementFactory.make ("identity");

    static construct {
        set_static_metadata ("camerasrc",
                             "Source",
                             "Camera source",
                             "nekocwd@mainlining.org");
    }

    public CameraSrc (Gst.Element src, Gst.Caps caps = new Gst.Caps.any ()) {
        source = src;
        add_many (source, capsfilter, decodebin, identity);
        source.link_many (capsfilter, decodebin);
        capsfilter.set_property ("caps", caps);
        decodebin.pad_added.connect ((pad) => {
            if (pad.get_stream () != null && pad.get_stream ().stream_type == Gst.StreamType.VIDEO) {
                pad.link (identity.get_static_pad ("sink"));
            }
        });
        add_pads (null, identity);
    }
}

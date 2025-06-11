/* bin_base.vala
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

public class EyeNeko.Elements.BinBase : Gst.Bin {
    protected Gst.Pad sinkpad;
    protected Gst.Pad srcpad;

    static construct {
        add_static_pad_template(
        {
            "sink",
            Gst.PadDirection.SINK,
            Gst.PadPresence.ALWAYS,
            { null, "video/x-raw" }
        });
        add_static_pad_template(
        {
            "src",
            Gst.PadDirection.SRC,
            Gst.PadPresence.ALWAYS,
            { null, "video/x-raw" }
        });
    }

    protected void add_pads(Gst.Element? sink, Gst.Element? src) {
        if (sink != null) {
            sinkpad = new Gst.GhostPad("sink", sink.get_static_pad("sink"));
            add_pad(sinkpad);
        }
        if (src != null) {
            srcpad = new Gst.GhostPad("src", src.get_static_pad("src"));
            add_pad(srcpad);
        }
    }
}

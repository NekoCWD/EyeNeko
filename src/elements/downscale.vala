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

public class EyeNeko.Elements.Downscale : BinBase {
    public Gst.Element videoscale = Gst.ElementFactory.make ("videoscale");
    public Gst.Element capsfilter = Gst.ElementFactory.make ("capsfilter");
    public int max_size { get; set; default = 0; }

    static construct {
        set_static_metadata ("downscale",
                             "Filter",
                             "Downscale video filter.",
                             "nekocwd@mainlining.org");
    }

    static bool sink_event (Gst.Pad pad, Gst.Object? parent, owned Gst.Event event) {
        var filter = (Downscale) parent;
        switch (event.type) {
        // Reset capsfilter on stream start/stop
        case Gst.EventType.STREAM_START :
        case Gst.EventType.STREAM_COLLECTION:
            filter.capsfilter.set_property ("caps", new Gst.Caps.any ());
            break;
        case Gst.EventType.CAPS:
            Gst.Caps caps;
            event.parse_caps (out caps);
            var info = new Gst.Video.Info.with_caps (caps);
            var old_info = info.copy ();
            var max_dim = int.max (info.width, info.height);
            if (filter.max_size > 0 && max_dim > filter.max_size) {
                double mult = (double) filter.max_size / (double) max_dim;
                info.width = (int) (info.width * mult);
                info.height = (int) (info.height * mult);
            }
            if (info.width % 2 > 0)
                info.width++;
            if (info.height % 2 > 0)
                info.height++;
            debug ("%dx%d=S=>%dx%d", old_info.width, old_info.height, info.width, info.height);
            var new_caps = caps.copy ();
            new_caps.set_simple ("width", typeof (int), info.width);
            new_caps.set_simple ("height", typeof (int), info.height);
            filter.capsfilter.set_property ("caps", new_caps);
            break;
        default:
            break;
        }
        return pad.event_default (parent, event);
    }

    public Downscale () {}
    public Downscale.to (int max_size) {
        _max_size = max_size;
    }

    construct {
        add_many (videoscale, capsfilter);
        videoscale.link (capsfilter);
        add_pads (videoscale, capsfilter);
        sinkpad.set_event_function (sink_event, null, null);
    }
}

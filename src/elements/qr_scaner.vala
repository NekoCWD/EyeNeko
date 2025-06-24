/* qr_detector.vala
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

public class EyeNeko.Elements.QrScaner : Gst.Base.Transform {
    static construct {
        set_static_metadata ("QRScaner",
                             "Filter",
                             "Downscale video filter.",
                             "nekocwd@mainlining.org");

        add_static_pad_template (
        {
            "sink",
            Gst.PadDirection.SINK,
            Gst.PadPresence.ALWAYS,
            { null, "video/x-raw" }
        });
        add_static_pad_template (
        {
            "src",
            Gst.PadDirection.SRC,
            Gst.PadPresence.ALWAYS,
            { null, "video/x-raw" }
        });
    }

    public Gee.HashSet<string> qr_codes = new Gee.HashSet<string> ();
    public signal void new_qr (string data);

    public bool enabled { get; set; }
    public bool can_scan { get; private set; }

    private ZBar.ImageScanner scaner = new ZBar.ImageScanner ();
    private ZBar.Image image = new ZBar.Image ();

    construct {
        image.format = ZBar.Format.fourcc_parse ("Y800");
    }

    public override bool sink_event (owned Gst.Event event) {
        switch (event.type) {
        case Gst.EventType.CAPS:
            Gst.Caps caps;
            event.parse_caps (out caps);
            var info = new Gst.Video.Info.with_caps (caps);
            can_scan = info.finfo.format == Gst.Video.Format.GRAY8;
            image.set_size (info.width, info.height);
            break;
        default:
            break;
        }
        return base.sink_event (event);
    }

    public override Gst.FlowReturn transform_ip (Gst.Buffer buf) {
        if (!can_scan || !enabled)
            return Gst.FlowReturn.OK;

        uint8[] img;
        buf.extract_dup (0, buf.get_size (), out img);
        image.set_data ((void[]) img, () => {}); // Don't free data
        scaner.scan_image (image);
        for (unowned var sym = image.first_symbol (); sym != null; sym = sym.next ()) {
            unowned var data = sym.get_data ();
            if (qr_codes.add (data)) {
                GLib.Idle.add (() => { // HACK it fixes GTK crash
                    new_qr (data);
                    return false;
                }, Priority.DEFAULT);
            }
        }
        return Gst.FlowReturn.OK;
    }
}

/* color_correction_matrix.vala
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

public class EyeNeko.Elements.ColorCorrectionMatrix : GLFilter {
    public float red_in_red { get; set; default = 1.0f; }
    public float red_in_green { get; set; default = 0.0f; }
    public float red_in_blue { get; set; default = 0.0f; }

    public float green_in_red { get; set; default = 0.0f; }
    public float green_in_green { get; set; default = 1.0f; }
    public float green_in_blue { get; set; default = 0.0f; }

    public float blue_in_red { get; set; default = 0.0f; }
    public float blue_in_green { get; set; default = 0.0f; }
    public float blue_in_blue { get; set; default = 1.0f; }

    static construct {
        set_static_metadata("colorcorrectionmatrix",
                            "Filter",
                            "Color correction matrix video filter.",
                            "nekocwd@mainlining.org");
    }

    construct {
        set_shader("ccm");
    }

    protected override void update_uniforms() {
        Gst.Structure uniforms = new Gst.Structure.empty("uniforms");
        uniforms.set("rr", typeof (float), red_in_red);
        uniforms.set("rg", typeof (float), red_in_green);
        uniforms.set("rb", typeof (float), red_in_blue);
        uniforms.set("gr", typeof (float), green_in_red);
        uniforms.set("gg", typeof (float), green_in_green);
        uniforms.set("gb", typeof (float), green_in_blue);
        uniforms.set("br", typeof (float), blue_in_red);
        uniforms.set("bg", typeof (float), blue_in_green);
        uniforms.set("bb", typeof (float), blue_in_blue);

        glshader.set_property("uniforms", uniforms);
    }
}

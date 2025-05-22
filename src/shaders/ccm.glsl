#version 100
#ifdef GL_ES
precision mediump float;
#endif
varying vec2 v_texcoord;
uniform sampler2D image;

uniform float rr;
uniform float rg;
uniform float rb;

uniform float gr;
uniform float gg;
uniform float gb;

uniform float br;
uniform float bg;
uniform float bb;

void main() {
    vec3 color = texture2D(image, v_texcoord).rgb;
    mat4 matrix = mat4(
            vec4(rr, rg, rb, 0.0),
            vec4(gr, gg, gb, 0.0),
            vec4(br, bg, bb, 0.0),
            vec4(0.0, 0.0, 0.0, 1.0)
        );
    gl_FragColor = matrix * vec4(color, 1.0);
}

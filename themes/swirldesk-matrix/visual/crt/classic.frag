#version 300 es
// SwirlDesk MATRIX CRT classic - static, single texture sample.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;
void main() {
    vec4 pixel = texture(tex, v_texcoord);
    vec3 col = pixel.rgb;
    float scan = 1.0 - 0.095 * step(1.0, mod(floor(gl_FragCoord.y), 3.0));
    vec2 pos = v_texcoord * 2.0 - 1.0;
    float vignette = 1.0 - 0.090 * smoothstep(0.35, 2.0, dot(pos, pos));
    float green = max(0.0, col.g - max(col.r, col.b));
    col += vec3(0.25, 1.0, 0.45) * green * 0.055;
    fragColor = vec4(clamp(col * scan * vignette, 0.0, 1.0), pixel.a);
}

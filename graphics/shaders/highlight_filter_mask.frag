uniform sampler2D texture;
uniform sampler2D mask_texture;
uniform float rgb_add_r;
uniform float rgb_add_g;
uniform float rgb_add_b;
uniform float screen_size_x;
uniform float screen_size_y;
uniform float mask_offset_x;
uniform float mask_offset_y;

void main() {
    vec2 screen_uv = gl_FragCoord.xy / vec2(screen_size_x, screen_size_y);
    vec2 mask_uv = screen_uv + vec2(mask_offset_x, mask_offset_y);

    vec4 base_color = texture2D(texture, gl_TexCoord[0].xy);
    vec4 mask_color_sample = texture2D(mask_texture, mask_uv);

    if (mask_color_sample.r > 0.5) {
        base_color.r += rgb_add_r;
        base_color.g += rgb_add_g;
        base_color.b += rgb_add_b;
    }

    gl_FragColor = base_color;
}


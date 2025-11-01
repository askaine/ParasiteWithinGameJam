shader_type canvas_item;

uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(0.8, 0.8, 0.8, 1.0); // slightly gray-white

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec4 flash = mix(tex, flash_color, flash_strength);
    COLOR = vec4(flash.rgb, tex.a);
}

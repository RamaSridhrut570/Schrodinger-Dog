shader_type canvas_item;

uniform float size : hint_range(0.0, 6.0);
uniform float width : hint_range(0.0, 6.0);
uniform float screen_width;
uniform float screen_height;
uniform sampler2D noise_tex;

uniform vec4 brighter_color = vec4(1.0, 0.8, 0.0, 1.0);
uniform vec4 middle_color  = vec4(1.0, 0.56, 0.0, 1.0);
uniform vec4 darker_color  = vec4(0.64, 0.2, 0.05, 1.0);

uniform float spread : hint_range(0.0, 1.0) = 0.5;
uniform vec2 player_position;
uniform int pixel_amount = 40;

void fragment() {
    vec2 grid_uv = round(UV * float(pixel_amount)) / float(pixel_amount);

    float aspect = screen_width / screen_height;
    vec2 aspect_uv = vec2(grid_uv.x * aspect, grid_uv.y);
    vec2 aspect_player = vec2(player_position.x * aspect, player_position.y);

    float dist = distance(aspect_uv, aspect_player);
    float noise_value = texture(noise_tex, vec2(dist, TIME * 0.1)).r;

    float gradient_value = 1.0 - smoothstep(spread, spread + 0.5, dist / spread);

    float step1 = step(noise_value, gradient_value);
    float step2 = step(noise_value, gradient_value - 0.2);
    float step3 = step(noise_value, gradient_value - 0.4);

    vec3 color_mix = mix(brighter_color.rgb, darker_color.rgb, step1 - step2);
    vec3 final_rgb = mix(color_mix, middle_color.rgb, step2 - step3);

    float h = size * 0.5;
    float l = h - (width * 0.5);
    float alpha = (dist <= h && dist > l) ? 1.0 : 0.0;

    COLOR = vec4(final_rgb, alpha);
}

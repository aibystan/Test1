shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 10.0) = 3.0;
uniform vec4 tint_color : source_color = vec4(0.0, 0.0, 0.0, 0.4);
uniform float overall_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 texel = blur_amount / vec2(textureSize(screen_texture, 0));

	vec4 col = vec4(0.0);
	// 3x3 box blur
	col += texture(screen_texture, uv + vec2(-texel.x, -texel.y));
	col += texture(screen_texture, uv + vec2(0.0,     -texel.y));
	col += texture(screen_texture, uv + vec2( texel.x, -texel.y));
	col += texture(screen_texture, uv + vec2(-texel.x,  0.0));
	col += texture(screen_texture, uv + vec2(0.0,      0.0));
	col += texture(screen_texture, uv + vec2( texel.x,  0.0));
	col += texture(screen_texture, uv + vec2(-texel.x,  texel.y));
	col += texture(screen_texture, uv + vec2(0.0,      texel.y));
	col += texture(screen_texture, uv + vec2( texel.x,  texel.y));
	col /= 9.0;

	// Koyulaştırma tonu ekle
	col.rgb = mix(col.rgb, tint_color.rgb, tint_color.a);
	COLOR = vec4(col.rgb, overall_alpha);
}

#version 120

varying vec2 TexCoords;
uniform sampler2D colortex0;

void main() {
    // Sample and apply gamma correction
	vec3 Color = texture2D(colortex0, TexCoords).rgb;
    Color = pow(Color, vec3(1.0 / 2.2));
    gl_FragData[0] = vec4(Color, 1.0);
}
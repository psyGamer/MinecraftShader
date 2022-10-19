#version 120

varying vec2 TexCoords;
varying vec2 LmCoords;
varying vec3 Normal;
varying vec4 Color;

uniform sampler2D texture;

void main(){
    vec4 albedo = texture2D(texture, TexCoords) * Color;
	// albedo = vec4(TexCoords, 0, 1);
    /* DRAWBUFFERS:012 */
    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(Normal * 0.5 + 0.5, 1);
    gl_FragData[2] = vec4(LmCoords, 0, 1);
}
#version 120

varying vec2 TexCoords;
varying vec2 LmCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec4 Material;

uniform sampler2D texture;
uniform sampler2D lightmap;

void main() {
    vec4 albedo = texture2D(texture, TexCoords) * Color;

    /* DRAWBUFFERS:024 */
    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(Normal, 1);
    gl_FragData[2] = Material;
}
#version 120

#include "settings.glsl"

uniform float frameTimeCounter;

varying vec2 TexCoords;
varying vec2 LmCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec4 WorldPos;
varying vec4 Material;
varying vec4 Entity;

/* DRAWBUFFERS:014 */

uniform sampler2D texture;
uniform sampler2D lightmap;

void main() {
    vec4 albedo = texture2D(texture, TexCoords) * Color;

    #ifndef USE_WATER_TEXTURE
        if (Entity.x == 1) {
            albedo = vec4(Color.rgb, 0.6);	
        }
    #endif

    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(Normal, 1);
    gl_FragData[2] = Material;
}
#version 120

#include "settings.glsl"

attribute vec4 mc_Entity;
attribute vec2 mc_midTexCoord;

uniform float frameTimeCounter;
uniform vec3 cameraPosition;

varying vec2 TexCoords;
varying vec2 LmCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec4 WorldPos;
varying vec4 Material;
varying vec4 Entity;

const float pi = 3.14159265358979323846;

#ifdef WAVY_OBJECTS_ENABLED
    vec3 getWind(vec3 pos) {
        vec3 w 	= pos*vec3(1.0, 0.3, 0.1);
        float tick = frameTimeCounter*pi;

        float m = sin(tick+(pos.x+pos.y+pos.z)*0.5)*0.4+0.6;

        float a 	= sin(tick*1.2+(w.x+w.y+w.z)*1.5)*0.4-0.35;
        float b 	= sin(tick*1.3+(w.x+w.y+w.z)*2.5)*0.2;
        float c 	= sin(tick*1.35+(w.x+w.y+w.z)*2.0)*0.1;

        vec3 w0 	= vec3(a, b, c)*m*0.2;

        float m1 	= sin(tick*1.3+(pos.x+pos.y+pos.z)*0.9)*0.3+0.7;

        float a1	= sin(tick*2.4+(w.x+w.y+w.z)*7.5)*0.4-0.3;
        float b1	= sin(tick*1.8+(w.x+w.y+w.z)*5.5)*0.2;
        float c1	= sin(tick*2.2+(w.x+w.y+w.z)*9.0)*0.1;

        vec3 w1 	= vec3(a1, b1, c1)*m1*0.1;
        return w0+w1;
    }
#endif // WAVY_OBJECTS_ENABLED

void main() {
    vec4 position = gl_Vertex;
    TexCoords = gl_MultiTexCoord0.st;
    Normal = gl_Normal * 0.5 + 0.5;
    Color = gl_Color;

    // Use the texture matrix instead of dividing by 15 to maintain compatiblity for each version of Minecraft
    LmCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    // Transform them into the [0, 1] range
    LmCoords = (LmCoords * 33.05 / 32.0) - (1.05 / 32.0);

    Material = (mc_Entity.x == 1 || mc_Entity.x == 201)
        ? vec4(1, 0, 0, 1)
        : vec4(0, 0, 0, 1);

    Entity = vec4(1);

    #ifdef WAVY_OBJECTS_ENABLED
        if (mc_Entity.x == 1) {
            float offX = position.x + cameraPosition.x + frameTimeCounter;
            float offZ = position.z + cameraPosition.z + frameTimeCounter;
            position.y += sin(offX * 1.2) * 0.2 * cos(offZ * 2) * 0.3 - 0.01;
            position.y += sin(offZ * 1.8) * 0.2 * cos(offX * 3) * 0.2 - 0.01;
        }
    #endif
    // position.xyz += getWind(position.xyz + cameraPosition);

    WorldPos = position;
    WorldPos.xyz += cameraPosition;
    gl_Position = gl_ModelViewProjectionMatrix * position;
}
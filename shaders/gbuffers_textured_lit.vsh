#version 120

#include "settings.glsl"
#include "lib/space_transform.glsl"

attribute vec4 mc_Entity;
attribute vec2 mc_midTexCoord;

uniform float frameTimeCounter;
uniform vec3 cameraPosition;

varying vec2 TexCoords;
varying vec2 LmCoords;
varying vec3 Normal;
varying vec4 Color;
varying vec4 Material;

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
        // vec3 dir = pos * vec3(1.0, 0.2, 0.15);
        // float tick = frameTimeCounter * pi;

        // float xOff = sin(tick * 0.2 + (dir.x, dir.y, dir.z) * 1) * 0.2 - 0.1;
        // float yOff = sin(tick * 0.3 + (dir.x, dir.y, dir.z) * 2) * 0.3 - 0.08;
        // float zOff = sin(tick * 0.1 + (dir.x, dir.y, dir.z) * 3) * 0.5 - 0.11;
        // float wOff = sin(tick * 0.6 + (dir.x, dir.y, dir.z) * 4) * 0.4 - 0.15;

        // return vec3(xOff, yOff, zOff) * wOff;

        // sin((blue channel x Pi) + time) x amplitude x red channel x (normalized(vector3 + perterbed normal))

        // float windDirection = texture2D(noisetex, pos.xz + frameCounter / 10000.0).x * 2 * pi;

        // float sinDir = sin(windDirection);
        // float cosDir = cos(windDirection);
        // mat2 rotationMatrix = mat2(
        //     cosDir, -sinDir,
        //     sinDir,  cosDir
        // );

        // // The higher we are, the faster the wind
        // // float windSpeed = mix(0.05, 0.15, pos.y / 256.0) / 1.7;
        // vec2 offset = rotationMatrix * vec2((sin(pos.x) + 1) * 0.1, (cos(pos.z) + 1) * 0.1);
        // return vec3(offset.x, 0, offset.y);
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

    Material = mc_Entity.x == 201
        ? vec4(1, 0, 0, 1)
        : vec4(0, 0, 0, 1);

    #ifdef WAVY_OBJECTS_ENABLED
        position.xyz += (mc_Entity.x == 101 && TexCoords.t < mc_midTexCoord.t) ||
                    (mc_Entity.x == 102 && TexCoords.t > mc_midTexCoord.t) ||
                    mc_Entity.x == 103
            ? getWind(position.xyz + cameraPosition)
            : vec3(0);
    #endif

    gl_Position = gl_ModelViewProjectionMatrix * position;
}
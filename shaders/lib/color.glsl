vec3 srgb2linear(vec3 color)
{
    return pow(color, vec3(2.2));
}

vec3 linear2srgb(vec3 color)
{
    return pow(color, vec3(1.0 / 2.2));
}
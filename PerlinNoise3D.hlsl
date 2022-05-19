#include "RandomFunction.hlsl"

float Grad(uint hash, float3 v)
{
    switch (hash % 12)
    {
        case 0:
            return v.x + v.y;
        case 1:
            return v.y + v.z;
        case 2:
            return v.z + v.x;
        case 3:
            return v.x - v.y;
        case 4:
            return v.y - v.z;
        case 5:
            return v.z - v.x;
        case 6:
            return -v.x + v.y;
        case 7:
            return -v.y + v.z;
        case 8:
            return -v.z + v.x;
        case 9:
            return -v.x - v.y;
        case 10:
            return -v.y - v.z;
        case 11:
            return -v.z - v.x;
        default:
            return 0;
    }
}

float Fade(float t)
{
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float Lerp(float t, float a, float b)
{
    return a + t * (b - a);
}

float BasicPerlinNoise3D(float3 position)
{
    int3 tempVectorInt[] =
    {
        int3(0, 0, 0),
		int3(1, 0, 0),
		int3(0, 1, 0),
		int3(1, 1, 0),
		int3(0, 0, 1),
		int3(1, 0, 1),
		int3(0, 1, 1),
		int3(1, 1, 1)
    };

    int3 positionInt = floor(position);
    position -= positionInt;
    float temp[8];

    for (int index = 0; index < 8; ++index)
    {
        temp[index] = Grad(FloatToRandom(positionInt + tempVectorInt[index]), position - tempVectorInt[index]);
    }

    float u = Fade(position.x);
    float v = Fade(position.y);
    float w = Fade(position.z);

    return Lerp(w, Lerp(v, Lerp(u, temp[0], temp[1]), Lerp(u, temp[2], temp[3])), Lerp(v, Lerp(u, temp[4], temp[5]), Lerp(u, temp[6], temp[7])));
}

float PerlinNoise3D(float3 position, float scale = 1, int detail = 1)
{
    float noise = 0.0;
    float maxValue = 0.0;
    int shrink = 1;

    for (int count = 0; count < detail; ++count)
    {
        noise += BasicPerlinNoise3D(position / scale * shrink) / shrink;
        maxValue += 1.0 / shrink;

        shrink *= 2;
    }

    return noise / maxValue;
}

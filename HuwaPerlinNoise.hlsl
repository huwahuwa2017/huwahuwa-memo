//Ver8 2022/12/03 09:03

#ifndef HUWA_PERLIN_NOISE_INCLUDED
#define HUWA_PERLIN_NOISE_INCLUDED

#include "HuwaRandomFunction.hlsl"

static int4 _HPN_PositionShift[] =
{
    int4(0, 0, 0, 0),
    int4(1, 0, 0, 0),
    int4(0, 1, 0, 0),
    int4(1, 1, 0, 0),
    int4(0, 0, 1, 0),
    int4(1, 0, 1, 0),
    int4(0, 1, 1, 0),
    int4(1, 1, 1, 0),
    int4(0, 0, 0, 1),
    int4(1, 0, 0, 1),
    int4(0, 1, 0, 1),
    int4(1, 1, 0, 1),
    int4(0, 0, 1, 1),
    int4(1, 0, 1, 1),
    int4(0, 1, 1, 1),
    int4(1, 1, 1, 1)
};

float HPN_Smooth(float t)
{
    return t * t * (t * -2.0 + 3.0);
    //return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

void HPN_Lerp1D(float input[2], float s, out float result)
{
    result = lerp(input[0], input[1], s);
}

void HPN_Lerp2D(float input[4], float s, out float result[2])
{
    result[0] = lerp(input[0], input[1], s);
    result[1] = lerp(input[2], input[3], s);
}

void HPN_Lerp3D(float input[8], float s, out float result[4])
{
    result[0] = lerp(input[0], input[1], s);
    result[1] = lerp(input[2], input[3], s);
    result[2] = lerp(input[4], input[5], s);
    result[3] = lerp(input[6], input[7], s);
}

void HPN_Lerp4D(float input[16], float s, out float result[8])
{
    result[0] = lerp(input[0], input[1], s);
    result[1] = lerp(input[2], input[3], s);
    result[2] = lerp(input[4], input[5], s);
    result[3] = lerp(input[6], input[7], s);
    result[4] = lerp(input[8], input[9], s);
    result[5] = lerp(input[10], input[11], s);
    result[6] = lerp(input[12], input[13], s);
    result[7] = lerp(input[14], input[15], s);
}

float BasicPerlinNoise(float position)
{
    int positionInt = floor(position);
    position -= positionInt;
    
    float temp1D[2];
    
    for (int index = 0; index < 2; ++index)
    {
        int shift = _HPN_PositionShift[index].x;
        uint rx = IntToRandom(positionInt + shift);
        float nf = RandomToFloat(rx);
        temp1D[index] = dot(position - shift, nf);
    }
    
    float result = 0.0;
    
    HPN_Lerp1D(temp1D, HPN_Smooth(position.x), result);
    
    return result;
}

float BasicPerlinNoise(float2 position)
{
    int2 positionInt = floor(position);
    position -= positionInt;
    
    float temp2D[4];
    float temp1D[2];
    
    for (int index = 0; index < 4; ++index)
    {
        int2 shift = _HPN_PositionShift[index].yx;
        uint rx = IntToRandom(positionInt + shift);
        uint ry = UIntToRandom(rx);
        float2 nf = float2(RandomToFloat(rx), RandomToFloat(ry));
        temp2D[index] = dot(position - shift, nf);
    }
    
    float result = 0.0;
    
    HPN_Lerp2D(temp2D, HPN_Smooth(position.y), temp1D);
    HPN_Lerp1D(temp1D, HPN_Smooth(position.x), result);
    
    return result;
}

float BasicPerlinNoise(float3 position)
{
    int3 positionInt = floor(position);
    position -= positionInt;
    
    float temp3D[8];
    float temp2D[4];
    float temp1D[2];
    
    for (int index = 0; index < 8; ++index)
    {
        int3 shift = _HPN_PositionShift[index].zyx;
        uint rx = IntToRandom(positionInt + shift);
        uint ry = UIntToRandom(rx);
        uint rz = UIntToRandom(ry);
        float3 nf = float3(RandomToFloat(rx), RandomToFloat(ry), RandomToFloat(rz));
        temp3D[index] = dot(position - shift, nf);
    }
    
    float result = 0.0;
    
    HPN_Lerp3D(temp3D, HPN_Smooth(position.z), temp2D);
    HPN_Lerp2D(temp2D, HPN_Smooth(position.y), temp1D);
    HPN_Lerp1D(temp1D, HPN_Smooth(position.x), result);
    
    return result;
}

float BasicPerlinNoise(float4 position)
{
    int4 positionInt = floor(position);
    position -= positionInt;
    
    float temp4D[16];
    float temp3D[8];
    float temp2D[4];
    float temp1D[2];
    
    for (int index = 0; index < 16; ++index)
    {
        int4 shift = _HPN_PositionShift[index].wzyx;
        uint rx = IntToRandom(positionInt + shift);
        uint ry = UIntToRandom(rx);
        uint rz = UIntToRandom(ry);
        uint rw = UIntToRandom(rz);
        float4 nf = float4(RandomToFloat(rx), RandomToFloat(ry), RandomToFloat(rz), RandomToFloat(rw));
        temp4D[index] = dot(position - shift, nf);
    }
    
    float result = 0.0;
    
    HPN_Lerp4D(temp4D, HPN_Smooth(position.w), temp3D);
    HPN_Lerp3D(temp3D, HPN_Smooth(position.z), temp2D);
    HPN_Lerp2D(temp2D, HPN_Smooth(position.y), temp1D);
    HPN_Lerp1D(temp1D, HPN_Smooth(position.x), result);
    
    return result;
}

float PerlinNoise(float position, int detail = 1)
{
    float noise = 0.0;
    float amplitude = 1.0;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += BasicPerlinNoise(position) * amplitude;
        amplitude *= 0.5;
        position *= 2.0;
    }
    
    return noise;
}

float PerlinNoise(float2 position, int detail = 1)
{
    float noise = 0.0;
    float amplitude = 1.0;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += BasicPerlinNoise(position) * amplitude;
        amplitude *= 0.5;
        position *= 2.0;
    }
    
    return noise;
}

float PerlinNoise(float3 position, int detail = 1)
{
    float noise = 0.0;
    float amplitude = 1.0;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += BasicPerlinNoise(position) * amplitude;
        amplitude *= 0.5;
        position *= 2.0;
    }
    
    return noise;
}

float PerlinNoise(float4 position, int detail = 1)
{
    float noise = 0.0;
    float amplitude = 1.0;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += BasicPerlinNoise(position) * amplitude;
        amplitude *= 0.5;
        position *= 2.0;
    }
    
    return noise;
}

#endif // HUWA_PERLIN_NOISE_INCLUDED

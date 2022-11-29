//Ver5 2022/11/30 06:54

#ifndef HUWA_PERLIN_NOISE_INCLUDED
#define HUWA_PERLIN_NOISE_INCLUDED

#include "HuwaRandomFunction.hlsl"

static int4 _positionShift[] =
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

float Smooth(float t)
{
    return t * t * (t * -2.0 + 3.0);
    //return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float Grad(float pos, int posInt, int shift)
{
    uint r0 = IntToRandom(posInt + shift);
    float nf = RandomToFloat(r0);
    return dot(pos - shift, nf);
}

float Grad(float2 pos, int2 posInt, int2 shift)
{
    uint r0 = IntToRandom(posInt + shift);
    uint r1 = UIntToRandom(r0);
    float2 nf = float2(RandomToFloat(r0), RandomToFloat(r1));
    return dot(pos - shift, nf);
}

float Grad(float3 pos, int3 posInt, int3 shift)
{
    uint r0 = IntToRandom(posInt + shift);
    uint r1 = UIntToRandom(r0);
    uint r2 = UIntToRandom(r1);
    float3 nf = float3(RandomToFloat(r0), RandomToFloat(r1), RandomToFloat(r2));
    return dot(pos - shift, nf);
}

float Grad(float4 pos, int4 posInt, int4 shift)
{
    uint r0 = IntToRandom(posInt + shift);
    uint r1 = UIntToRandom(r0);
    uint r2 = UIntToRandom(r1);
    uint r3 = UIntToRandom(r2);
    float4 nf = float4(RandomToFloat(r0), RandomToFloat(r1), RandomToFloat(r2), RandomToFloat(r3));
    return dot(pos - shift, nf);
}

void DimensionLerpX(float input[2], float s, out float result)
{
    result = lerp(input[0], input[1], s);
}

void DimensionLerpY(float input[4], float s, out float result[2])
{
    result[0] = lerp(input[0], input[1], s);
    result[1] = lerp(input[2], input[3], s);
}

void DimensionLerpZ(float input[8], float s, out float result[4])
{
    result[0] = lerp(input[0], input[1], s);
    result[1] = lerp(input[2], input[3], s);
    result[2] = lerp(input[4], input[5], s);
    result[3] = lerp(input[6], input[7], s);
}

void DimensionLerpW(float input[16], float s, out float result[8])
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
    
    float tempX[2];
    
    for (int index = 0; index < 2; ++index)
    {
        tempX[index] = Grad(position, positionInt, _positionShift[index].x);
    }
    
    float result = 0.0;
    
    DimensionLerpX(tempX, Smooth(position.x), result);
    
    return result;
}

float BasicPerlinNoise(float2 position)
{
    int2 positionInt = floor(position);
    position -= positionInt;
    
    float tempY[4];
    float tempX[2];
    
    for (int index = 0; index < 4; ++index)
    {
        tempY[index] = Grad(position, positionInt, _positionShift[index].yx);
    }
    
    float result = 0.0;
    
    DimensionLerpY(tempY, Smooth(position.y), tempX);
    DimensionLerpX(tempX, Smooth(position.x), result);
    
    return result;
}

float BasicPerlinNoise(float3 position)
{
    int3 positionInt = floor(position);
    position -= positionInt;
    
    float tempZ[8];
    float tempY[4];
    float tempX[2];
    
    for (int index = 0; index < 8; ++index)
    {
        tempZ[index] = Grad(position, positionInt, _positionShift[index].zyx);
    }
    
    float result = 0.0;
    
    DimensionLerpZ(tempZ, Smooth(position.z), tempY);
    DimensionLerpY(tempY, Smooth(position.y), tempX);
    DimensionLerpX(tempX, Smooth(position.x), result);
    
    return result;
}

float BasicPerlinNoise(float4 position)
{
    int4 positionInt = floor(position);
    position -= positionInt;
    
    float tempW[16];
    float tempZ[8];
    float tempY[4];
    float tempX[2];
    
    for (int index = 0; index < 16; ++index)
    {
        tempW[index] = Grad(position, positionInt, _positionShift[index].wzyx);
    }
    
    float result = 0.0;
    
    DimensionLerpW(tempW, Smooth(position.w), tempZ);
    DimensionLerpZ(tempZ, Smooth(position.z), tempY);
    DimensionLerpY(tempY, Smooth(position.y), tempX);
    DimensionLerpX(tempX, Smooth(position.x), result);
    
    return result;
}

float PerlinNoise(float position, float scale = 1, int detail = 1)
{
    float noise = 0.0;
    float amplitude = 1.0;
    float pos = position * scale;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += BasicPerlinNoise(pos) * amplitude;
        amplitude *= 0.5;
        pos *= 2.0;
    }
    
    return noise;
}

float PerlinNoise(float2 position, float scale = 1, int detail = 1)
{
    float noise = 0.0;
    float amplitude = 1.0;
    float2 pos = position * scale;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += BasicPerlinNoise(pos) * amplitude;
        amplitude *= 0.5;
        pos *= 2.0;
    }
    
    return noise;
}

float PerlinNoise(float3 position, float scale = 1, int detail = 1)
{
    float noise = 0.0;
    float amplitude = 1.0;
    float3 pos = position * scale;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += BasicPerlinNoise(pos) * amplitude;
        amplitude *= 0.5;
        pos *= 2.0;
    }
    
    return noise;
}

float PerlinNoise(float4 position, float scale = 1, int detail = 1)
{
    float noise = 0.0;
    float amplitude = 1.0;
    float4 pos = position * scale;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += BasicPerlinNoise(pos) * amplitude;
        amplitude *= 0.5;
        pos *= 2.0;
    }
    
    return noise;
}

#endif // HUWA_PERLIN_NOISE_INCLUDED

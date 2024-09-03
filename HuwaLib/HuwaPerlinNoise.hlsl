//Ver12 2024/09/03 20:34

#if !defined(HUWA_PERLIN_NOISE_INCLUDED)
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

int HPN_IntLerp(int x, int y, int s)
{
    return x + (y - x) * s;
}

int2 HPN_IntLerp(int2 x, int2 y, int2 s)
{
    return x + (y - x) * s;
}

int3 HPN_IntLerp(int3 x, int3 y, int3 s)
{
    return x + (y - x) * s;
}

int4 HPN_IntLerp(int4 x, int4 y, int4 s)
{
    return x + (y - x) * s;
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

float HPN_Smooth(float t)
{
    return t * t * (t * -2.0 + 3.0);
    //return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float PerlinNoise(float input, uint repetition)
{
    float temp1D[2];
    
    int inputInt = floor(input);
    input -= inputInt;
    
    bool flag = repetition == 0;
    repetition += flag;
    
    for (int index = 0; index < 2; ++index)
    {
        int shift = _HPN_PositionShift[index].x;
        
        int target = inputInt + shift;
        target = HPN_IntLerp(target % repetition, target, flag);
        
        uint random = ValueToRandom(target);
        float randomFloat = RandomToFloat(random);
        temp1D[index] = dot(input - shift, randomFloat);
    }
    
    float result = 0.0;
    
    HPN_Lerp1D(temp1D, HPN_Smooth(input.x), result);
    
    return result;
}

float PerlinNoise(float2 input, uint2 repetition)
{
    float temp2D[4];
    float temp1D[2];
    
    int2 inputInt = floor(input);
    input -= inputInt;
    
    bool2 flag = repetition == 0;
    repetition += flag;
    
    for (int index = 0; index < 4; ++index)
    {
        int2 shift = _HPN_PositionShift[index].yx;
        
        int2 target = inputInt + shift;
        target = HPN_IntLerp(target % repetition, target, flag);
        
        uint random = ValueToRandom(target);
        float2 randomFloat = float2(RandomToFloat(random), UpdateRandomToFloat(random));
        temp2D[index] = dot(input - shift, randomFloat);
    }
    
    float result = 0.0;
    
    HPN_Lerp2D(temp2D, HPN_Smooth(input.y), temp1D);
    HPN_Lerp1D(temp1D, HPN_Smooth(input.x), result);
    
    return result * 0.70710678;
}

float PerlinNoise(float3 input, uint3 repetition)
{
    float temp3D[8];
    float temp2D[4];
    float temp1D[2];
    
    int3 inputInt = floor(input);
    input -= inputInt;
    
    bool3 flag = repetition == 0;
    repetition += flag;
    
    for (int index = 0; index < 8; ++index)
    {
        int3 shift = _HPN_PositionShift[index].zyx;
        
        int3 target = inputInt + shift;
        target = HPN_IntLerp(target % repetition, target, flag);
        
        uint random = ValueToRandom(target);
        float3 randomFloat = float3(RandomToFloat(random), UpdateRandomToFloat(random), UpdateRandomToFloat(random));
        temp3D[index] = dot(input - shift, randomFloat);
    }
    
    float result = 0.0;
    
    HPN_Lerp3D(temp3D, HPN_Smooth(input.z), temp2D);
    HPN_Lerp2D(temp2D, HPN_Smooth(input.y), temp1D);
    HPN_Lerp1D(temp1D, HPN_Smooth(input.x), result);
    
    return result * 0.57735026;
}

float PerlinNoise(float4 input, uint4 repetition)
{
    float temp4D[16];
    float temp3D[8];
    float temp2D[4];
    float temp1D[2];
    
    int4 inputInt = floor(input);
    input -= inputInt;
    
    bool4 flag = repetition == 0;
    repetition += flag;
    
    for (int index = 0; index < 16; ++index)
    {
        int4 shift = _HPN_PositionShift[index].wzyx;
        
        int4 target = inputInt + shift;
        target = HPN_IntLerp(target % repetition, target, flag);
        
        uint random = ValueToRandom(target);
        float4 randomFloat = float4(RandomToFloat(random), UpdateRandomToFloat(random), UpdateRandomToFloat(random), UpdateRandomToFloat(random));
        temp4D[index] = dot(input - shift, randomFloat);
    }
    
    float result = 0.0;
    
    HPN_Lerp4D(temp4D, HPN_Smooth(input.w), temp3D);
    HPN_Lerp3D(temp3D, HPN_Smooth(input.z), temp2D);
    HPN_Lerp2D(temp2D, HPN_Smooth(input.y), temp1D);
    HPN_Lerp1D(temp1D, HPN_Smooth(input.x), result);
    
    return result * 0.5;
}

float FBM_PerlinNoise(float input, uint repetition, int detail)
{
    float noise = 0.0;
    float height = 0.0;
    float amplitude = 1.0;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += PerlinNoise(input, repetition) * amplitude;
        height += amplitude;
        amplitude *= 0.5;
        input *= 2.0;
        repetition *= 2.0;
    }
    
    return noise / height;
}

float FBM_PerlinNoise(float2 input, uint2 repetition, int detail)
{
    float noise = 0.0;
    float height = 0.0;
    float amplitude = 1.0;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += PerlinNoise(input, repetition) * amplitude;
        height += amplitude;
        amplitude *= 0.5;
        input *= 2.0;
        repetition *= 2.0;
    }
    
    return noise / height;
}

float FBM_PerlinNoise(float3 input, uint3 repetition, int detail)
{
    float noise = 0.0;
    float height = 0.0;
    float amplitude = 1.0;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += PerlinNoise(input, repetition) * amplitude;
        height += amplitude;
        amplitude *= 0.5;
        input *= 2.0;
        repetition *= 2.0;
    }
    
    return noise / height;
}

float FBM_PerlinNoise(float4 input, uint4 repetition, int detail)
{
    float noise = 0.0;
    float height = 0.0;
    float amplitude = 1.0;
    
    for (int count = 0; count < detail; ++count)
    {
        noise += PerlinNoise(input, repetition) * amplitude;
        height += amplitude;
        amplitude *= 0.5;
        input *= 2.0;
        repetition *= 2.0;
    }
    
    return noise / height;
}

#endif // HUWA_PERLIN_NOISE_INCLUDED

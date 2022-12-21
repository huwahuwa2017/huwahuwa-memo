//Ver5 2022/12/13 23:44 Revert

#ifndef HUWA_CELLULAR_NOISE_INCLUDED
#define HUWA_CELLULAR_NOISE_INCLUDED

#include "HuwaRandomFunction.hlsl"

static int4 _HSN_PositionShift[] =
{
    int4(0, 0, 0, 0),
    int4(1, 0, 0, 0),
    int4(-1, 0, 0, 0),
    int4(0, 1, 0, 0),
    int4(1, 1, 0, 0),
    int4(-1, 1, 0, 0),
    int4(0, -1, 0, 0),
    int4(1, -1, 0, 0),
    int4(-1, -1, 0, 0),
    int4(0, 0, 1, 0),
    int4(1, 0, 1, 0),
    int4(-1, 0, 1, 0),
    int4(0, 1, 1, 0),
    int4(1, 1, 1, 0),
    int4(-1, 1, 1, 0),
    int4(0, -1, 1, 0),
    int4(1, -1, 1, 0),
    int4(-1, -1, 1, 0),
    int4(0, 0, -1, 0),
    int4(1, 0, -1, 0),
    int4(-1, 0, -1, 0),
    int4(0, 1, -1, 0),
    int4(1, 1, -1, 0),
    int4(-1, 1, -1, 0),
    int4(0, -1, -1, 0),
    int4(1, -1, -1, 0),
    int4(-1, -1, -1, 0),
    int4(0, 0, 0, 1),
    int4(1, 0, 0, 1),
    int4(-1, 0, 0, 1),
    int4(0, 1, 0, 1),
    int4(1, 1, 0, 1),
    int4(-1, 1, 0, 1),
    int4(0, -1, 0, 1),
    int4(1, -1, 0, 1),
    int4(-1, -1, 0, 1),
    int4(0, 0, 1, 1),
    int4(1, 0, 1, 1),
    int4(-1, 0, 1, 1),
    int4(0, 1, 1, 1),
    int4(1, 1, 1, 1),
    int4(-1, 1, 1, 1),
    int4(0, -1, 1, 1),
    int4(1, -1, 1, 1),
    int4(-1, -1, 1, 1),
    int4(0, 0, -1, 1),
    int4(1, 0, -1, 1),
    int4(-1, 0, -1, 1),
    int4(0, 1, -1, 1),
    int4(1, 1, -1, 1),
    int4(-1, 1, -1, 1),
    int4(0, -1, -1, 1),
    int4(1, -1, -1, 1),
    int4(-1, -1, -1, 1),
    int4(0, 0, 0, -1),
    int4(1, 0, 0, -1),
    int4(-1, 0, 0, -1),
    int4(0, 1, 0, -1),
    int4(1, 1, 0, -1),
    int4(-1, 1, 0, -1),
    int4(0, -1, 0, -1),
    int4(1, -1, 0, -1),
    int4(-1, -1, 0, -1),
    int4(0, 0, 1, -1),
    int4(1, 0, 1, -1),
    int4(-1, 0, 1, -1),
    int4(0, 1, 1, -1),
    int4(1, 1, 1, -1),
    int4(-1, 1, 1, -1),
    int4(0, -1, 1, -1),
    int4(1, -1, 1, -1),
    int4(-1, -1, 1, -1),
    int4(0, 0, -1, -1),
    int4(1, 0, -1, -1),
    int4(-1, 0, -1, -1),
    int4(0, 1, -1, -1),
    int4(1, 1, -1, -1),
    int4(-1, 1, -1, -1),
    int4(0, -1, -1, -1),
    int4(1, -1, -1, -1),
    int4(-1, -1, -1, -1)
};

int HSN_IntLerp(int x, int y, int s)
{
    return x + (y - x) * s;
}

void CellularNoise(in float position, in uint repetition, out float distance0, out float distance1, out float randomVector)
{
    distance0 = 99.9;
    distance1 = 99.9;
    randomVector = 0.0;
    
    int positionInt = floor(position);
    position -= positionInt;
    
    bool flagX = repetition.x == 0;
    
    for (int index = 0; index < 3; ++index)
    {
        int shift = _HSN_PositionShift[index];
        
        int target = positionInt + shift;
        target.x = HSN_IntLerp(target.x % (repetition.x + flagX), target.x, flagX);
        
        uint rx = IntToRandom(target);
        float newRandomVector = RandomToFloatAbs(rx);
        
        float rp = newRandomVector - position + shift;
        
        rp = abs(rp);
        float newDistance = rp.x;
        
        bool flag0 = newDistance < distance0;
        bool flag1 = newDistance < distance1;
        
        distance1 = lerp(distance1, newDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, newDistance, flag0);
        randomVector = lerp(randomVector, newRandomVector, flag0);
    }
}

// type = 0  Manhattan distance
// type = 1  Euclidean distance
// type = 2  Chebyshev distance
// type = 3  Euclidean distance square
void CellularNoise(in int type, in float2 position, in uint2 repetition, out float distance0, out float distance1, out float2 randomVector)
{
    distance0 = 99.9;
    distance1 = 99.9;
    randomVector = 0.0;
    
    int2 positionInt = floor(position);
    position -= positionInt;
    
    bool flagX = repetition.x == 0;
    bool flagY = repetition.y == 0;
    
    for (int index = 0; index < 9; ++index)
    {
        int2 shift = _HSN_PositionShift[index];
        
        int2 target = positionInt + shift;
        target.x = HSN_IntLerp(target.x % (repetition.x + flagX), target.x, flagX);
        target.y = HSN_IntLerp(target.y % (repetition.y + flagY), target.y, flagY);
        
        uint rx = IntToRandom(target);
        uint ry = UIntToRandom(rx);
        float2 newRandomVector = float2(RandomToFloatAbs(rx), RandomToFloatAbs(ry));
        
        float2 rp = newRandomVector - position + shift;
        
        float newDistance = 0.0;
        
        switch (type)
        {
            case 0:
                rp = abs(rp);
                newDistance = rp.x + rp.y;
                break;
            case 1:
            case 3:
                newDistance = dot(rp, rp);
                break;
            case 2:
                rp = abs(rp);
                newDistance = max(rp.x, rp.y);
                break;
        }
        
        bool flag0 = newDistance < distance0;
        bool flag1 = newDistance < distance1;
        
        distance1 = lerp(distance1, newDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, newDistance, flag0);
        randomVector = lerp(randomVector, newRandomVector, flag0);
    }
    
    if (type == 1)
    {
        distance0 = sqrt(distance0);
        distance1 = sqrt(distance1);
    }
}

// type = 0  Manhattan distance
// type = 1  Euclidean distance
// type = 2  Chebyshev distance
// type = 3  Euclidean distance square
void CellularNoise(in int type, in float3 position, in uint3 repetition, out float distance0, out float distance1, out float3 randomVector)
{
    distance0 = 99.9;
    distance1 = 99.9;
    randomVector = 0.0;
    
    int3 positionInt = floor(position);
    position -= positionInt;
    
    bool flagX = repetition.x == 0;
    bool flagY = repetition.y == 0;
    bool flagZ = repetition.z == 0;
    
    for (int index = 0; index < 27; ++index)
    {
        int3 shift = _HSN_PositionShift[index];
        
        int3 target = positionInt + shift;
        target.x = HSN_IntLerp(target.x % (repetition.x + flagX), target.x, flagX);
        target.y = HSN_IntLerp(target.y % (repetition.y + flagY), target.y, flagY);
        target.z = HSN_IntLerp(target.z % (repetition.z + flagZ), target.z, flagZ);
        
        uint rx = IntToRandom(target);
        uint ry = UIntToRandom(rx);
        uint rz = UIntToRandom(ry);
        float3 newRandomVector = float3(RandomToFloatAbs(rx), RandomToFloatAbs(ry), RandomToFloatAbs(rz));
        
        float3 rp = newRandomVector - position + shift;
        
        float newDistance = 0.0;
        
        switch (type)
        {
            case 0:
                rp = abs(rp);
                newDistance = rp.x + rp.y + rp.z;
                break;
            case 1:
            case 3:
                newDistance = dot(rp, rp);
                break;
            case 2:
                rp = abs(rp);
                newDistance = max(max(rp.x, rp.y), rp.z);
                break;
        }
        
        bool flag0 = newDistance < distance0;
        bool flag1 = newDistance < distance1;
        
        distance1 = lerp(distance1, newDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, newDistance, flag0);
        randomVector = lerp(randomVector, newRandomVector, flag0);
    }
    
    if (type == 1)
    {
        distance0 = sqrt(distance0);
        distance1 = sqrt(distance1);
    }
}

// type = 0  Manhattan distance
// type = 1  Euclidean distance
// type = 2  Chebyshev distance
// type = 3  Euclidean distance square
void CellularNoise(in int type, in float4 position, in uint4 repetition, out float distance0, out float distance1, out float4 randomVector)
{
    distance0 = 99.9;
    distance1 = 99.9;
    randomVector = 0.0;
    
    int4 positionInt = floor(position);
    position -= positionInt;
    
    bool flagX = repetition.x == 0;
    bool flagY = repetition.y == 0;
    bool flagZ = repetition.z == 0;
    bool flagW = repetition.w == 0;
    
    for (int index = 0; index < 81; ++index)
    {
        int4 shift = _HSN_PositionShift[index];
        
        int4 target = positionInt + shift;
        target.x = HSN_IntLerp(target.x % (repetition.x + flagX), target.x, flagX);
        target.y = HSN_IntLerp(target.y % (repetition.y + flagY), target.y, flagY);
        target.z = HSN_IntLerp(target.z % (repetition.z + flagZ), target.z, flagZ);
        target.w = HSN_IntLerp(target.w % (repetition.w + flagW), target.w, flagW);
        
        uint rx = IntToRandom(target);
        uint ry = UIntToRandom(rx);
        uint rz = UIntToRandom(ry);
        uint rw = UIntToRandom(rz);
        float4 newRandomVector = float4(RandomToFloatAbs(rx), RandomToFloatAbs(ry), RandomToFloatAbs(rz), RandomToFloatAbs(rw));
        
        float4 rp = newRandomVector - position + shift;
        
        float newDistance = 0.0;
        
        switch (type)
        {
            case 0:
                rp = abs(rp);
                newDistance = rp.x + rp.y + rp.z + rp.w;
                break;
            case 1:
            case 3:
                newDistance = dot(rp, rp);
                break;
            case 2:
                rp = abs(rp);
                newDistance = max(max(rp.x, rp.y), max(rp.z, rp.w));
                break;
        }
        
        bool flag0 = newDistance < distance0;
        bool flag1 = newDistance < distance1;
        
        distance1 = lerp(distance1, newDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, newDistance, flag0);
        randomVector = lerp(randomVector, newRandomVector, flag0);
    }
    
    if (type == 1)
    {
        distance0 = sqrt(distance0);
        distance1 = sqrt(distance1);
    }
}

#endif // HUWA_CELLULAR_NOISE_INCLUDED

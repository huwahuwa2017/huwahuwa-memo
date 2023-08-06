//Ver13 2023/08/06 09:00

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

int HCN_IntLerp(int x, int y, int s)
{
    return x + (y - x) * s;
}

int2 HCN_IntLerp(int2 x, int2 y, int2 s)
{
    return x + (y - x) * s;
}

int3 HCN_IntLerp(int3 x, int3 y, int3 s)
{
    return x + (y - x) * s;
}

int4 HCN_IntLerp(int4 x, int4 y, int4 s)
{
    return x + (y - x) * s;
}

void CellularNoise(in float input, in uint repetition, out float distance0, out float distance1, out float color, out float relativePosition)
{
    distance0 = 99.9;
    distance1 = 99.9;
    color = 0.0;
    relativePosition = 0.0;
    
    int inputInt = floor(input);
    input -= inputInt;
    
    bool flag = repetition == 0;
    repetition += flag;
    
    for (int index = 0; index < 3; ++index)
    {
        int shift = _HSN_PositionShift[index];
        
        int target = inputInt + shift;
        target = HCN_IntLerp(target % repetition, target, flag);
        
        uint random = ValueToRandom(target);
        float randomFloat = RandomToFloatAbs(random);
        float tempRP = randomFloat - input + shift;
        
        tempRP = abs(tempRP);
        float tempDistance = tempRP.x;
        
        bool flag0 = tempDistance < distance0;
        bool flag1 = tempDistance < distance1;
        
        distance1 = lerp(distance1, tempDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, tempDistance, flag0);
        color = lerp(color, randomFloat, flag0);
        relativePosition = lerp(relativePosition, tempRP, flag0);
    }
}

// type = 0  Manhattan distance
// type = 1  Euclidean distance
// type = 2  Chebyshev distance
// type = 3  Euclidean distance square
void CellularNoise(in int type, in float2 input, in uint2 repetition, out float distance0, out float distance1, out float2 color, out float2 relativePosition)
{
    distance0 = 99.9;
    distance1 = 99.9;
    color = 0.0;
    relativePosition = 0.0;
    
    int2 inputInt = floor(input);
    input -= inputInt;
    
    bool2 flag = repetition == 0;
    repetition += flag;
    
    for (int index = 0; index < 9; ++index)
    {
        int2 shift = _HSN_PositionShift[index];
        
        int2 target = inputInt + shift;
        target = HCN_IntLerp(target % repetition, target, flag);
        
        uint random = ValueToRandom(target);
        float2 randomFloat = float2(RandomToFloatAbs(random), UpdateRandomToFloatAbs(random));
        float2 tempRP = randomFloat - input + shift;
        
        float tempDistance = 0.0;
        
        switch (type)
        {
            case 0:
                tempRP = abs(tempRP);
                tempDistance = tempRP.x + tempRP.y;
                break;
            case 1:
            case 3:
                tempDistance = dot(tempRP, tempRP);
                break;
            case 2:
                tempRP = abs(tempRP);
                tempDistance = max(tempRP.x, tempRP.y);
                break;
        }
        
        bool flag0 = tempDistance < distance0;
        bool flag1 = tempDistance < distance1;
        
        distance1 = lerp(distance1, tempDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, tempDistance, flag0);
        color = lerp(color, randomFloat, flag0);
        relativePosition = lerp(relativePosition, tempRP, flag0);
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
void CellularNoise(in int type, in float3 input, in uint3 repetition, out float distance0, out float distance1, out float3 color, out float3 relativePosition)
{
    distance0 = 99.9;
    distance1 = 99.9;
    color = 0.0;
    relativePosition = 0.0;
    
    int3 inputInt = floor(input);
    input -= inputInt;
    
    bool3 flag = repetition == 0;
    repetition += flag;
    
    for (int index = 0; index < 27; ++index)
    {
        int3 shift = _HSN_PositionShift[index];
        
        int3 target = inputInt + shift;
        target = HCN_IntLerp(target % repetition, target, flag);
        
        uint random = ValueToRandom(target);
        float3 randomFloat = float3(RandomToFloatAbs(random), UpdateRandomToFloatAbs(random), UpdateRandomToFloatAbs(random));
        float3 tempRP = randomFloat - input + shift;
        
        float tempDistance = 0.0;
        
        switch (type)
        {
            case 0:
                tempRP = abs(tempRP);
                tempDistance = tempRP.x + tempRP.y + tempRP.z;
                break;
            case 1:
            case 3:
                tempDistance = dot(tempRP, tempRP);
                break;
            case 2:
                tempRP = abs(tempRP);
                tempDistance = max(max(tempRP.x, tempRP.y), tempRP.z);
                break;
        }
        
        bool flag0 = tempDistance < distance0;
        bool flag1 = tempDistance < distance1;
        
        distance1 = lerp(distance1, tempDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, tempDistance, flag0);
        color = lerp(color, randomFloat, flag0);
        relativePosition = lerp(relativePosition, tempRP, flag0);
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
void CellularNoise(in int type, in float4 input, in uint4 repetition, out float distance0, out float distance1, out float4 color, out float4 relativePosition)
{
    distance0 = 99.9;
    distance1 = 99.9;
    color = 0.0;
    relativePosition = 0.0;
    
    int4 inputInt = floor(input);
    input -= inputInt;
    
    bool4 flag = repetition == 0;
    repetition += flag;
    
    for (int index = 0; index < 81; ++index)
    {
        int4 shift = _HSN_PositionShift[index];
        
        int4 target = inputInt + shift;
        target = HCN_IntLerp(target % repetition, target, flag);
        
        uint random = ValueToRandom(target);
        float4 randomFloat = float4(RandomToFloatAbs(random), UpdateRandomToFloatAbs(random), UpdateRandomToFloatAbs(random), UpdateRandomToFloatAbs(random));
        float4 tempRP = randomFloat - input + shift;
        
        float tempDistance = 0.0;
        
        switch (type)
        {
            case 0:
                tempRP = abs(tempRP);
                tempDistance = tempRP.x + tempRP.y + tempRP.z + tempRP.w;
                break;
            case 1:
            case 3:
                tempDistance = dot(tempRP, tempRP);
                break;
            case 2:
                tempRP = abs(tempRP);
                tempDistance = max(max(tempRP.x, tempRP.y), max(tempRP.z, tempRP.w));
                break;
        }
        
        bool flag0 = tempDistance < distance0;
        bool flag1 = tempDistance < distance1;
        
        distance1 = lerp(distance1, tempDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, tempDistance, flag0);
        color = lerp(color, randomFloat, flag0);
        relativePosition = lerp(relativePosition, tempRP, flag0);
    }
    
    if (type == 1)
    {
        distance0 = sqrt(distance0);
        distance1 = sqrt(distance1);
    }
}

#endif // HUWA_CELLULAR_NOISE_INCLUDED

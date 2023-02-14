//Ver10 2023/02/15 03:48

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

void CellularNoise(in float input, in uint repetition, out float distance0, out float distance1, out float color, out float position)
{
    distance0 = 99.9;
    distance1 = 99.9;
    color = 0.0;
    position = 0.0;
    
    int shift = 0;
    
    int inputInt = floor(input);
    input -= inputInt;
    
    bool flag = repetition.x == 0;
    repetition += flag;
    
    for (int index = 0; index < 3; ++index)
    {
        int tempShift = _HSN_PositionShift[index];
        
        int target = inputInt + tempShift;
        target.x = HSN_IntLerp(target.x % repetition.x, target.x, flag.x);
        
        uint random = IntToRandom(target);
        float randomFloat = RandomToFloatAbs(random);
        float rp = randomFloat - input + tempShift;
        
        rp = abs(rp);
        float tempDistance = rp.x;
        
        bool flag0 = tempDistance < distance0;
        bool flag1 = tempDistance < distance1;
        
        distance1 = lerp(distance1, tempDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, tempDistance, flag0);
        color = lerp(color, randomFloat, flag0);
        shift = lerp(shift, tempShift, flag0);
    }
    
    position = inputInt + shift + color;
}

// type = 0  Manhattan distance
// type = 1  Euclidean distance
// type = 2  Chebyshev distance
// type = 3  Euclidean distance square
void CellularNoise(in int type, in float2 input, in uint2 repetition, out float distance0, out float distance1, out float2 color, out float2 position)
{
    distance0 = 99.9;
    distance1 = 99.9;
    color = 0.0;
    position = 0.0;
    
    int2 shift = 0;
    
    int2 inputInt = floor(input);
    input -= inputInt;
    
    bool2 flag = bool2(repetition.x == 0, repetition.y == 0);
    repetition += flag;
    
    for (int index = 0; index < 9; ++index)
    {
        int2 tempShift = _HSN_PositionShift[index];
        
        int2 target = inputInt + tempShift;
        target.x = HSN_IntLerp(target.x % repetition.x, target.x, flag.x);
        target.y = HSN_IntLerp(target.y % repetition.y, target.y, flag.y);
        
        uint random = IntToRandom(target);
        float2 randomFloat = float2(RandomToFloatAbs(random), UpdateRandomToFloatAbs(random));
        float2 rp = randomFloat - input + tempShift;
        
        float tempDistance = 0.0;
        
        switch (type)
        {
            case 0:
                rp = abs(rp);
                tempDistance = rp.x + rp.y;
                break;
            case 1:
            case 3:
                tempDistance = dot(rp, rp);
                break;
            case 2:
                rp = abs(rp);
                tempDistance = max(rp.x, rp.y);
                break;
        }
        
        bool flag0 = tempDistance < distance0;
        bool flag1 = tempDistance < distance1;
        
        distance1 = lerp(distance1, tempDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, tempDistance, flag0);
        color = lerp(color, randomFloat, flag0);
        shift = lerp(shift, tempShift, flag0);
    }
    
    if (type == 1)
    {
        distance0 = sqrt(distance0);
        distance1 = sqrt(distance1);
    }
    
    position = inputInt + shift + color;
}

// type = 0  Manhattan distance
// type = 1  Euclidean distance
// type = 2  Chebyshev distance
// type = 3  Euclidean distance square
void CellularNoise(in int type, in float3 input, in uint3 repetition, out float distance0, out float distance1, out float3 color, out float3 position)
{
    distance0 = 99.9;
    distance1 = 99.9;
    color = 0.0;
    position = 0.0;
    
    int3 shift = 0;
    
    int3 inputInt = floor(input);
    input -= inputInt;
    
    bool3 flag = bool3(repetition.x == 0, repetition.y == 0, repetition.z == 0);
    repetition += flag;
    
    for (int index = 0; index < 27; ++index)
    {
        int3 tempShift = _HSN_PositionShift[index];
        
        int3 target = inputInt + tempShift;
        target.x = HSN_IntLerp(target.x % repetition.x, target.x, flag.x);
        target.y = HSN_IntLerp(target.y % repetition.y, target.y, flag.y);
        target.z = HSN_IntLerp(target.z % repetition.z, target.z, flag.z);
        
        uint random = IntToRandom(target);
        float3 randomFloat = float3(RandomToFloatAbs(random), UpdateRandomToFloatAbs(random), UpdateRandomToFloatAbs(random));
        float3 rp = randomFloat - input + tempShift;
        
        float tempDistance = 0.0;
        
        switch (type)
        {
            case 0:
                rp = abs(rp);
                tempDistance = rp.x + rp.y + rp.z;
                break;
            case 1:
            case 3:
                tempDistance = dot(rp, rp);
                break;
            case 2:
                rp = abs(rp);
                tempDistance = max(max(rp.x, rp.y), rp.z);
                break;
        }
        
        bool flag0 = tempDistance < distance0;
        bool flag1 = tempDistance < distance1;
        
        distance1 = lerp(distance1, tempDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, tempDistance, flag0);
        color = lerp(color, randomFloat, flag0);
        shift = lerp(shift, tempShift, flag0);
    }
    
    if (type == 1)
    {
        distance0 = sqrt(distance0);
        distance1 = sqrt(distance1);
    }
    
    position = inputInt + shift + color;
}

// type = 0  Manhattan distance
// type = 1  Euclidean distance
// type = 2  Chebyshev distance
// type = 3  Euclidean distance square
void CellularNoise(in int type, in float4 input, in uint4 repetition, out float distance0, out float distance1, out float4 color, out float4 position)
{
    distance0 = 99.9;
    distance1 = 99.9;
    color = 0.0;
    position = 0.0;
    
    int4 shift = 0;
    
    int4 inputInt = floor(input);
    input -= inputInt;
    
    bool4 flag = bool4(repetition.x == 0, repetition.y == 0, repetition.z == 0, repetition.w == 0);
    repetition += flag;
    
    for (int index = 0; index < 81; ++index)
    {
        int4 tempShift = _HSN_PositionShift[index];
        
        int4 target = inputInt + tempShift;
        target.x = HSN_IntLerp(target.x % repetition.x, target.x, flag.x);
        target.y = HSN_IntLerp(target.y % repetition.y, target.y, flag.y);
        target.z = HSN_IntLerp(target.z % repetition.z, target.z, flag.z);
        target.w = HSN_IntLerp(target.w % repetition.w, target.w, flag.w);
        
        uint random = IntToRandom(target);
        float4 randomFloat = float4(RandomToFloatAbs(random), UpdateRandomToFloatAbs(random), UpdateRandomToFloatAbs(random), UpdateRandomToFloatAbs(random));
        float4 rp = randomFloat - input + tempShift;
        
        float tempDistance = 0.0;
        
        switch (type)
        {
            case 0:
                rp = abs(rp);
                tempDistance = rp.x + rp.y + rp.z + rp.w;
                break;
            case 1:
            case 3:
                tempDistance = dot(rp, rp);
                break;
            case 2:
                rp = abs(rp);
                tempDistance = max(max(rp.x, rp.y), max(rp.z, rp.w));
                break;
        }
        
        bool flag0 = tempDistance < distance0;
        bool flag1 = tempDistance < distance1;
        
        distance1 = lerp(distance1, tempDistance, flag1);
        distance1 = lerp(distance1, distance0, flag0);
        distance0 = lerp(distance0, tempDistance, flag0);
        color = lerp(color, randomFloat, flag0);
        shift = lerp(shift, tempShift, flag0);
    }
    
    if (type == 1)
    {
        distance0 = sqrt(distance0);
        distance1 = sqrt(distance1);
    }
    
    position = inputInt + shift + color;
}

#endif // HUWA_CELLULAR_NOISE_INCLUDED

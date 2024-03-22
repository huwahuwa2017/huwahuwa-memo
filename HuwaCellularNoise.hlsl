// Ver14 2024-03-22 16:40

#ifndef HUWA_CELLULAR_NOISE_INCLUDED
#define HUWA_CELLULAR_NOISE_INCLUDED

#define HCN_SETUP_0\
distance0 = 9.9;\
distance1 = 9.9;\
color = 0.0;\
relativePosition = 0.0;\
repetitionFlag = repetition == 0;\
repetition += repetitionFlag;\
input = repetitionFlag ? input : ((input % repetition) + repetition) % repetition;\
inputInt = floor(input);\
input -= inputInt;

#define HCN_SETUP_1\
bool flag0 = tempDistance < distance0;\
bool flag1 = tempDistance < distance1;\
distance1 = flag1 ? tempDistance : distance1;\
distance1 = flag0 ? distance0 : distance1;\
distance0 = flag0 ? tempDistance : distance0;\
color = flag0 ? randomFloat : color;\
relativePosition = flag0 ? tempRP : relativePosition;

#include "HuwaRandomFunction.hlsl"

static int4 _HCN_PositionShift[] =
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

void CellularNoise(in float input, in int repetition, out float distance0, out float distance1, out float color, out float relativePosition)
{
    bool repetitionFlag;
    int inputInt;
    
    HCN_SETUP_0
    
    for (int index = 0; index < 3; ++index)
    {
        int shift = _HCN_PositionShift[index];
        
        int target = inputInt + shift;
        target = repetitionFlag ? target : ((target % repetition) + repetition) % repetition;
        
        uint random = ValueToRandom(target);
        float randomFloat = RandomToFloatAbs(random);
        float tempRP = randomFloat - input + shift;
        
        float tempDistance = abs(tempRP);
        
        HCN_SETUP_1
    }
}

// type = 0  Manhattan distance
// type = 1  Euclidean distance
// type = 2  Chebyshev distance
// type = 3  Euclidean distance square
void CellularNoise(in int type, in float2 input, in int2 repetition, out float distance0, out float distance1, out float2 color, out float2 relativePosition)
{
    bool2 repetitionFlag;
    int2 inputInt;
    
    HCN_SETUP_0
    
    for (int index = 0; index < 9; ++index)
    {
        int2 shift = _HCN_PositionShift[index];
        
        int2 target = inputInt + shift;
        target = repetitionFlag ? target : ((target % repetition) + repetition) % repetition;
        
        uint random = ValueToRandom(target);
        float2 randomFloat = float2(RandomToFloatAbs(random), UpdateRandomToFloatAbs(random));
        float2 tempRP = randomFloat - input + shift;
        
        float2 tempAbs;
        float tempDistance;
        
        switch (type)
        {
            case 0:
                tempAbs = abs(tempRP);
                tempDistance = tempAbs.x + tempAbs.y;
                break;
            case 1:
            case 3:
                tempDistance = dot(tempRP, tempRP);
                break;
            case 2:
                tempAbs = abs(tempRP);
                tempDistance = max(tempAbs.x, tempAbs.y);
                break;
        }
        
        HCN_SETUP_1
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
void CellularNoise(in int type, in float3 input, in int3 repetition, out float distance0, out float distance1, out float3 color, out float3 relativePosition)
{
    bool3 repetitionFlag;
    int3 inputInt;
    
    HCN_SETUP_0
    
    for (int index = 0; index < 27; ++index)
    {
        int3 shift = _HCN_PositionShift[index];
        
        int3 target = inputInt + shift;
        target = repetitionFlag ? target : ((target % repetition) + repetition) % repetition;
        
        uint random = ValueToRandom(target);
        float3 randomFloat = float3(RandomToFloatAbs(random), UpdateRandomToFloatAbs(random), UpdateRandomToFloatAbs(random));
        float3 tempRP = randomFloat - input + shift;
        
        float3 tempAbs;
        float tempDistance;
        
        switch (type)
        {
            case 0:
                tempAbs = abs(tempRP);
                tempDistance = tempAbs.x + tempAbs.y + tempAbs.z;
                break;
            case 1:
            case 3:
                tempDistance = dot(tempRP, tempRP);
                break;
            case 2:
                tempAbs = abs(tempRP);
                tempDistance = max(max(tempAbs.x, tempAbs.y), tempAbs.z);
                break;
        }
        
        HCN_SETUP_1
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
void CellularNoise(in int type, in float4 input, in int4 repetition, out float distance0, out float distance1, out float4 color, out float4 relativePosition)
{
    bool4 repetitionFlag;
    int4 inputInt;
    
    HCN_SETUP_0
    
    for (int index = 0; index < 81; ++index)
    {
        int4 shift = _HCN_PositionShift[index];
        
        int4 target = inputInt + shift;
        target = repetitionFlag ? target : ((target % repetition) + repetition) % repetition;
        
        uint random = ValueToRandom(target);
        float4 randomFloat = float4(RandomToFloatAbs(random), UpdateRandomToFloatAbs(random), UpdateRandomToFloatAbs(random), UpdateRandomToFloatAbs(random));
        float4 tempRP = randomFloat - input + shift;
        
        float4 tempAbs;
        float tempDistance;
        
        switch (type)
        {
            case 0:
                tempAbs = abs(tempRP);
                tempDistance = tempAbs.x + tempAbs.y + tempAbs.z + tempAbs.w;
                break;
            case 1:
            case 3:
                tempDistance = dot(tempRP, tempRP);
                break;
            case 2:
                tempAbs = abs(tempRP);
                tempDistance = max(max(tempAbs.x, tempAbs.y), max(tempAbs.z, tempAbs.w));
                break;
        }
        
        HCN_SETUP_1
    }
    
    if (type == 1)
    {
        distance0 = sqrt(distance0);
        distance1 = sqrt(distance1);
    }
}

#endif // HUWA_CELLULAR_NOISE_INCLUDED

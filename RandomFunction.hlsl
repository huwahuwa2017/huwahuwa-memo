uint XorBitShift(uint seed)
{
    seed ^= (seed << 13);
    seed ^= (seed >> 17);
    seed ^= (seed << 5);
    return seed;
}



uint UIntToRandom(uint data)
{
    return XorBitShift(data * 1450663063) | 1;
}

uint UIntToRandom(uint2 data)
{
    data.x = UIntToRandom(data.x);
    data.y = UIntToRandom(data.y);
    
    return data.x * data.y;
}

uint UIntToRandom(uint3 data)
{
    data.x = UIntToRandom(data.x);
    data.y = UIntToRandom(data.y);
    data.z = UIntToRandom(data.z);
    
    return data.x * data.y * data.z;
}

uint UIntToRandom(uint4 data)
{
    data.x = UIntToRandom(data.x);
    data.y = UIntToRandom(data.y);
    data.z = UIntToRandom(data.z);
    data.w = UIntToRandom(data.w);
    
    return data.x * data.y * data.z * data.w;
}



uint IntToRandom(int data)
{
    return UIntToRandom(asuint(data));
}

uint IntToRandom(int2 data)
{
    return UIntToRandom(asuint(data));
}

uint IntToRandom(int3 data)
{
    return UIntToRandom(asuint(data));
}

uint IntToRandom(int4 data)
{
    return UIntToRandom(asuint(data));
}



uint FloatToRandom(float data)
{
    return UIntToRandom(asuint(data));
}

uint FloatToRandom(float2 data)
{
    return UIntToRandom(asuint(data));
}

uint FloatToRandom(float3 data)
{
    return UIntToRandom(asuint(data));
}

uint FloatToRandom(float4 data)
{
    return UIntToRandom(asuint(data));
}



int RandomToInt(uint seed)
{
    return asint(seed);
}

float RandomToFloatAbs(uint seed)
{
    uint data = seed & 0x7FFFFF | 0x3F800000;
    return asfloat(data) - 1.0;
}

float RandomToFloat(uint seed)
{
    uint data = asuint(RandomToFloatAbs(seed)) | (seed & 0x80000000);
    return asfloat(data);
}
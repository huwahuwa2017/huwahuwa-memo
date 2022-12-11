//Ver3 2022/12/11 23:18

#ifndef HUWA_RANDOM_FUNCTION_INCLUDED
#define HUWA_RANDOM_FUNCTION_INCLUDED

uint Xorshift(uint seed)
{
    seed ^= seed << 13;
    seed ^= seed >> 17;
    seed ^= seed << 5;
    return seed;
}



uint UIntToRandom(uint seed)
{
    return Xorshift(seed) * 1450663063;
}

uint UIntToRandom(uint2 seed)
{
    return Xorshift(Xorshift(seed.x) + seed.y) * 1450663063;
}

uint UIntToRandom(uint3 seed)
{
    return Xorshift(Xorshift(Xorshift(seed.x) + seed.y) + seed.z) * 1450663063;
}

uint UIntToRandom(uint4 seed)
{
    return Xorshift(Xorshift(Xorshift(Xorshift(seed.x) + seed.y) + seed.z) + seed.w) * 1450663063;
}



uint IntToRandom(int seed)
{
    return UIntToRandom(asuint(seed));
}

uint IntToRandom(int2 seed)
{
    return UIntToRandom(asuint(seed));
}

uint IntToRandom(int3 seed)
{
    return UIntToRandom(asuint(seed));
}

uint IntToRandom(int4 seed)
{
    return UIntToRandom(asuint(seed));
}



uint FloatToRandom(float seed)
{
    return UIntToRandom(asuint(seed));
}

uint FloatToRandom(float2 seed)
{
    return UIntToRandom(asuint(seed));
}

uint FloatToRandom(float3 seed)
{
    return UIntToRandom(asuint(seed));
}

uint FloatToRandom(float4 seed)
{
    return UIntToRandom(asuint(seed));
}



int RandomToInt(uint seed)
{
    return asint(seed);
}

float RandomToFloatAbs(uint seed)
{
    return asfloat(seed & 0x7FFFFF | 0x3F800000) - 1.0;
}

float RandomToFloat(uint seed)
{
    return asfloat(asuint(RandomToFloatAbs(seed)) | (seed & 0x80000000));
}

#endif // HUWA_RANDOM_FUNCTION_INCLUDED

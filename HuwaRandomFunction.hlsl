//Ver6 2023/08/06 09:00

#ifndef HUWA_RANDOM_FUNCTION_INCLUDED
#define HUWA_RANDOM_FUNCTION_INCLUDED

uint Xorshift(uint seed)
{
    seed ^= seed << 13;
    seed ^= seed >> 17;
    seed ^= seed << 5;
    return seed;
}

uint ValueToRandom(uint seed)
{
    return (Xorshift(seed) + 1) * 1450663063;
}

uint ValueToRandom(uint2 seed)
{
    return (Xorshift(Xorshift(seed.y) + seed.x) + 1) * 1450663063;
}

uint ValueToRandom(uint3 seed)
{
    return (Xorshift(Xorshift(Xorshift(seed.z) + seed.y) + seed.x) + 1) * 1450663063;
}

uint ValueToRandom(uint4 seed)
{
    return (Xorshift(Xorshift(Xorshift(Xorshift(seed.w) + seed.z) + seed.y) + seed.x) + 1) * 1450663063;
}

uint ValueToRandom(int seed)
{
    return ValueToRandom(asuint(seed));
}

uint ValueToRandom(int2 seed)
{
    return ValueToRandom(asuint(seed));
}

uint ValueToRandom(int3 seed)
{
    return ValueToRandom(asuint(seed));
}

uint ValueToRandom(int4 seed)
{
    return ValueToRandom(asuint(seed));
}

uint ValueToRandom(float seed)
{
    return ValueToRandom(asuint(seed));
}

uint ValueToRandom(float2 seed)
{
    return ValueToRandom(asuint(seed));
}

uint ValueToRandom(float3 seed)
{
    return ValueToRandom(asuint(seed));
}

uint ValueToRandom(float4 seed)
{
    return ValueToRandom(asuint(seed));
}



int RandomToInt(uint random)
{
    return asint(random);
}

float RandomToFloatAbs(uint random)
{
    return asfloat(random & 0x3FFFFFFF | 0x3F800000) - 1.0;
}

float RandomToFloat(uint random)
{
    return asfloat(asuint(RandomToFloatAbs(random)) | (random & 0x80000000));
}



uint UpdateRandom(in out uint random)
{
    random = ValueToRandom(random);
    return random;
}

int UpdateRandomToInt(in out uint random)
{
    random = ValueToRandom(random);
    return RandomToInt(random);
}

float UpdateRandomToFloatAbs(in out uint random)
{
    random = ValueToRandom(random);
    return RandomToFloatAbs(random);
}

float UpdateRandomToFloat(in out uint random)
{
    random = ValueToRandom(random);
    return RandomToFloat(random);
}

#endif // HUWA_RANDOM_FUNCTION_INCLUDED

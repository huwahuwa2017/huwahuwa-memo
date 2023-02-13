//Ver4 2023/02/14 07:07

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
    uint temp = Xorshift(seed);
    return (temp + (temp == 0)) * 1450663063;
}

uint UIntToRandom(uint2 seed)
{
    uint temp = Xorshift(Xorshift(seed.x) + seed.y);
    return (temp + (temp == 0)) * 1450663063;
}

uint UIntToRandom(uint3 seed)
{
    uint temp = Xorshift(Xorshift(Xorshift(seed.x) + seed.y) + seed.z);
    return (temp + (temp == 0)) * 1450663063;
}

uint UIntToRandom(uint4 seed)
{
    uint temp = Xorshift(Xorshift(Xorshift(Xorshift(seed.x) + seed.y) + seed.z) + seed.w);
    return (temp + (temp == 0)) * 1450663063;
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
    float temp = asfloat(random & 0xBFFFFFFF | 0x3F800000);
    return temp - sign(temp);
}



uint UpdateRandom(in out uint random)
{
    random = UIntToRandom(random);
    return random;
}

int UpdateRandomToInt(in out uint random)
{
    random = UIntToRandom(random);
    return RandomToInt(random);
}

float UpdateRandomToFloatAbs(in out uint random)
{
    random = UIntToRandom(random);
    return RandomToFloatAbs(random);
}

float UpdateRandomToFloat(in out uint random)
{
    random = UIntToRandom(random);
    return RandomToFloat(random);
}

#endif // HUWA_RANDOM_FUNCTION_INCLUDED

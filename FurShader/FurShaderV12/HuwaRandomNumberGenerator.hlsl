// Ver1 2026/05/17 21:37

#if !defined(HUWA_RANDOM_NUMBER_GENERATOR_INCLUDED)
#define HUWA_RANDOM_NUMBER_GENERATOR_INCLUDED

uint Xorshift(uint value)
{
	value ^= value << 13;
	value ^= value >> 17;
	value ^= value << 5;
	return value;
}

uint GenerateSeed(uint value)
{
	return (Xorshift(value) + 1) * 1450663063;
	// return mad(Xorshift(value), 1450663063, 1450663063);
}

uint GenerateSeed(uint2 value)
{
	return (Xorshift(Xorshift(value.y) + value.x) + 1) * 1450663063;
	// return mad(Xorshift(Xorshift(value.y) + value.x), 1450663063, 1450663063);
}

uint GenerateSeed(uint3 value)
{
	return (Xorshift(Xorshift(Xorshift(value.z) + value.y) + value.x) + 1) * 1450663063;
	// return mad(Xorshift(Xorshift(Xorshift(value.z) + value.y) + value.x), 1450663063, 1450663063);
}

uint GenerateSeed(uint4 value)
{
	return (Xorshift(Xorshift(Xorshift(Xorshift(value.w) + value.z) + value.y) + value.x) + 1) * 1450663063;
	// return mad(Xorshift(Xorshift(Xorshift(Xorshift(value.w) + value.z) + value.y) + value.x), 1450663063, 1450663063);
}

uint GenerateSeed(int value)
{
    return GenerateSeed(asuint(value));
}

uint GenerateSeed(int2 value)
{
    return GenerateSeed(asuint(value));
}

uint GenerateSeed(int3 value)
{
    return GenerateSeed(asuint(value));
}

uint GenerateSeed(int4 value)
{
    return GenerateSeed(asuint(value));
}

uint GenerateSeed(float value)
{
    return GenerateSeed(asuint(value));
}

uint GenerateSeed(float2 value)
{
    return GenerateSeed(asuint(value));
}

uint GenerateSeed(float3 value)
{
    return GenerateSeed(asuint(value));
}

uint GenerateSeed(float4 value)
{
	return GenerateSeed(asuint(value));
}



uint GenerateUint(in out uint seed)
{
    seed = Xorshift(seed);
	return seed;
}

int GenerateInt(in out uint seed)
{
    seed = Xorshift(seed);
    return asint(seed);
}

float GenerateAbsFloat(in out uint seed)
{
    seed = Xorshift(seed);
    return asfloat(seed & 0x3FFFFFFF | 0x3F800000) - 1.0;
}

float GenerateFloat(in out uint seed)
{
    seed = Xorshift(seed);
    return asfloat(asuint(asfloat(seed & 0x3FFFFFFF | 0x3F800000) - 1.0) | (seed & 0x80000000));
}

#endif // HUWA_RANDOM_NUMBER_GENERATOR_INCLUDED

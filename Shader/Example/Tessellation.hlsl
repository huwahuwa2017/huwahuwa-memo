#include "UnityCG.cginc"

struct I2V
{
    float4 lPos : POSITION;
};

struct V2G
{
    float4 cPos : TEXCOORD0;
};

struct G2F
{
    float4 cPos : SV_POSITION;
};

struct TessellationFactor
{
    float tessFactor[3] : SV_TessFactor;
    float insideTessFactor : SV_InsideTessFactor;
};

float _InsideTessFactor;
float _OutsideTessFactor;

V2G VertexShaderStage(I2V input)
{
    V2G output = (V2G) 0;
    output.cPos = UnityObjectToClipPos(input.lPos);
    return output;
}

/*
partitioning の詳細

・integer
  係数を切り上げ

・pow2
  2^n に丸めるらしいが、ちゃんと動いているようには見えない

・fractional_even
  偶数で補間

・fractional_odd
  奇数で補間
*/

// tri, quad, isoline
[domain("tri")]

// integer, fractional_even, fractional_odd, pow2
[partitioning("integer")]

// point, line, triangle_cw, triangle_ccw
[outputtopology("triangle_cw")]

// よくわからん  とりあえず以下の Domain Type と一致する頂点数を入れておけばいい
// tri = 3, quad = 4, isoline = 4
[outputcontrolpoints(3)]

[patchconstantfunc("PatchConstantFunction")]
V2G HullShaderStage(InputPatch<V2G, 3> input, uint id : SV_OutputControlPointID)
{
    return input[id];
}

TessellationFactor PatchConstantFunction(InputPatch<V2G, 3> input)
{
    TessellationFactor output = (TessellationFactor) 0;
    output.tessFactor[0] = _OutsideTessFactor;
    output.tessFactor[1] = _OutsideTessFactor;
    output.tessFactor[2] = _OutsideTessFactor;
    output.insideTessFactor = _InsideTessFactor;
    return output;
}

[domain("tri")]
V2G DomainShaderStage(TessellationFactor tf, const OutputPatch<V2G, 3> input, float3 bary : SV_DomainLocation)
{
    V2G output = (V2G) 0;
    output.cPos = bary.x * input[0].cPos + bary.y * input[1].cPos + bary.z * input[2].cPos;
    return output;
}



[maxvertexcount(4)]
void GeometryShaderStage(triangle V2G input[3], inout LineStream<G2F> stream)
{
    G2F output = (G2F) 0;
    
    output.cPos = input[0].cPos;
    stream.Append(output);
    output.cPos = input[1].cPos;
    stream.Append(output);
    output.cPos = input[2].cPos;
    stream.Append(output);
    output.cPos = input[0].cPos;
    stream.Append(output);
}

half4 FragmentShaderStage(G2F input) : SV_Target
{
    return 1.0;
}

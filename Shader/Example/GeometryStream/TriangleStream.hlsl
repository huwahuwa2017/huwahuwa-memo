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

V2G VertexShaderStage(I2V input)
{
    V2G output = (V2G) 0;
    output.cPos = UnityObjectToClipPos(input.lPos);
    return output;
}

[maxvertexcount(3)]
void GeometryShaderStage(triangle V2G input[3], inout TriangleStream<G2F> stream)
{
    G2F output = (G2F) 0;
    
    output.cPos = input[0].cPos;
    stream.Append(output);
    output.cPos = input[1].cPos;
    stream.Append(output);
    output.cPos = input[2].cPos;
    stream.Append(output);
}

half4 FragmentShaderStage(G2F input) : SV_Target
{
    return 1.0;
}

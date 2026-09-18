
#include "UnityCG.cginc"

struct I2V
{
    float4 lPos : POSITION;
};

struct V2F
{
    float4 cPos : SV_POSITION;
};

Texture2D<uint> _StencilTex;

uint _StencilRef;
uint _StencilA;
uint _StencilB;

V2F VertexShaderStage(I2V input)
{
    V2F output = (V2F) 0;
    output.cPos = UnityObjectToClipPos(input.lPos);
    return output;
}

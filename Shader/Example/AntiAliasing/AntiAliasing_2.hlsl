
#include "UnityCG.cginc"

struct I2V
{
    float4 lPos : POSITION;
    float2 uv : TEXCOORD0;
};

struct V2F
{
    float4 cPos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

sampler2D _MainTex;
float4 _MainTex_TexelSize;

uint _Difference;
uint _ViewOriginalColor;
float _OffsetLOD;

uint _MaxAnisotropy;

V2F VertexShaderStage(I2V input)
{
    V2F output = (V2F) 0;
    output.cPos = UnityObjectToClipPos(input.lPos);
    output.uv = input.uv;
    return output;
}

half4 FragmentShaderStage(V2F input) : SV_Target
{
    float2 size = _MainTex_TexelSize.zw;
    
    float2 uv = input.uv;
    uv = mul(float2x2(0.707, 0.707, -0.707, 0.707), uv);
    
    // uv の値が大きくなると誤差も大きくなる
    // かといって uv を frac 関数に直接入れると、
    // 繰り返し部分の ddx, ddy が正しく計算できなりエイリアスが発生する
    // なので少し工夫する必要がある
    uv.x += frac(_Time.x);
    
    
    
    float2 dx, dy;
    {
        float2 temp00 = uv * size;
        dx = ddx(temp00);
        dy = ddy(temp00);
    }
    
    // 長方形の長辺と短辺
    float longSideLength, shortSideLength;
    float2 longSideVector;
    {
        float temp30 = length(dx);
        float temp31 = length(dy);
        longSideLength = max(temp30, temp31);
        shortSideLength = min(temp30, temp31);
        
        longSideVector = (longSideLength == temp30) ? dx : dy;
    }
    
    float2 samplingDir = longSideVector / size;
    
    uint samplingCount = ceil(longSideLength / shortSideLength);
    samplingCount = clamp(samplingCount, 1, _MaxAnisotropy);
    
    float2 samplingMove = samplingDir / samplingCount;
    
    float2 samplingPos = uv - samplingDir * 0.5;
    samplingPos = samplingPos + samplingMove * 0.5;
    
    float lod = max(shortSideLength, longSideLength / samplingCount);
    lod = log2(lod) + _OffsetLOD;
    
    float4 resultColors = 0.0;
    
    for (uint count = 0; count < samplingCount; ++count)
    {
        resultColors += tex2Dlod(_MainTex, float4(samplingPos, 0.0, lod));
        samplingPos += samplingMove;
    }

    resultColors = resultColors / samplingCount;
    
    
    
    // 比較用
    half4 originalColor = tex2D(_MainTex, uv);
    
    half4 output = _ViewOriginalColor ? originalColor : resultColors;
    output = _Difference ? abs(resultColors - originalColor) : output;
    return output;
}

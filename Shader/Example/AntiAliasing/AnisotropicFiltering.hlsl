
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
    
    // uv ‚Ì’l‚ª‘å‚«‚­‚È‚é‚ÆŒë·‚à‘å‚«‚­‚È‚é
    // ‚©‚Æ‚¢‚Á‚Ä uv ‚ð frac ŠÖ”‚É’¼Ú“ü‚ê‚é‚ÆA
    // ŒJ‚è•Ô‚µ•”•ª‚Ì ddx, ddy ‚ª³‚µ‚­ŒvŽZ‚Å‚«‚È‚èƒGƒCƒŠƒAƒX‚ª”­¶‚·‚é
    // ‚È‚Ì‚Å­‚µH•v‚·‚é•K—v‚ª‚ ‚é
    uv.x += frac(_Time.x); 
    
    
    
    float2 dx, dy;
    {
        float2 temp00 = uv * size;
        dx = ddx(temp00);
        dy = ddy(temp00);
    }
    
    // „¡          „¢
    // „ dx.x  dy.x„ 
    // „ dx.y  dy.y„  = M
    // „¤          „£
    
    //             „¡            „¢
    //      T  -1  „ m00    m0110„ 
    // ( M M  )   =„ m0110  m11  „  ‚ðŒvŽZ‚·‚é
    //             „¤            „£
    float m00, m0110, m11;
    {
        float invDet = dx.x * dy.y - dy.x * dx.y;
        invDet = 1.0 / (invDet * invDet);
        
        m00 = (dx.y * dx.y + dy.y * dy.y) * invDet;
        m0110 = -(dx.x * dx.y + dy.x * dy.y) * invDet;
        m11 = (dx.x * dx.x + dy.x * dy.x) * invDet;
    }
    
    //      T  -1
    // ( M M  )   ‚ÌŒÅ—L’l‚ðŒvŽZ‚·‚é
    float eigen0, eigen1;
    {
        float temp10 = m00 + m11;
        float temp11 = m00 * m11 - m0110 * m0110;
        float temp12 = sqrt(temp10 * temp10 - 4.0 * temp11);

        eigen0 = (temp10 + temp12) * 0.5;
        eigen1 = (temp10 - temp12) * 0.5;
    }
    
    //      T  -1
    // ( M M  )   ‚ÌŒÅ—LƒxƒNƒgƒ‹‚ðŒvŽZ‚µ‚Ä³‹K‰»‚·‚é
    float2 eigenVector;
    {
        float temp20 = eigen1 - m00;
        float temp21 = eigen1 - m11;
        
        bool flag0 = abs(temp20) > abs(temp21);
        float2 temp22 = flag0 ? float2(m0110, temp20) : float2(temp21, m0110);
        
        float temp23 = sqrt(dot(temp22, temp22));
        eigenVector = (temp23 > 0.0) ? temp22 / temp23 : 0.0;
    }
    
    // ‘È‰~‚Ì’·”¼Œa‚Æ’Z”¼Œa
    float longRadius, shortRadius;
    {
        longRadius = 1.0 / sqrt(eigen1);
        shortRadius = 1.0 / sqrt(eigen0);
        
        float temp30 = length(dx);
        float temp31 = length(dy);
        longRadius = isnan(longRadius) ? max(temp30, temp31) : longRadius;
        shortRadius = isnan(shortRadius) ? min(temp30, temp31) : shortRadius;
    }
    
    float2 samplingDir = eigenVector * longRadius / size;
    
    uint samplingCount = ceil(longRadius / shortRadius);
    samplingCount = clamp(samplingCount, 1, _MaxAnisotropy);
    
    float2 samplingMove = samplingDir / samplingCount;
    
    float2 samplingPos = uv - samplingDir * 0.5;
    samplingPos = samplingPos + samplingMove * 0.5;
    
    float lod = max(shortRadius, longRadius / samplingCount);
    lod = log2(lod) + _OffsetLOD;
    
    float4 resultColors = 0.0;
    
    for (uint count = 0; count < samplingCount; ++count)
    {
        resultColors += tex2Dlod(_MainTex, float4(samplingPos, 0.0, lod));
        samplingPos += samplingMove;
    }

    resultColors = resultColors / samplingCount;
    
    
    
    // ”äŠr—p
    half4 originalColor = tex2D(_MainTex, uv);
    
    half4 output = _ViewOriginalColor ? originalColor : resultColors;
    output = _Difference ? abs(resultColors - originalColor) : output;
    return output;
}

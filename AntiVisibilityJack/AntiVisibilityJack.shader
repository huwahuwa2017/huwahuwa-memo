Shader "AntiVisibilityJack/AntiVisibilityJack"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Overlay+815199"
            "DisableBatching" = "True"
        }

        Pass
        {
            ZWrite Off
            ZTest Always

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            Texture2D _AVJ_BackgroundTexture;

            float4 VertexShaderStage(float2 uv : TEXCOORD0) : SV_POSITION
            {
                float4 cPos = float4(uv * 2.0 - 1.0, 0.5, 1.0);
                cPos.y *= _ProjectionParams.x;
                return cPos;
            }

            float4 FragmentShaderStage(float4 cPos : SV_POSITION) : SV_Target
            {
                float4 color = _AVJ_BackgroundTexture[uint2(cPos.xy)];
                color.a = 1.0;
                return color;
            }

            ENDCG
        }
    }
}
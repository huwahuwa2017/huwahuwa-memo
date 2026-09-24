Shader "HuwaPortal/PostProcess"
{
    SubShader
    {
        Tags
        {
            "Queue" = "Overlay+800000"
            "DisableBatching" = "True"
            "IgnoreProjector" = "True"
        }
        
        Pass
        {
            ZTest Always
            ZWrite Off

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage
            
            #include "UnityCG.cginc"

            struct I2V
            {
                float2 uv : TEXCOORD0;
            };

            struct V2F
            {
                float4 cPos : SV_POSITION;
            };
            
            Texture2D _MainTex;
            Texture2D<uint> _StencilTex;

            uint _StencilA;

            V2F VertexShaderStage(I2V input)
            {
                float4 cPos = float4(input.uv * 2.0 - 1.0, 0.5, 1.0);
                cPos.y *= _ProjectionParams.x;

                V2F output = (V2F)0;
                output.cPos = cPos;
                return output;
            }

            half4 FragmentShaderStage(V2F input) : SV_Target
            {
                uint2 index = uint2(input.cPos.xy);
                uint data = _StencilTex[index];

                bool flag = (_StencilA > 255) || (data == _StencilA);
                clip(-flag);

                return _MainTex[index];
            }

            ENDCG
        }
    }
}

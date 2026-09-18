Shader "HuwaPortal/GraphicsBlit"
{
    Properties
    {
        [NoScaleOffset]
        _MainTex("_MainTex", 2D) = "white" {}
    }

    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        struct I2V
        {
            float2 uv : TEXCOORD0;
        };

        struct V2F
        {
            float4 cPos : SV_POSITION;
        };
        
        Texture2D<uint> _MainTex;

        uint _StencilA;
        uint _StencilB;

        V2F VertexShaderStage(I2V input)
        {
            float4 cPos = float4(input.uv * 2.0 - 1.0, 0.5, 1.0);
            cPos.y *= _ProjectionParams.x;

            V2F output = (V2F)0;
            output.cPos = cPos;
            return output;
        }

        ENDCG
        
        // Pass : 0
        // StencilReset
        Pass
        {
            ZTest Always
            ZWrite Off

            CGPROGRAM
            
            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            uint FragmentShaderStage(V2F input) : SV_Target
            {
                return 0;
            }

            ENDCG
        }
        
        // Pass : 1
        // StencilCopy
        Pass
        {
            ZTest Always
            ZWrite Off

            CGPROGRAM
            
            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            uint FragmentShaderStage(V2F input) : SV_Target
            {
                return _MainTex[uint2(input.cPos.xy)];
            }

            ENDCG
        }
        
        // Pass : 2
        // StencilReplace
        Pass
        {
            ZTest Always
            ZWrite Off

            CGPROGRAM
            
            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            uint FragmentShaderStage(V2F input) : SV_Target
            {
                uint data = _MainTex[uint2(input.cPos.xy)];
                return (data == _StencilA) ? _StencilB : data;
            }

            ENDCG
        }
    }
}

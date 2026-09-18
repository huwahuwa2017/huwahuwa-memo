Shader "HuwaPortal/StencilReplace"
{
    SubShader
    {
        Pass
        {
            ZTest Always
            ZWrite Off

            CGPROGRAM

            #pragma vertex VertexShaderStage
            #pragma fragment FragmentShaderStage

            #include "Common.hlsl"

            uint FragmentShaderStage(V2F input) : SV_Target
            {
                uint data = _StencilTex[uint2(input.cPos.xy)].x;
                return (data == _StencilA) ? _StencilB : data;
            }

            ENDCG
        }
    }
}

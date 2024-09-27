// Ver3 2024/09/03 20:34

#if !defined(HUWA_INVERSE_MATRIX_INCLUDED)
#define HUWA_INVERSE_MATRIX_INCLUDED

float2x2 Inverse(float2x2 m)
{
    return float2x2(m._22, -m._12, -m._21, m._11) * rcp(determinant(m));
}

float3x3 Inverse(float3x3 m)
{
    float3x3 am;
    am._11_21_31 = mad(m._22_31_21, m._33_23_32, -m._32_21_31 * m._23_33_22);
    am._12_22_32 = mad(m._32_11_31, m._13_33_12, -m._12_31_11 * m._33_13_32);
    am._13_23_33 = mad(m._12_21_11, m._23_13_22, -m._22_11_21 * m._13_23_12);
    
    float invDet = rcp(dot(m[0], am._11_21_31));
    am._11_21_31 *= invDet;
    am._12_22_32 *= invDet;
    am._13_23_33 *= invDet;
    
    return am;
}

float4x4 Inverse(float4x4 m)
{
    float2 r12 = float2(mad(m._13, m._24, -m._23 * m._14), mad(m._11, m._22, -m._21 * m._12));
    float2 r13 = float2(mad(m._13, m._34, -m._33 * m._14), mad(m._11, m._32, -m._31 * m._12));
    float2 r14 = float2(mad(m._13, m._44, -m._43 * m._14), mad(m._11, m._42, -m._41 * m._12));
    float2 r23 = float2(mad(m._23, m._34, -m._33 * m._24), mad(m._21, m._32, -m._31 * m._22));
    float2 r24 = float2(mad(m._23, m._44, -m._43 * m._24), mad(m._21, m._42, -m._41 * m._22));
    float2 r34 = float2(mad(m._33, m._44, -m._43 * m._34), mad(m._31, m._42, -m._41 * m._32));
    
    float4x4 am;
    am._11_21_31_41 = mad(m._22_21_24_23, r34.xxyy, mad(m._32_31_34_33, -r24.xxyy, m._42_41_44_43 * r23.xxyy));
    am._12_22_32_42 = mad(m._12_11_14_13, r34.xxyy, mad(m._32_31_34_33, -r14.xxyy, m._42_41_44_43 * r13.xxyy));
    am._13_23_33_43 = mad(m._12_11_14_13, r24.xxyy, mad(m._22_21_24_23, -r14.xxyy, m._42_41_44_43 * r12.xxyy));
    am._14_24_34_44 = mad(m._12_11_14_13, r23.xxyy, mad(m._22_21_24_23, -r13.xxyy, m._32_31_34_33 * r12.xxyy));
    am._21_41 = -am._21_41;
    am._12_32 = -am._12_32;
    am._23_43 = -am._23_43;
    am._14_34 = -am._14_34;
    
    float invDet = rcp(dot(m[0], am._11_21_31_41));
    am._11_21_31_41 *= invDet;
    am._12_22_32_42 *= invDet;
    am._13_23_33_43 *= invDet;
    am._14_24_34_44 *= invDet;
    
    return am;
}

#endif // HUWA_INVERSE_MATRIX_INCLUDED

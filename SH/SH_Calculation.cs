// v2 2025-06-16 00:55

using FlowPaintTool;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public class SH_Calculation : MonoBehaviour
{
    [SerializeField]
    private Material _material0 = null;

    [SerializeField]
    private Material _material1 = null;

    [SerializeField]
    private Material _material2 = null;

    [SerializeField]
    private Camera _camera = null;

    [SerializeField]
    private RenderTexture _cubeMap = null;

    [SerializeField]
    private RenderTexture _temp0 = null;

    [SerializeField]
    private RenderTexture _temp1 = null;

    private Texture2D _memory = null;



    private static int _SH_Count = 9;
    private static Vector3[] _sh = new Vector3[_SH_Count];
    private static int[] _spid = new int[_SH_Count];
    private static string[] _keywords = new string[_SH_Count];

    // https://www.gamedev.net/forums/topic/671562-spherical-harmonics-cubemap/
    private static float CosineA0 = 1f;
    private static float CosineA1 = 2.0f / 3.0f;
    private static float CosineA2 = 0.25f;

    private static float _pi = Mathf.PI;

    private static float[] _SH_Multiply = new float[]
    {
        CosineA0 * 1f / (4f * _pi),

        CosineA1 * 3f / (4f * _pi),
        CosineA1 * 3f / (4f * _pi),
        CosineA1 * 3f / (4f * _pi),

        CosineA2 * 15f / ( 4f * _pi),
        CosineA2 * 15f / ( 4f * _pi),
        CosineA2 *  5f / (16f * _pi),
        CosineA2 * 15f / ( 4f * _pi),
        CosineA2 * 15f / (16f * _pi)
    };

    private void Start()
    {
        for (int i = 0; i < _SH_Count; ++i)
        {
            _spid[i] = Shader.PropertyToID("_SH_Coefficient_" + i.ToString());
            _keywords[i] = "SH_" + i.ToString();
        }

        RenderTextureDescriptor rtDescriptor = _cubeMap.descriptor;
        rtDescriptor.dimension = TextureDimension.Tex2D;
        rtDescriptor.width = _cubeMap.width / 2;
        rtDescriptor.height = _cubeMap.height / 2;
        rtDescriptor.graphicsFormat = GraphicsFormat.R32G32B32A32_SFloat;
        rtDescriptor.depthStencilFormat = GraphicsFormat.None;
        rtDescriptor.useMipMap = true;
        rtDescriptor.autoGenerateMips = true;

        _temp0 = new RenderTexture(rtDescriptor);

        rtDescriptor.width = 1;
        rtDescriptor.height = 1;
        rtDescriptor.useMipMap = false;
        rtDescriptor.autoGenerateMips = false;

        _temp1 = new RenderTexture(rtDescriptor);

        _memory = FPT_TextureOperation.GenerateTexture2D(_temp1);
    }

    private void EnableKeyword(Material m, int index)
    {
        foreach (string keyword in _keywords)
        {
            m.DisableKeyword(keyword);
        }

        m.EnableKeyword(_keywords[index]);
    }

    private void Calculation(int index)
    {
        EnableKeyword(_material0, index);
        Graphics.Blit(null, _temp0, _material0);   // ‹…–Ê’²˜aŒW”‚ðŒvŽZ
        Graphics.Blit(_temp0, _temp1, _material1); // mipmap‚ð—˜—p‚µ‚Ä‹…–Ê’²˜aŒW”‚Ì•½‹Ï‚ðŒvŽZ

        // ‹…–Ê’²˜aŒW”‚Ì•½‹Ï‚ðŒvŽZ‚µ‚½ RenderTexture ‚Ìƒf[ƒ^‚ðŽæ“¾‚·‚é
        // AsyncGPUReadback ‚Í Editor ã‚Å“®‚©‚È‚¢‚Ì‚ÅŽg‚í‚È‚¢
        FPT_TextureOperation.DataTransfer(_temp1, _memory);
        Color color = _memory.GetPixel(0, 0);

        // area ‚Ì‡Œv‚ðŠm”F‚µ‚½‚¢Žž—p‚Ì Debug.Log
        // Œ‹‰Ê‚Í‚Ù‚Ú 4pi ‚É‚È‚é‚Ì‚¾‚ªA’á‰ð‘œ“x‚¾‚Æ4pi‚æ‚è­‚µ‘å‚«‚­‚È‚é‚Ì‚Å‹C‚É‚È‚él‚ÍŠm”F‚µ‚Ä‚Ý‚Ä‚Ë
        Debug.Log(color.a.ToString());

        Vector3 temp0 = new Vector3(color.r, color.g, color.b) * _SH_Multiply[index];
        _material2.SetVector(_spid[index], temp0);
        _sh[index] = temp0;
    }



    int _frameCount = 0;

    private void FixedUpdate()
    {
        _camera.RenderToCubemap(_cubeMap);
        _material0.SetTexture("_CubeMap", _cubeMap);

        Calculation(_frameCount);

        ++_frameCount;
        _frameCount = (_frameCount >= _SH_Count) ? 0 : _frameCount;
    }

    [ContextMenu("SH Calculation")]
    public void TestD()
    {
        Start();

        _camera.RenderToCubemap(_cubeMap);
        _material0.SetTexture("_CubeMap", _cubeMap);

        for (int i = 0; i < _SH_Count; i++)
        {
            Calculation(i);
        }

        string log = string.Empty;

        for (int i = 0; i < _SH_Count; i++)
        {
            log += ($"float3({_sh[i].x}, {_sh[i].y}, {_sh[i].z}),\n");
        }

        Debug.Log(log);
    }



    [ContextMenu("Show light probe parameters")]
    public void TestE()
    {
        SphericalHarmonicsL2 probe;
        LightProbes.GetInterpolatedProbe(transform.position, null, out probe);

        string log = string.Empty;

        for (int i = 0; i < 9; i++)
        {
            log += ($"float3({probe[0, i]}, {probe[1, i]}, {probe[2, i]}),\n");
        }

        Debug.Log(log);
    }
}

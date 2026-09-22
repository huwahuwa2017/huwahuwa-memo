
using UdonSharp;
using UnityEngine;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class HuwaPortalData : UdonSharpBehaviour
{
    [SerializeField, Tooltip("描画するかしないかを決定する距離")]
    private float _visibleRange = 32f;

    [SerializeField, Tooltip("ポータルの内部を描画するための Renderer")]
    private Renderer _renderer = null;

    [SerializeField, Tooltip("プレイヤーがこのコライダーの範囲内に侵入するとテレポートする")]
    private Collider _teleportTrigger = null;

    [SerializeField, Tooltip("テレポート元 (出発地) の座標系")]
    private Transform _originTransform = null;

    [SerializeField, Tooltip("テレポート元 (出発地) のクリップ平面の位置と方向")]
    private Transform _originClipPlane = null;

    [SerializeField, Tooltip("テレポート先 (目的地) の座標系")]
    private Transform _destinationTransform = null;

    [SerializeField, Tooltip("テレポート先 (目的地) のクリップ平面の位置と方向")]
    private Transform _destinationClipPlane = null;

    [SerializeField, Tooltip("このポータルを覗いたときに見える可能性があるポータル")]
    private HuwaPortalData[] _visiblePortals = null;


    private float _visibleRangePow2 = 1f;
    private Material _stencilDepthWriteMaterial = null;
    private Material _originalMaterial = null;


    public float GetVisibleRange()
    {
        return _visibleRange;
    }

    public Renderer GetRenderer()
    {
        return _renderer;
    }

    public Collider GetTeleportTrigger()
    {
        return _teleportTrigger;
    }

    public Transform GetOriginTransform()
    {
        return _originTransform;
    }

    public Transform GetOriginClipPlane()
    {
        return _originClipPlane;
    }

    public Transform GetDestinationTransform()
    {
        return _destinationTransform;
    }

    public Transform GetDestinationClipPlane()
    {
        return _destinationClipPlane;
    }

    public HuwaPortalData[] GetVisiblePortals()
    {
        return _visiblePortals;
    }


    public void SetVisibleRangePow2(float input)
    {
        _visibleRangePow2 = input;
    }

    public float GetVisibleRangePow2()
    {
        return _visibleRangePow2;
    }

    public void SetOriginalMaterial(Material input)
    {
        _originalMaterial = input;
    }

    public Material GetOriginalMaterial()
    {
        return _originalMaterial;
    }

    public void SetStencilDepthWriteMaterial(Material input)
    {
        _stencilDepthWriteMaterial = input;
    }

    public Material GetStencilDepthWriteMaterial()
    {
        return _stencilDepthWriteMaterial;
    }
}

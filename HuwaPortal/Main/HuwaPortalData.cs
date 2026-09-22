
using System;
using UdonSharp;
using UnityEngine;

// オブジェクト指向信者が見たら発狂する実装
[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class HuwaPortalData : UdonSharpBehaviour
{
    [SerializeField, Tooltip("描画するかしないかを決定する距離")]
    public float _visibleRange = 32f;

    [SerializeField, Tooltip("ポータルの内部を描画するための Renderer")]
    public Renderer _renderer = null;

    [SerializeField, Tooltip("プレイヤーがこのコライダーの範囲内に侵入するとテレポートする")]
    public Collider _teleportTrigger = null;

    [SerializeField, Tooltip("テレポート元 (出発地) の座標系")]
    public Transform _originTransform = null;

    [SerializeField, Tooltip("テレポート元 (出発地) のクリップ平面の位置と方向")]
    public Transform _originClipPlane = null;

    [SerializeField, Tooltip("テレポート先 (目的地) の座標系")]
    public Transform _destinationTransform = null;

    [SerializeField, Tooltip("テレポート先 (目的地) のクリップ平面の位置と方向")]
    public Transform _destinationClipPlane = null;

    [SerializeField, Tooltip("このポータルを覗いたときに見える可能性があるポータル")]
    public HuwaPortalData[] _visiblePortals = null;


    [NonSerialized]
    public float _visibleRangePow2 = 1f;

    [NonSerialized]
    public Material _stencilDepthWriteMaterial = null;

    [NonSerialized]
    public Material _originalMaterial = null;
}

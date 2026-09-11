
// v3.13 2026-09-11 08:28

using UdonSharp;
using UnityEngine;
using VRC.SDK3.Rendering;
using VRC.SDKBase;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class HuwaPortalMain : UdonSharpBehaviour
{
    // _targetQueueSize がレンダリングの最大回数となりますが、
    // 最初は自分自身の視点のレンダリングで、2回目以降がポータルのレンダリングになります
    // つまり、レンダリングされるポータルの最大個数は、(_targetQueueSize - 1) 個となります
    // 例えば _targetQueueSize に 16 を設定した場合、レンダリングされるポータルの最大個数は 15 個となります
    [SerializeField, Tooltip("ポータルをレンダリングする回数に影響します\n1以上の値を入力してください")]
    private int _targetQueueSize = 16;

    [SerializeField, Tooltip("ポータルのステンシルを決定する段階で使用するレイヤー")]
    private int _huwaPortalLayer = 27;

    [SerializeField, Tooltip("すべての HuwaPortalData を設定してください")]
    private HuwaPortalData[] _allPortals = null;

    [SerializeField, Tooltip("VRC Scene Descriptor の ReferenceCamera と同じカメラを設定してください")]
    private Camera _sceneDescriptorReferenceCamera = null;

    [SerializeField, Tooltip("ポータルをレンダリングするカメラを設定してください")]
    private Camera _portalCamera = null;

    [SerializeField, Tooltip("マテリアルを複製するための MeshRenderer を設定してください")]
    private MeshRenderer _materialDuplicator = null;

    [SerializeField, HideInInspector]
    private Material _portalMaterial = null;

    [SerializeField, HideInInspector]
    private Material _stencilDepthWriteMaterial = null;

    [SerializeField, HideInInspector]
    private Material _stencilDepthClearMaterial = null;

    [SerializeField, HideInInspector]
    private Material _stencilReplaceMaterial = null;

    [SerializeField, HideInInspector]
    private Texture _dummyTexture = null;



    private int _leftCameraTexID = -1;
    private int _rightCameraTexID = -1;
    private int _photoCameraTexID = -1;
    private int _screenCameraPM_m11ID = -1;
    private int _photoCameraPM_m11ID = -1;
    private int _huwaPortalCameraModeID = -1;
    private int _stencilRefID = -1;
    private int _stencilAID = -1;
    private int _stencilBID = -1;

    private VRCPlayerApi _localPlayer = null;
    private bool _isUserInVR = false;

    private Transform _portalCameraTransform = null;
    private int _initialCullingMask = 0;
    private int _huwaPortalCullingMask = 0;

    private int _allPortalCount = -1;
    private Renderer[] _allPortalRenderers = null;
    private Material[] _allOriginalMaterials = null;



    private int _queueSize = -1;
    private int _enqueueIndex = 0;
    private int _dequeueIndex = 0;
    private HuwaPortalData[] _queueRenderPortal = null;
    private Matrix4x4[] _queueCameraMatrix = null;
    private int[] _queueParentIndex = null;

    private bool _startOnPreCull = true;

    private bool _screenCameraChangePending = false;
    private bool _photoCameraChangePending = false;
    private int _screenCameraWidth = -1;
    private int _photoCameraWidth = -1;
    private int _screenCameraHeight = -1;
    private int _photoCameraHeight = -1;

    private bool _leftEyeIsActive = false;
    private bool _rightEyeIsActive = false;
    private bool _photoCameraIsActive = false;
    private RenderTexture[] _leftCameraRTs = null;
    private RenderTexture[] _rightCameraRTs = null;
    private RenderTexture[] _photoCameraRTs = null;
    private Matrix4x4 _leftCameraPM = Matrix4x4.identity;
    private Matrix4x4 _rightCameraPM = Matrix4x4.identity;
    private Matrix4x4 _photoCameraPM = Matrix4x4.identity;



    private Vector3 _offset = new Vector3(0f, 0.5f, 0f);
    Matrix4x4 _zFlipMatrix = Matrix4x4.Scale(new Vector3(1f, 1f, -1f));
    Plane[] _planesCache = new Plane[6];



    public void SetTargetQueueSize(int input)
    {
        _targetQueueSize = Mathf.Max(1, input);
    }

    public int GetTargetQueueSize()
    {
        return _targetQueueSize;
    }



    private void Start()
    {
        if (_allPortals == null)
        {
            Debug.LogError("_allPortals が見つかりません");
            gameObject.SetActive(false);
            return;
        }

        if (_sceneDescriptorReferenceCamera == null)
        {
            Debug.LogError("_sceneDescriptorReferenceCamera が見つかりません");
            gameObject.SetActive(false);
            return;
        }

        if (_portalCamera == null)
        {
            Debug.LogError("_portalCamera が見つかりません");
            gameObject.SetActive(false);
            return;
        }

        if (_materialDuplicator == null)
        {
            Debug.LogError("_materialDuplicator が見つかりません");
            gameObject.SetActive(false);
            return;
        }

        _leftCameraTexID = VRCShader.PropertyToID("_LeftCameraTex");
        _rightCameraTexID = VRCShader.PropertyToID("_RightCameraTex");
        _photoCameraTexID = VRCShader.PropertyToID("_PhotoCameraTex");
        _screenCameraPM_m11ID = VRCShader.PropertyToID("_ScreenCameraPM_m11");
        _photoCameraPM_m11ID = VRCShader.PropertyToID("_PhotoCameraPM_m11");
        _huwaPortalCameraModeID = VRCShader.PropertyToID("_HuwaPortalCameraMode");
        _stencilRefID = VRCShader.PropertyToID("_StencilRef");
        _stencilAID = VRCShader.PropertyToID("_StencilA");
        _stencilBID = VRCShader.PropertyToID("_StencilB");

        _localPlayer = Networking.LocalPlayer;
        _isUserInVR = _localPlayer.IsUserInVR();

        _portalCameraTransform = _portalCamera.transform;
        _initialCullingMask = _portalCamera.cullingMask;
        _huwaPortalCullingMask = 1 << _huwaPortalLayer;

        _allPortalCount = _allPortals.Length;
        _allPortalRenderers = new Renderer[_allPortalCount];
        _allOriginalMaterials = new Material[_allPortalCount];

        for (int index = 0; index < _allPortalCount; index++)
        {
            HuwaPortalData pd = _allPortals[index];

            Renderer renderer = pd.GetRenderer();
            _allPortalRenderers[index] = renderer;
            _allOriginalMaterials[index] = renderer.sharedMaterial;

            // Udon は Instantiate(material) や new Material(material) が使えないので、
            // Renderer.material を利用してマテリアルを複製する
            _materialDuplicator.sharedMaterial = _stencilDepthWriteMaterial;
            pd.SetStencilDepthWriteMaterial(_materialDuplicator.material);
        }
    }



    public override void OnVRCCameraSettingsChanged(VRCCameraSettings cameraSettings)
    {
        if (cameraSettings == null)
            return;

        if (VRCCameraSettings.ScreenCamera == cameraSettings)
        {
            _screenCameraChangePending = true;
        }

        if (VRCCameraSettings.PhotoCamera == cameraSettings)
        {
            _photoCameraChangePending = true;
        }
    }

    private RenderTexture[] RegenerateRenderTexture(RenderTexture[] target, int width, int height)
    {
        if (target == null)
        {
            target = new RenderTexture[2];
        }
        else
        {
            target[0].Release();
            target[1].Release();
            Destroy(target[0]);
            Destroy(target[1]);
        }

        target[0] = new RenderTexture(width, height, 32, RenderTextureFormat.ARGBHalf);
        target[1] = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBHalf);

        return target;
    }

    private void UpdateCameraMatrix(Matrix4x4 cameraMatrix, Matrix4x4 projectionMatrix, Transform clipPlaneTransform)
    {
        _portalCameraTransform.SetPositionAndRotation(cameraMatrix.GetPosition(), cameraMatrix.rotation);
        _portalCamera.ResetWorldToCameraMatrix();
        Matrix4x4 viewMatrix = _portalCamera.worldToCameraMatrix;

        _portalCamera.projectionMatrix = projectionMatrix;

        _portalCamera.ResetCullingMatrix();

        if (clipPlaneTransform != null)
        {
            Vector3 vPos = viewMatrix.MultiplyPoint(clipPlaneTransform.position);
            Vector3 vNormal = Vector3.Normalize(viewMatrix.MultiplyVector(clipPlaneTransform.forward));
            float clipDistance = -Vector3.Dot(vPos, vNormal);

            //if (clipDistance < NearClipPlane)
            if (clipDistance < -0.01f)
            {
                Vector4 clipPlane = new Vector4(vNormal.x, vNormal.y, vNormal.z, clipDistance);
                projectionMatrix = _portalCamera.CalculateObliqueMatrix(clipPlane);
                _portalCamera.projectionMatrix = projectionMatrix;
            }
        }
    }

    private void RenderPortal(Vector3 eyePos, Quaternion eyeRot, Matrix4x4 projectionMatrix, RenderTexture[] rts)
    {
        _enqueueIndex = 0;
        _dequeueIndex = 0;
        _portalCamera.SetTargetBuffers(rts[0].colorBuffer, rts[0].depthBuffer);

        // どの _queueRenderPortal のレンダリング結果を保持するのか、という情報をステンシルに書き込む
        // ついでに一番奥のポータルも描画する
        {
            _queueRenderPortal[_enqueueIndex] = null;
            _queueCameraMatrix[_enqueueIndex] = Matrix4x4.TRS(eyePos, eyeRot, Vector3.one);
            ++_enqueueIndex;

            _portalCamera.renderingPath = RenderingPath.VertexLit;
            _portalCamera.cullingMask = _huwaPortalCullingMask;

            for (int index = 0; index < _allPortalCount; index++)
            {
                _allPortalRenderers[index].gameObject.layer = _huwaPortalLayer;
            }

            while (_enqueueIndex > _dequeueIndex)
            {
                // Dequeue
                HuwaPortalData renderPortal = _queueRenderPortal[_dequeueIndex];
                Matrix4x4 cameraMatrix = _queueCameraMatrix[_dequeueIndex];

                Vector3 cameraPos = cameraMatrix.GetPosition();

                HuwaPortalData[] visiblePortals;
                Transform clipPlaneTransform;

                if (renderPortal == null)
                {
                    _portalCamera.clearFlags = CameraClearFlags.Depth;
                    visiblePortals = _allPortals;
                    clipPlaneTransform = null;
                }
                else
                {
                    _portalCamera.clearFlags = CameraClearFlags.Nothing;
                    visiblePortals = renderPortal.GetVisiblePortals();
                    clipPlaneTransform = renderPortal.GetDestinationClipPlane();

                    _stencilDepthClearMaterial.SetFloat(_stencilRefID, _dequeueIndex);
                    VRCGraphics.Blit(_dummyTexture, rts[0], _stencilDepthClearMaterial);
                }

                for (int index = 0; index < _allPortalCount; index++)
                {
                    // null を代入すると、一番奥のポータルがわかりやすくなる
                    // _portalMaterial を代入すると、前回の描画結果を表示する
                    //_allPortalRenderers[index].sharedMaterial = null;
                    _allPortalRenderers[index].sharedMaterial = _allOriginalMaterials[index];
                }

                foreach (HuwaPortalData pd in visiblePortals)
                {
                    if (_enqueueIndex >= _queueSize)
                        break;

                    if (!pd.gameObject.activeInHierarchy)
                        continue;

                    Vector3 lp = pd.GetOriginClipPlane().InverseTransformPoint(cameraPos);
                    float d = Vector3.Magnitude(lp);

                    if ((lp.z < 0f) || (d > pd.GetVisibleRange()))
                        continue;

                    Matrix4x4 newCameraMatrix = pd.GetDestinationTransform().localToWorldMatrix * pd.GetOriginTransform().worldToLocalMatrix * cameraMatrix;
                    Matrix4x4 cullMatrix = projectionMatrix * _zFlipMatrix * Matrix4x4.Inverse(cameraMatrix);

                    GeometryUtility.CalculateFrustumPlanes(cullMatrix, _planesCache);
                    bool tpAABB = GeometryUtility.TestPlanesAABB(_planesCache, pd.GetRenderer().bounds);

                    if (!tpAABB)
                        continue;

                    // Enqueue
                    _queueRenderPortal[_enqueueIndex] = pd;
                    _queueCameraMatrix[_enqueueIndex] = newCameraMatrix;
                    _queueParentIndex[_enqueueIndex] = _dequeueIndex;

                    Material material = pd.GetStencilDepthWriteMaterial();
                    material.SetFloat(_stencilRefID, _enqueueIndex);
                    pd.GetRenderer().sharedMaterial = material;

                    ++_enqueueIndex;
                }

                UpdateCameraMatrix(cameraMatrix, projectionMatrix, clipPlaneTransform);
                _portalCamera.Render();

                ++_dequeueIndex;
            }
        }

        // ポータルをレンダリングする
        // ステンシルに合わせてレンダリング結果を保持する
        {
            // これがないと次に描画されるポータルが変になる
            VRCGraphics.Blit(rts[0], rts[1]);

            _portalCamera.renderingPath = RenderingPath.UsePlayerSettings;
            _portalCamera.cullingMask = _initialCullingMask;

            for (int index = 0; index < _allPortalCount; index++)
            {
                _allPortalRenderers[index].gameObject.layer = 0;
            }

            while (_dequeueIndex > 1)
            {
                --_dequeueIndex;
                HuwaPortalData renderPortal = _queueRenderPortal[_dequeueIndex];
                Matrix4x4 cameraMatrix = _queueCameraMatrix[_dequeueIndex];
                int parentIndex = _queueParentIndex[_dequeueIndex];

                _stencilDepthClearMaterial.SetFloat(_stencilRefID, _dequeueIndex);
                VRCGraphics.Blit(_dummyTexture, rts[0], _stencilDepthClearMaterial);

                for (int index = 0; index < _allPortalCount; index++)
                {
                    _allPortalRenderers[index].sharedMaterial = _allOriginalMaterials[index];
                }

                foreach (HuwaPortalData pd in renderPortal.GetVisiblePortals())
                {
                    pd.GetRenderer().sharedMaterial = _portalMaterial;
                }

                UpdateCameraMatrix(cameraMatrix, projectionMatrix, renderPortal.GetDestinationClipPlane());
                _portalCamera.Render();

                _stencilReplaceMaterial.SetFloat(_stencilAID, _dequeueIndex);
                _stencilReplaceMaterial.SetFloat(_stencilBID, parentIndex);
                VRCGraphics.Blit(_dummyTexture, rts[0], _stencilReplaceMaterial);
                VRCGraphics.Blit(rts[0], rts[1]);
            }
        }

        for (int index = 0; index < _allPortalCount; index++)
        {
            _allPortalRenderers[index].sharedMaterial = _portalMaterial;
        }
    }

    private void OnPreCull()
    {
        //Debug.Log("Start OnPreCull");

        VRCCameraSettings scs = VRCCameraSettings.ScreenCamera;
        VRCCameraSettings pcs = VRCCameraSettings.PhotoCamera;

        // OnVRCCameraSettingsChanged(VRCCameraSettings) はプレイヤーがワールドに入ったときは実行されないので、
        // OnPreCull() が初めて実行されたときに、 OnVRCCameraSettingsChanged(VRCCameraSettings) を実行する
        // Start() で実行すれば？ と思うかもしれないが、異常な値が設定されてしまう
        // おそらく Start() は VRCCameraSettings が準備する前に実行されるからと予想している
        if (_startOnPreCull)
        {
            _startOnPreCull = false;
            OnVRCCameraSettingsChanged(scs);
            OnVRCCameraSettingsChanged(pcs);
        }

        if (_queueSize != _targetQueueSize)
        {
            _queueSize = _targetQueueSize;

            Debug.Log("_targetQueueSize の変更を検出");

            _queueRenderPortal = new HuwaPortalData[_queueSize];
            _queueCameraMatrix = new Matrix4x4[_queueSize];
            _queueParentIndex = new int[_queueSize];
        }

        if (_screenCameraChangePending)
        {
            _screenCameraChangePending = false;

            Debug.Log("ScreenCamera の変更を検出");

            _leftEyeIsActive = scs.Active;
            _rightEyeIsActive = scs.Active && _isUserInVR;

            // ProjectionMatrix の更新
            {
                if (_isUserInVR)
                {
                    _leftCameraPM = _sceneDescriptorReferenceCamera.GetStereoProjectionMatrix(Camera.StereoscopicEye.Left);
                    _rightCameraPM = _sceneDescriptorReferenceCamera.GetStereoProjectionMatrix(Camera.StereoscopicEye.Right);
                }
                else
                {
                    _leftCameraPM = Matrix4x4.Perspective(scs.FieldOfView, scs.Aspect, scs.NearClipPlane, scs.FarClipPlane);
                }
            }

            // ピクセル数の変更を検知すると RenderTexture を再生成する
            {
                // ここに 1 未満の値が入る状況は見たことは無いが、
                // 念のために 1 未満の値が入らないようにしておく
                int width = Mathf.Max(1, scs.PixelWidth);
                int height = Mathf.Max(1, scs.PixelHeight);

                if (width != _screenCameraWidth || height != _screenCameraHeight)
                {
                    _screenCameraWidth = width;
                    _screenCameraHeight = height;

                    _leftCameraRTs = RegenerateRenderTexture(_leftCameraRTs, width, height);
                    _portalMaterial.SetTexture(_leftCameraTexID, _leftCameraRTs[1]);

                    if (_isUserInVR)
                    {
                        _rightCameraRTs = RegenerateRenderTexture(_rightCameraRTs, width, height);
                        _portalMaterial.SetTexture(_rightCameraTexID, _rightCameraRTs[1]);
                    }
                }
            }
        }

        if (_photoCameraChangePending)
        {
            _photoCameraChangePending = false;

            Debug.Log("PhotoCamera の変更を検出");

            _photoCameraIsActive = pcs.Active;

            // ProjectionMatrix の更新
            {
                // https://feedback.vrchat.com/bug-reports/p/vrccamerasettings-fov-wrong-for-photo-camera
                // PhotoCamera の FOV がずれているので 0.85 倍する
                // 掛ける値が小さすぎると画面端の描画に失敗するので少し余裕を持たせる
                // ちなみにスクリーンショット（F12キー）もFOVがずれている
                float photoCameraFOV = pcs.FieldOfView * 0.85f;

                _photoCameraPM = Matrix4x4.Perspective(photoCameraFOV, pcs.Aspect, pcs.NearClipPlane, pcs.FarClipPlane);
            }

            // ピクセル数の変更を検知すると RenderTexture を再生成する
            {
                // ここに 1 未満の値が入る状況は見たことは無いが、
                // 念のために 1 未満の値が入らないようにしておく
                int width = Mathf.Max(1, pcs.PixelWidth);
                int height = Mathf.Max(1, pcs.PixelHeight);

                if (width != _photoCameraWidth || height != _photoCameraHeight)
                {
                    _photoCameraWidth = width;
                    _photoCameraHeight = height;

                    _photoCameraRTs = RegenerateRenderTexture(_photoCameraRTs, width, height);
                    _portalMaterial.SetTexture(_photoCameraTexID, _photoCameraRTs[1]);
                }
            }
        }



        _portalMaterial.SetFloat(_screenCameraPM_m11ID, _leftCameraPM.m11);
        _portalMaterial.SetFloat(_photoCameraPM_m11ID, _photoCameraPM.m11);

        if (_leftEyeIsActive)
        {
            _portalMaterial.SetFloat(_huwaPortalCameraModeID, 0f);
            Vector3 eyePos = VRCCameraSettings.GetEyePosition(Camera.StereoscopicEye.Left);
            Quaternion eyeRot = VRCCameraSettings.GetEyeRotation(Camera.StereoscopicEye.Left);
            RenderPortal(eyePos, eyeRot, _leftCameraPM, _leftCameraRTs);
        }

        if (_rightEyeIsActive)
        {
            _portalMaterial.SetFloat(_huwaPortalCameraModeID, 1f);
            Vector3 eyePos = VRCCameraSettings.GetEyePosition(Camera.StereoscopicEye.Right);
            Quaternion eyeRot = VRCCameraSettings.GetEyeRotation(Camera.StereoscopicEye.Right);
            RenderPortal(eyePos, eyeRot, _rightCameraPM, _rightCameraRTs);
        }

        if (_photoCameraIsActive)
        {
            _portalMaterial.SetFloat(_huwaPortalCameraModeID, 2f);
            Vector3 eyePos = pcs.Position;
            Quaternion eyeRot = pcs.Rotation;
            RenderPortal(eyePos, eyeRot, _photoCameraPM, _photoCameraRTs);
        }

        _portalMaterial.SetFloat(_huwaPortalCameraModeID, -1f);

        //Debug.Log("End OnPreCull");
    }





    private void FixedUpdate()
    {
        Vector3 offsetPos = _localPlayer.GetPosition() + _offset;

        foreach (HuwaPortalData pd in _allPortals)
        {
            Collider collider = pd.GetTeleportTrigger();

            // Collider が有効になっているのかを確認したいが、 collider.enabled だけでは不十分である。
            // Collider の親オブジェクトが無効になっているかも確認する
            if (collider == null || !collider.enabled || !collider.gameObject.activeInHierarchy)
                continue;

            Vector3 closestPos = collider.ClosestPoint(offsetPos);

            if (Vector3.SqrMagnitude(closestPos - offsetPos) >= 0.000001f)
                continue;

            Transform originTransform = pd.GetOriginTransform();
            Transform destinationTransform = pd.GetDestinationTransform();

            Quaternion tpRot = destinationTransform.rotation;
            Quaternion mpInvRot = Quaternion.Inverse(originTransform.rotation);
            Quaternion rRot = tpRot * mpInvRot;

            Vector3 rp = _localPlayer.GetPosition() - originTransform.position;
            Vector3 wp = destinationTransform.position + (rRot * rp);

            Quaternion playerRot;

            if (_isUserInVR)
            {
                playerRot = _localPlayer.GetRotation();
            }
            else
            {
                // DesktopMode で落下アニメーション中に localPlayer.GetRotation() でプレイヤーの回転を取得すると
                // おかしくなるので、代わりに VRCCameraSettings.GetEyeRotation を使う
                playerRot = VRCCameraSettings.GetEyeRotation(Camera.StereoscopicEye.Left);
            }

            _localPlayer.TeleportTo(wp, rRot * playerRot);
            _localPlayer.SetVelocity(rRot * _localPlayer.GetVelocity());

            break;
        }
    }
}

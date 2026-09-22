
using UdonSharp;
using UnityEngine;
using VRC.SDK3.Rendering;
using VRC.SDKBase;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class HuwaPortalTeleport : UdonSharpBehaviour
{
    [SerializeField, Tooltip("すべての HuwaPortalData を設定してください")]
    private HuwaPortalData[] _allPortals = null;

    private VRCPlayerApi _localPlayer = null;
    private bool _isUserInVR = false;

    private int _allPortalCount = -1;
    private Collider[] _allTeleportTriggers = null;

    private Vector3 _offset = new Vector3(0f, 0.5f, 0f);

    private void Start()
    {
        _localPlayer = Networking.LocalPlayer;
        _isUserInVR = _localPlayer.IsUserInVR();

        _allPortalCount = _allPortals.Length;
        _allTeleportTriggers = new Collider[_allPortalCount];

        for (int index = 0; index < _allPortalCount; index++)
        {
            _allTeleportTriggers[index] = _allPortals[index].GetTeleportTrigger();
        }
    }

    private void FixedUpdate()
    {
        Vector3 playerPos = _localPlayer.GetPosition();
        Vector3 offsetPos = playerPos + _offset;

        for (int index = 0; index < _allPortalCount; index++)
        {
            Collider collider = _allTeleportTriggers[index];

            if (collider == null)
                continue;

            if (!(collider.enabled && collider.gameObject.activeInHierarchy))
                continue;

            Vector3 closestPos = collider.ClosestPoint(offsetPos);

            if (Vector3.Distance(closestPos, offsetPos) > 0.001f)
                continue;

            HuwaPortalData pd = _allPortals[index];
            Transform originTransform = pd.GetOriginTransform();
            Transform destinationTransform = pd.GetDestinationTransform();

            Vector3 wp = destinationTransform.TransformPoint(originTransform.InverseTransformPoint(playerPos));
            Quaternion rRot = destinationTransform.rotation * Quaternion.Inverse(originTransform.rotation);

            Quaternion playerRot;

            if (_isUserInVR)
            {
                playerRot = _localPlayer.GetRotation();
            }
            else
            {
                // DesktopMode で落下アニメーション中に localPlayer.GetRotation() でプレイヤーの回転を取得するとおかしくなる
                // かわりに VRCCameraSettings.GetEyeRotation を使う
                playerRot = VRCCameraSettings.GetEyeRotation(Camera.StereoscopicEye.Left);
            }

            _localPlayer.TeleportTo(wp, rRot * playerRot);
            _localPlayer.SetVelocity(rRot * _localPlayer.GetVelocity());

            break;
        }
    }
}

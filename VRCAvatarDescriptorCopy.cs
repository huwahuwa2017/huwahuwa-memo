//2022/07/18

#if UNITY_EDITOR

using System;
using System.Linq;
using UnityEditor;
using UnityEngine;
using VRC.Core;
using VRC.SDK3.Avatars.Components;

public class VRCAvatarDescriptorCopy : MonoBehaviour
{
    [SerializeField]
    private GameObject _source;

    private Transform[] _transformArray;

    private SkinnedMeshRenderer[] _skinnedMeshRendererArray;

    public void Copy()
    {
        if (_source == null)
        {
            Debug.Log("コピー元となるゲームオブジェクトを設定してください");
            return;
        }

        PipelineManager mpm = gameObject.GetComponent<PipelineManager>();
        VRCAvatarDescriptor mad = gameObject.GetComponent<VRCAvatarDescriptor>();

        mpm = mpm ?? gameObject.AddComponent<PipelineManager>();
        mad = mad ?? gameObject.AddComponent<VRCAvatarDescriptor>();

        string tpmj = JsonUtility.ToJson(_source.GetComponent<PipelineManager>());
        string tadj = JsonUtility.ToJson(_source.GetComponent<VRCAvatarDescriptor>());

        Debug.Log("PipelineManager : \n" + tpmj);
        Debug.Log("VRCAvatarDescriptor : \n" + tadj);

        JsonUtility.FromJsonOverwrite(tpmj, mpm);
        JsonUtility.FromJsonOverwrite(tadj, mad);



        _transformArray = gameObject.GetComponentsInChildren<Transform>();
        _skinnedMeshRendererArray = gameObject.GetComponentsInChildren<SkinnedMeshRenderer>();

        TransformUpdate(mad.lipSyncJawBone, i => mad.lipSyncJawBone = i);
        SkinnedMeshRendererUpdate(mad.VisemeSkinnedMesh, i => mad.VisemeSkinnedMesh = i);

        VRCAvatarDescriptor.CustomEyeLookSettings cels = mad.customEyeLookSettings;
        TransformUpdate(cels.leftEye, i => cels.leftEye = i);
        TransformUpdate(cels.rightEye, i => cels.rightEye = i);
        TransformUpdate(cels.upperLeftEyelid, i => cels.upperLeftEyelid = i);
        TransformUpdate(cels.upperRightEyelid, i => cels.upperRightEyelid = i);
        TransformUpdate(cels.lowerLeftEyelid, i => cels.lowerLeftEyelid = i);
        TransformUpdate(cels.lowerRightEyelid, i => cels.lowerRightEyelid = i);
        SkinnedMeshRendererUpdate(cels.eyelidsSkinnedMesh, i => cels.eyelidsSkinnedMesh = i);
        mad.customEyeLookSettings = cels;
    }

    private void TransformUpdate(Transform target, Action<Transform> action)
    {
        if (target == null) return;
        action(SearchTransform(target.name));
    }

    private Transform SearchTransform(string search)
    {
        Transform result = _transformArray.FirstOrDefault(i => i.name == search);

        if (result == null)
        {
            Debug.Log("Transform : " + search + "が見つかりません");
        }

        return result;
    }

    private void SkinnedMeshRendererUpdate(SkinnedMeshRenderer target, Action<SkinnedMeshRenderer> action)
    {
        if (target == null) return;
        action(SearchSkinnedMeshRenderer(target.name));
    }

    private SkinnedMeshRenderer SearchSkinnedMeshRenderer(string search)
    {
        SkinnedMeshRenderer result = _skinnedMeshRendererArray.FirstOrDefault(i => i.name == search);

        if (result == null)
        {
            Debug.Log("SkinnedMeshRenderer : " + search + "が見つかりません");
        }

        return result;
    }
}

[CustomEditor(typeof(VRCAvatarDescriptorCopy))]
public class VRCAvatarDescriptorCopyEditor : Editor
{
    private VRCAvatarDescriptorCopy _instance;

    private SerializedProperty _sourceProp;

    private void OnEnable()
    {
        _instance = target as VRCAvatarDescriptorCopy;

        _sourceProp = serializedObject.FindProperty("_source");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        EditorGUILayout.PropertyField(_sourceProp);
        serializedObject.ApplyModifiedProperties();

        GUILayout.Space(10f);

        if (GUILayout.Button("Copy"))
        {
            _instance.Copy();
        }
    }
}

#endif

/*
6群遅発中性子モデル は次の URL から引用
https://nucleide.nukehub.org/tutorials/interactive/kinetics

遅発中性子割合 と 崩壊定数 は次の PDF の 106 ページ目から引用
https://www.engr.psu.edu/conedmat/courses/nuce497a/lamarsh_baratta-introduction_to_nuclear_engineering_textbook_3rd_edition.pdf

インアワー方程式 は次の URL から引用
https://en.wikipedia.org/wiki/Inhour_equation
*/

using UnityEngine;

public class Neutron10 : MonoBehaviour
{
    [SerializeField, Range(-1f, 1f)]
    float _reactivitySpeed = 0f;

    // 反応度
    [SerializeField]
    float _reactivity = 0f;

    [SerializeField]
    float _debugKeffective = 1f;

    [SerializeField]
    float _debugNeutronPopulation = 0;

    [SerializeField]
    float _debugReactorPeriod = 0;


    // 中性子の数
    float _neutronPopulation = 100f;

    // 遅発中性子割合 (β_i)
    float[] _delayedFractions = new float[] { 0.000215f, 0.001424f, 0.001274f, 0.002568f, 0.000748f, 0.000273f };

    // 崩壊定数 (λ_i)
    float[] _decayConstants = new float[] { 0.0124f, 0.0305f, 0.111f, 0.301f, 1.14f, 3.01f };

    // 遅発中性子先行核の濃度 (C_i)
    float[] _precursors = new float[6];

    // 遅発中性子割合の合計 (β)
    float _totalDelayedFraction = 0.006502f;

    // 即発中性子の世代時間 (Λ) (中性子が発生してから吸収・核分裂を経て次の中性子が発生するまでの平均時間)
    float _generationTime = 0.0001f;


    // ReactorPeriod の逆数
    float _invReactorPeriod = 0f;


    private void Start()
    {
        // _precursors の初期値を設定
        for (int index = 0; index < 6; ++index)
        {
            _precursors[index] = _neutronPopulation * _delayedFractions[index] / (_generationTime * _decayConstants[index]);
        }
    }

    private void FixedUpdate()
    {
        float dt = Time.fixedDeltaTime;

        _reactivitySpeed = Mathf.Round(_reactivitySpeed);

        _reactivity = _reactivity + _reactivitySpeed * 0.0001f * dt;

        float k_effective = 1f / (1f - _reactivity);
        _debugKeffective = k_effective;




        // 前進オイラー法
        // dn/dt
        float dnp = _neutronPopulation * (_reactivity - _totalDelayedFraction) / _generationTime;

        for (int index = 0; index < 6; ++index)
        {
            dnp = dnp + _decayConstants[index] * _precursors[index];

            // dC_i/dt
            float dpc = _neutronPopulation * _delayedFractions[index] / _generationTime - _decayConstants[index] * _precursors[index];
            _precursors[index] = _precursors[index] + dpc * dt;
        }

        _neutronPopulation = _neutronPopulation + dnp * dt;

        _debugNeutronPopulation = _neutronPopulation;




        // インアワー方程式をニュートン法で解いて _invReactorPeriod を求める
        // 通常のインアワー方程式
        float inhour = _invReactorPeriod * _generationTime - _reactivity;

        // 微分したインアワー方程式
        float derivativeInhour = _generationTime;

        for (int index = 0; index < 6; ++index)
        {
            // 通常のインアワー方程式
            inhour = inhour + (_invReactorPeriod * _delayedFractions[index]) / (_invReactorPeriod + _decayConstants[index]);

            // 微分したインアワー方程式
            float temp = _invReactorPeriod + _decayConstants[index];
            derivativeInhour = derivativeInhour + (_delayedFractions[index] * _decayConstants[index]) / (temp * temp);
        }

        // ニュートン法
        _invReactorPeriod = _invReactorPeriod - inhour / derivativeInhour;

        if (_reactivity < 0f)
        {
            // 反応度が負の場合
            float epsilon = 0.0001f;
            _invReactorPeriod = Mathf.Clamp(_invReactorPeriod, -_decayConstants[0] + epsilon, 0f);
        }
        else
        {
            // 反応度が正の場合
            _invReactorPeriod = Mathf.Max(_invReactorPeriod, 0f);
        }

        _debugReactorPeriod = 1f / _invReactorPeriod;
    }
}

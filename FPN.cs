using System;

namespace HuwaDataStruct
{
    public struct FPN : IComparable, IComparable<FPN>, IEquatable<FPN>
    {
        private static readonly uint _floatOne = 0x3F800000;

        //0~23
        private static readonly int _decimalPointPosition = 16;

        private static readonly double _magnification = 1 << _decimalPointPosition;



        public static explicit operator FPN(uint value) => new FPN(value);

        public static explicit operator FPN(int value) => new FPN(value);

        public static explicit operator FPN(ulong value) => new FPN(value);

        public static explicit operator FPN(long value) => new FPN(value);

        public static explicit operator FPN(double value) => new FPN(value);

        public static explicit operator FPN(float value) => new FPN(value);

        public static explicit operator long(FPN value) => value.ToLong();

        public static explicit operator double(FPN value) => value.ToDouble();

        public static explicit operator float(FPN value) => value.ToFloat();



        public static FPN operator +(FPN value) => new FPN { _FPN = +value._FPN };

        public static FPN operator -(FPN value) => new FPN { _FPN = -value._FPN };

        public static FPN operator +(FPN left, FPN right) => new FPN { _FPN = left._FPN + right._FPN };

        public static FPN operator -(FPN left, FPN right) => new FPN { _FPN = left._FPN - right._FPN };

        public static FPN operator *(FPN left, FPN right)
        {
            long leftAbs = Math.Abs(left._FPN);
            long rightAbs = Math.Abs(right._FPN);

            byte leftBitCount = 0;
            byte rightBitCount = 0;

            for (int i = 0; i < 63; ++i)
            {
                leftBitCount += (byte)((leftAbs >> i) & 1);
                rightBitCount += (byte)((rightAbs >> i) & 1);
            }

            if (leftBitCount < rightBitCount)
            {
                FPN temp_0 = left;
                left = right;
                right = temp_0;

                leftAbs = Math.Abs(left._FPN);
                rightAbs = Math.Abs(right._FPN);
            }



            long data = 0;
            bool overflow = false;

            for (int i = 0; i < 64; ++i)
            {
                unsafe
                {
                    long temp_0 = (rightAbs >> i) & 1;

                    if (!*(bool*)&temp_0)
                    {
                        continue;
                    }
                }

                int shift = i - _decimalPointPosition;
                long add = 0;

                if (shift < 0)
                {
                    add = leftAbs >> -shift;
                }
                else
                {
                    add = leftAbs << shift;
                }

                data += add;
                overflow |= add < 0;
            }

            unsafe
            {
                long leftSign = left._FPN >> 63;
                long rightSign = right._FPN >> 63;

                if ((*(bool*)&leftSign) ^ (*(bool*)&rightSign))
                {
                    data = -data;
                }
            }

            if (overflow)
            {
                byte temp_3 = byte.MaxValue;
                temp_3 += 1;
            }

            return new FPN { _FPN = data };
        }

        public static FPN operator /(FPN left, FPN right)
        {
            if (right._FPN == 0)
            {
                throw new DivideByZeroException();
            }

            long leftAbs = Math.Abs(left._FPN);
            long rightAbs = Math.Abs(right._FPN);

            int shift = 1;

            while ((rightAbs >> shift) != 0)
            {
                ++shift;
            }



            long sub = rightAbs << (63 - shift);
            long temp_0 = left._FPN;
            long data = 0;

            for (int i = 0; i < 63; ++i)
            {
                data = data << 1;

                if (temp_0 >= sub)
                {
                    temp_0 -= sub;
                    data |= 1;
                }

                sub = sub >> 1;
            }

            unsafe
            {
                long leftSign = left._FPN >> 63;
                long rightSign = right._FPN >> 63;

                if ((*(bool*)&leftSign) ^ (*(bool*)&rightSign))
                {
                    data = -data;
                }
            }

            return new FPN { _FPN = data };
        }

        public static bool operator ==(FPN left, FPN right) => left._FPN == right._FPN;

        public static bool operator !=(FPN left, FPN right) => left._FPN != right._FPN;

        public static bool operator <(FPN left, FPN right) => left._FPN < right._FPN;

        public static bool operator >(FPN left, FPN right) => left._FPN > right._FPN;

        public static bool operator <=(FPN left, FPN right) => left._FPN <= right._FPN;

        public static bool operator >=(FPN left, FPN right) => left._FPN >= right._FPN;



        private long _FPN;

        public FPN(uint d)
        {
            _FPN = (long)d << _decimalPointPosition;
        }

        public FPN(int d)
        {
            _FPN = (long)d << _decimalPointPosition;
        }

        public FPN(ulong d)
        {
            _FPN = (long)d << _decimalPointPosition;
        }

        public FPN(long d)
        {
            _FPN = d << _decimalPointPosition;
        }

        public FPN(float d)
        {
            _FPN = (long)(d * _magnification);
        }

        public FPN(double d)
        {
            _FPN = (long)(d * _magnification);
        }

        public override bool Equals(object value)
        {
            return value is FPN && this == (FPN)value;
        }

        public override int GetHashCode()
        {
            return _FPN.GetHashCode();
        }

        public override string ToString()
        {
            return ToLong().ToString() + GetDecimalPlaceAbs().ToString().Remove(0, 1);
        }

        public bool Equals(FPN value)
        {
            return this == value;
        }

        public int CompareTo(object value)
        {
            if (value == null || !(value is FPN))
            {
                throw new ArgumentException("Object must be of type FPN.");
            }

            return _FPN.CompareTo(((FPN)value)._FPN);
        }

        public int CompareTo(FPN value)
        {
            return _FPN.CompareTo(value._FPN);
        }

        public long ToLong()
        {
            return _FPN >> _decimalPointPosition;
        }

        public double ToDouble()
        {
            return _FPN / _magnification;
        }

        public float ToFloat()
        {
            return (float)ToDouble();
        }

        public float GetDecimalPlace()
        {
            uint sign = (uint)(_FPN >> 32) & 0x80000000;
            uint data = (uint)Math.Abs(_FPN) << (32 - _decimalPointPosition) >> 9;
            data = sign | data | _floatOne;
            uint data2 = sign | _floatOne;

            unsafe
            {
                return (*(float*)&data) - (*(float*)&data2);
            }
        }

        public float GetDecimalPlaceAbs()
        {
            uint data = (uint)Math.Abs(_FPN) << (32 - _decimalPointPosition) >> 9;
            data = data | _floatOne;

            unsafe
            {
                return (*(float*)&data) - 1f;
            }
        }

        public long GetInternalData()
        {
            return _FPN;
        }

        public void SetInternalData(long value)
        {
            _FPN = value;
        }
    }
}

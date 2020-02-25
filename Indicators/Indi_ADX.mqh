//+------------------------------------------------------------------+
//|                                                EA31337 framework |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Includes.
#include "../Indicator.mqh"

// Indicator line identifiers used in ADX indicator.
enum ENUM_ADX_LINE {
#ifdef __MQL4__
  LINE_MAIN_ADX = MODE_MAIN,    // Base indicator line.
  LINE_PLUSDI   = MODE_PLUSDI,  // +DI indicator line.
  LINE_MINUSDI  = MODE_MINUSDI, // -DI indicator line.
#else
  LINE_MAIN_ADX = MAIN_LINE,    // Base indicator line.
  LINE_PLUSDI   = PLUSDI_LINE,  // +DI indicator line.
  LINE_MINUSDI  = MINUSDI_LINE, // -DI indicator line.
#endif
  FINAL_ADX_LINE_ENTRY,
};

// Structs.   
struct ADXEntry : IndicatorEntry {
  double value[FINAL_ADX_LINE_ENTRY];
  string ToString(int _mode = EMPTY) {
    return StringFormat("%g,%g,%g",
      value[LINE_MAIN_ADX], value[LINE_PLUSDI], value[LINE_MINUSDI]);
  }
  bool IsValid() {
    return
      fmin(fmin(value[LINE_MAIN_ADX], value[LINE_PLUSDI]), value[LINE_MINUSDI]) >= 0
      && fmax(fmax(value[LINE_MAIN_ADX], value[LINE_PLUSDI]), value[LINE_MINUSDI]) <= 100;
  }
};
struct ADXParams : IndicatorParams {
  unsigned int period;
  ENUM_APPLIED_PRICE applied_price;
  // Struct constructor.
  void ADXParams(unsigned int _period, ENUM_APPLIED_PRICE _applied_price)
    : period(_period), applied_price(_applied_price) {
    dtype = TYPE_DOUBLE;
    itype = INDI_ADX;
    max_modes = FINAL_ADX_LINE_ENTRY;
   };
};

/**
 * Implements the Average Directional Movement Index indicator.
 */
class Indi_ADX : public Indicator {

 protected:

  ADXParams params;

 public:

  /**
   * Class constructor.
   */
  Indi_ADX(ADXParams &_params)
    : params(_params.period, _params.applied_price), Indicator((IndicatorParams) _params) { }
  Indi_ADX(ADXParams &_params, ENUM_TIMEFRAMES _tf)
    : params(_params.period, _params.applied_price), Indicator(INDI_ADX, _tf) { }

  /**
    * Returns the indicator value.
    *
    * @docs
    * - https://docs.mql4.com/indicators/iadx
    * - https://www.mql5.com/en/docs/indicators/iadx
    */
  static double iADX(
      string _symbol,
      ENUM_TIMEFRAMES _tf,
      unsigned int _period,
      ENUM_APPLIED_PRICE _applied_price,   // (MT5): not used
      ENUM_ADX_LINE _mode = LINE_MAIN_ADX, // (MT4/MT5): 0 - MODE_MAIN/MAIN_LINE, 1 - MODE_PLUSDI/PLUSDI_LINE, 2 - MODE_MINUSDI/MINUSDI_LINE
      int _shift = 0,
      Indicator *_obj = NULL
      ) {
#ifdef __MQL4__
    return ::iADX(_symbol, _tf, _period, _applied_price, _mode, _shift);
#else // __MQL5__
    int _handle = Object::IsValid(_obj) ? _obj.GetState().GetHandle() : NULL;
    double _res[];
    if (_handle == NULL || _handle == INVALID_HANDLE) {
      if ((_handle = ::iADX(_symbol, _tf, _period)) == INVALID_HANDLE) {
        SetUserError(ERR_USER_INVALID_HANDLE);
        return EMPTY_VALUE;
      }
      else if (Object::IsValid(_obj)) {
        _obj.SetHandle(_handle);
      }
    }
    int _bars_calc = BarsCalculated(_handle);
    if (_bars_calc < 2) {
      SetUserError(ERR_USER_INVALID_BUFF_NUM);
      return EMPTY_VALUE;
    }
    if (CopyBuffer(_handle, _mode, -_shift, 1, _res) < 0) {
      return EMPTY_VALUE;
    }
    return _res[0];
#endif
  }

  /**
    * Returns the indicator's value.
    */
  double GetValue(ENUM_ADX_LINE _mode = LINE_MAIN_ADX, int _shift = 0) {
    double _value = Indi_ADX::iADX(GetSymbol(), GetTf(), GetPeriod(), GetAppliedPrice(), _mode, _shift, GetPointer(this));
    istate.is_ready = _LastError == ERR_NO_ERROR;
    istate.is_changed = false;
    return _value;
  }

  /**
    * Returns the indicator's struct value.
    */
  ADXEntry GetEntry(int _shift = 0) {
    ADXEntry _entry;
    _entry.timestamp = GetBarTime(_shift);
    _entry.value[LINE_MAIN_ADX] = GetValue(LINE_MAIN_ADX, _shift);
    _entry.value[LINE_PLUSDI] = GetValue(LINE_PLUSDI, _shift);
    _entry.value[LINE_MINUSDI] = GetValue(LINE_MINUSDI, _shift);
    if (_entry.IsValid()) { _entry.AddFlags(INDI_ENTRY_FLAG_IS_VALID); }
    return _entry;
  }

  /**
   * Returns the indicator's entry value.
   */
  MqlParam GetEntryValue(int _shift = 0, int _mode = 0) {
    MqlParam _param = {TYPE_DOUBLE};
    _param.double_value = GetEntry(_shift).value[_mode];
    return _param;
  }

    /* Class getters */

    /**
     * Get period value.
     */
    unsigned int GetPeriod() {
      return params.period;
    }

    /**
     * Get applied price value.
     *
     * Note: Not used in MT5.
     */
    ENUM_APPLIED_PRICE GetAppliedPrice() {
      return params.applied_price;
    }

    /* Setters */

    /**
     * Set period value.
     */
    void SetPeriod(unsigned int _period) {
      istate.is_changed = true;
      params.period = _period;
    }

    /**
     * Set applied price value.
     *
     * Note: Not used in MT5.
     */
    void SetAppliedPrice(ENUM_APPLIED_PRICE _applied_price) {
      istate.is_changed = true;
      params.applied_price = _applied_price;
    }

  /* Printer methods */

  /**
   * Returns the indicator's value in plain format.
   */
  string ToString(int _shift = 0, int _mode = EMPTY) {
    return GetEntry(_shift).ToString(_mode);
  }

};

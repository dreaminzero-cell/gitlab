/**
 * Formats a number as string using `toLocaleString`.
 *
 * @param {Number} number to be converted
 * @param {params} Parameters
 * @param {params.fractionDigits} Number of decimal digits
 * to display, defaults to using `toLocaleString` defaults.
 * @param {params.maxLength} Max output char lenght at the
 * expense of precision, if the output is longer than this,
 * the formatter switches to using exponential notation.
 * @param {params.factor} Value is multiplied by this factor,
 * useful for value normalization.
 * @returns Formatted value
 */
function formatFixedPoint(
  value,
  { fractionDigits = undefined, maxLength = undefined, valueFactor = 1 },
) {
  if (value === null) {
    return '';
  }

  const num = value * valueFactor;
  const formatted = num.toLocaleString(undefined, {
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  });

  if (maxLength !== undefined && formatted.length > maxLength) {
    // 123456 becomes 1.23e+8
    return num.toExponential(2);
  }
  return formatted;
}

/**
 * Formats a number as a string scaling it up according to units.
 *
 * While the number is scaled down, the units are scaled up.
 *
 * @param {Array} List of units of the scale
 * @param {Number} unitFactor - Factor of the scale for each
 * unit after which the next unit is used scaled.
 */
const scaledFormatter = (units, unitFactor = 1000) => {
  return (value, fractionDigits) => {
    if (value === null) {
      return '';
    }
    if (
      value === Number.NEGATIVE_INFINITY ||
      value === Number.POSITIVE_INFINITY ||
      Number.isNaN(value)
    ) {
      return value.toLocaleString(undefined);
    }

    let num = value;
    let scale = 0;
    const limit = units.length;

    while (Math.abs(num) >= unitFactor) {
      scale += 1;
      num /= unitFactor;

      if (scale >= limit) {
        return 'NA';
      }
    }

    const unit = units[scale];

    return `${formatFixedPoint(num, { fractionDigits })}${unit}`;
  };
};

/**
 * Returns a function that formats a number as a string.
 */
export const numberFormatter = (valueFactor = 1) => {
  return (value, fractionDigits, maxLength) => {
    return `${formatFixedPoint(value, { fractionDigits, maxLength, valueFactor })}`;
  };
};

/**
 * Returns a function that formats a number as a string with a suffix.
 */
export const suffixFormatter = (unit = '', valueFactor = 1) => {
  return (value, fractionDigits, maxLength) => {
    const length = maxLength !== undefined ? maxLength - unit.length : undefined;
    return `${formatFixedPoint(value, { fractionDigits, maxLength: length, valueFactor })}${unit}`;
  };
};

/**
 * Returns a function that formats a number scaled using SI units notation.
 */
export const scaledSIFormatter = (unit = '', prefixOffset = 0) => {
  const fractional = ['y', 'z', 'a', 'f', 'p', 'n', 'µ', 'm'];
  const multiplicative = ['k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y'];
  const symbols = [...fractional, '', ...multiplicative];

  const units = symbols.slice(fractional.length + prefixOffset).map(prefix => {
    return `${prefix}${unit}`;
  });

  if (!units.length) {
    // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
    throw new RangeError('The unit cannot be converted, please try a different scale');
  }

  return scaledFormatter(units);
};

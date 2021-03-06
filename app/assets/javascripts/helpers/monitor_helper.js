/**
 * @param {String} queryLabel - Default query label for chart
 * @param {Object} metricAttributes - Default metric attribute values (e.g. method, instance)
 * @returns {String} The formatted query label
 * @example
 * singleAttributeLabel('app', {__name__: "up", app: "prometheus"}) -> "app: prometheus"
 */
const singleAttributeLabel = (queryLabel, metricAttributes) => {
  if (!queryLabel) return '';
  const relevantAttribute = queryLabel.toLowerCase().replace(' ', '_');
  const value = metricAttributes[relevantAttribute];
  if (!value) return '';
  return `${queryLabel}: ${value}`;
};

/**
 * @param {String} queryLabel - Default query label for chart
 * @param {Object} metricAttributes - Default metric attribute values (e.g. method, instance)
 * @returns {String} The formatted query label
 * @example
 * templatedLabel('__name__', {__name__: "up", app: "prometheus"}) -> "__name__"
 */
const templatedLabel = (queryLabel, metricAttributes) => {
  if (!queryLabel) return '';
  // eslint-disable-next-line array-callback-return
  Object.entries(metricAttributes).map(([templateVar, label]) => {
    const regex = new RegExp(`{{\\s*${templateVar}\\s*}}`, 'g');
    // eslint-disable-next-line no-param-reassign
    queryLabel = queryLabel.replace(regex, label);
  });

  return queryLabel;
};

/**
 * @param {Object} metricAttributes - Default metric attribute values (e.g. method, instance)
 * @returns {String} The formatted query label
 * @example
 * multiMetricLabel('', {__name__: "up", app: "prometheus"}) -> "__name__: up, app: prometheus"
 */
const multiMetricLabel = metricAttributes => {
  return Object.entries(metricAttributes)
    .map(([templateVar, label]) => `${templateVar}: ${label}`)
    .join(', ');
};

/**
 * @param {String} queryLabel - Default query label for chart
 * @param {Object} metricAttributes - Default metric attribute values (e.g. method, instance)
 * @returns {String} The formatted query label
 */
const getSeriesLabel = (queryLabel, metricAttributes) => {
  return (
    singleAttributeLabel(queryLabel, metricAttributes) ||
    templatedLabel(queryLabel, metricAttributes) ||
    multiMetricLabel(metricAttributes) ||
    queryLabel
  );
};

/**
 * @param {Array} queryResults - Array of Result objects
 * @param {Object} defaultConfig - Default chart config values (e.g. lineStyle, name)
 * @returns {Array} The formatted values
 */
// eslint-disable-next-line import/prefer-default-export
export const makeDataSeries = (queryResults, defaultConfig) =>
  queryResults
    .map(result => {
      // NaN values may disrupt avg., max. & min. calculations in the legend, filter them out
      const data = result.values.filter(([, value]) => !Number.isNaN(value));
      if (!data.length) {
        return null;
      }
      const series = { data };
      return {
        ...defaultConfig,
        ...series,
        name: getSeriesLabel(defaultConfig.name, result.metric),
      };
    })
    .filter(series => series !== null);

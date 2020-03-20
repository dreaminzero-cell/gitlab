import { backOff } from '~/lib/utils/common_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { s__ } from '~/locale';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import { TOKEN_TYPE_POD_NAME } from '../constants';

import * as types from './mutation_types';

const flashTimeRangeWarning = () => {
  flash(s__('Metrics|Invalid time range, please verify.'), 'warning');
};

const flashLogsError = () => {
  flash(s__('Metrics|There was an error fetching the logs, please try again'));
};

const requestUntilData = (url, params) =>
  backOff((next, stop) => {
    axios
      .get(url, { params })
      .then(res => {
        if (res.status === httpStatusCodes.ACCEPTED) {
          next();
          return;
        }
        stop(res);
      })
      .catch(err => {
        stop(err);
      });
  });

const requestLogsUntilData = state => {
  const params = {};
  const { logs_api_path } = state.environments.options.find(
    ({ name }) => name === state.environments.current,
  );

  if (state.pods.current) {
    params.pod_name = state.pods.current;
  }
  if (state.search) {
    params.search = state.search;
  }
  if (state.timeRange.current) {
    try {
      const { start, end } = convertToFixedRange(state.timeRange.current);
      params.start_time = start;
      params.end_time = end;
    } catch {
      flashTimeRangeWarning();
    }
  }
  if (state.logs.cursor) {
    params.cursor = state.logs.cursor;
  }

  return requestUntilData(logs_api_path, params);
};

/**
 * Converts filters emitted by the component, e.g. a filterered-search
 * to parameters to be applied to the filters of the store
 * @param {Array} filters - List of strings or objects to filter by.
 * @returns {Object} - An object with `search` and `podName` keys.
 */
const filtersToParams = (filters = []) => {
  // Strings become part of the `search`
  const search = filters.filter(f => typeof f === 'string').join(' ');

  // Objects become other params
  const defaults = {
    podName: null,
  };
  const otherParams = filters
    .filter(f => f && typeof f === 'object')
    .reduce((acc, { type, value }) => {
      if (type === TOKEN_TYPE_POD_NAME) {
        return { ...acc, podName: value.data };
      }
      return acc;
    }, defaults);

  return { search, ...otherParams };
};

export const setInitData = ({ commit }, { timeRange, environmentName, podName }) => {
  commit(types.SET_TIME_RANGE, timeRange);
  commit(types.SET_PROJECT_ENVIRONMENT, environmentName);
  commit(types.SET_CURRENT_POD_NAME, podName);
};

export const showFilteredLogs = ({ dispatch, commit }, filters = []) => {
  const { podName, search } = filtersToParams(filters);

  commit(types.SET_CURRENT_POD_NAME, podName);
  commit(types.SET_SEARCH, search);

  dispatch('fetchLogs');
};

export const showPodLogs = ({ dispatch, commit }, podName) => {
  commit(types.SET_CURRENT_POD_NAME, podName);
  dispatch('fetchLogs');
};

export const setTimeRange = ({ dispatch, commit }, timeRange) => {
  commit(types.SET_TIME_RANGE, timeRange);
  dispatch('fetchLogs');
};

export const showEnvironment = ({ dispatch, commit }, environmentName) => {
  commit(types.SET_PROJECT_ENVIRONMENT, environmentName);
  dispatch('fetchLogs');
};

/**
 * Fetch environments data and initial logs
 * @param {Object} store
 * @param {String} environmentsPath
 */
export const fetchEnvironments = ({ commit, dispatch }, environmentsPath) => {
  commit(types.REQUEST_ENVIRONMENTS_DATA);

  return axios
    .get(environmentsPath)
    .then(({ data }) => {
      commit(types.RECEIVE_ENVIRONMENTS_DATA_SUCCESS, data.environments);
      dispatch('fetchLogs');
    })
    .catch(() => {
      commit(types.RECEIVE_ENVIRONMENTS_DATA_ERROR);
      flash(s__('Metrics|There was an error fetching the environments data, please try again'));
    });
};

export const fetchLogs = ({ commit, state }) => {
  commit(types.REQUEST_LOGS_DATA);

  return requestLogsUntilData(state)
    .then(({ data }) => {
      const { pod_name, pods, logs, cursor } = data;
      commit(types.RECEIVE_LOGS_DATA_SUCCESS, { logs, cursor });

      commit(types.SET_CURRENT_POD_NAME, pod_name);

      commit(types.RECEIVE_PODS_DATA_SUCCESS, pods);
    })
    .catch(() => {
      commit(types.RECEIVE_PODS_DATA_ERROR);
      commit(types.RECEIVE_LOGS_DATA_ERROR);
      flashLogsError();
    });
};

export const fetchMoreLogsPrepend = ({ commit, state }) => {
  if (state.logs.isComplete) {
    // return when all logs are loaded
    return Promise.resolve();
  }

  commit(types.REQUEST_LOGS_DATA_PREPEND);

  return requestLogsUntilData(state)
    .then(({ data }) => {
      const { logs, cursor } = data;
      commit(types.RECEIVE_LOGS_DATA_PREPEND_SUCCESS, { logs, cursor });
    })
    .catch(() => {
      commit(types.RECEIVE_LOGS_DATA_PREPEND_ERROR);
      flashLogsError();
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};

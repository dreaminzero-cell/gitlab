import { activityBarViews, viewerTypes } from '../constants';

export default () => ({
  currentProjectId: '',
  currentBranchId: '',
  currentMergeRequestId: '',
  changedFiles: [],
  stagedFiles: [],
  endpoints: {},
  lastCommitMsg: '',
  lastCommitPath: '',
  loading: false,
  openFiles: [],
  parentTreeUrl: '',
  trees: {},
  projects: {},
  leftPanelCollapsed: false,
  rightPanelCollapsed: false,
  panelResizing: false,
  entries: {},
  viewer: viewerTypes.edit,
  delayViewerUpdated: false,
  currentActivityView: activityBarViews.edit,
  unusedSeal: true,
  fileFindVisible: false,
  links: {},
  errorMessage: null,
  entryModal: {
    type: '',
    path: '',
    entry: {},
  },
  clientsidePreviewEnabled: false,
  renderWhitespaceInCode: false,
  editorTheme: '',
});

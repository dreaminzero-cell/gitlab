<script>
import { mapState, mapActions } from 'vuex';
import { GlBadge, GlLoadingIcon, GlEmptyState, GlPagination } from '@gitlab/ui';
import MergeRequestTable from './merge_request_table.vue';

export default {
  components: {
    GlBadge,
    GlLoadingIcon,
    GlPagination,
    GlEmptyState,
    MergeRequestTable,
  },
  props: {
    projectId: {
      type: Number,
      required: true,
    },
    newMergeRequestUrl: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState({
      isLoading: 'isLoading',
      perPage: state => state.pageInfo.perPage,
      totalItems: state => state.pageInfo.total,
      page: state => state.pageInfo.page,
    }),
    currentPage: {
      get() {
        return this.page;
      },
      set(newVal) {
        this.setPage(newVal);
        this.fetchMergeRequests();
      },
    },
  },
  created() {
    this.setProjectId(this.projectId);
    this.fetchMergeRequests();
  },
  methods: {
    ...mapActions(['setProjectId', 'fetchMergeRequests', 'setPage']),
  },
};
</script>

<template>
  <div class="mt-2">
    <gl-loading-icon v-show="isLoading" size="md" class="mt-3" />
    <template v-if="!isLoading">
      <gl-empty-state
        v-if="!totalItems"
        :title="__(`You don't have any open merge requests`)"
        :primary-button-text="__('New merge request')"
        :primary-button-link="newMergeRequestUrl"
        :svg-path="emptyStateSvgPath"
      >
        <template #description>
          <div class="text-center">
            <p>
              {{
                __(
                  'Code Review Analytics displays a table of open merge requests considered to be in code review. There are currently no merge requests in review for this project and/or filters.',
                )
              }}
            </p>
          </div>
        </template>
      </gl-empty-state>
      <template v-else>
        <div>
          <span class="font-weight-bold">{{ __('Merge Requests in Review') }}</span>
          <gl-badge pill>{{ totalItems }}</gl-badge>
        </div>
        <merge-request-table />
        <gl-pagination
          v-model="currentPage"
          :per-page="perPage"
          :total-items="totalItems"
          align="center"
          class="w-100"
        />
      </template>
    </template>
  </div>
</template>

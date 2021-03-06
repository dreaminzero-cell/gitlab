<script>
import { isString } from 'lodash';

import { GlLink, GlNewButton } from '@gitlab/ui';

const validateUrlAndLabel = value => isString(value.label) && isString(value.url);

export default {
  components: {
    GlLink,
    GlNewButton,
  },
  props: {
    branch: {
      type: Object,
      required: true,
      validator: validateUrlAndLabel,
    },
    commit: {
      type: Object,
      required: true,
      validator: validateUrlAndLabel,
    },
    mergeRequest: {
      type: Object,
      required: true,
      validator: validateUrlAndLabel,
    },
    returnUrl: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <div class="border-bottom pb-4">
      <h3>{{ s__('StaticSiteEditor|Success!') }}</h3>
      <p>
        {{
          s__(
            'StaticSiteEditor|Your changes have been submitted and a merge request has been created. The changes won’t be visible on the site until the merge request has been accepted.',
          )
        }}
      </p>
      <div class="d-flex justify-content-end">
        <gl-new-button ref="returnToSiteButton" :href="returnUrl">{{
          s__('StaticSiteEditor|Return to site')
        }}</gl-new-button>
        <gl-new-button
          ref="mergeRequestButton"
          class="ml-2"
          :href="mergeRequest.url"
          variant="success"
          >{{ s__('StaticSiteEditor|View merge request') }}</gl-new-button
        >
      </div>
    </div>

    <div class="pt-2">
      <h4>{{ s__('StaticSiteEditor|Summary of changes') }}</h4>
      <ul>
        <li>
          {{ s__('StaticSiteEditor|You created a new branch:') }}
          <gl-link ref="branchLink" :href="branch.url">{{ branch.label }}</gl-link>
        </li>
        <li>
          {{ s__('StaticSiteEditor|You created a merge request:') }}
          <gl-link ref="mergeRequestLink" :href="mergeRequest.url">{{
            mergeRequest.label
          }}</gl-link>
        </li>
        <li>
          {{ s__('StaticSiteEditor|You added a commit:') }}
          <gl-link ref="commitLink" :href="commit.url">{{ commit.label }}</gl-link>
        </li>
      </ul>
    </div>
  </div>
</template>

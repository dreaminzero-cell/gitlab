<script>
import { GlDeprecatedButton, GlNewButton, GlLoadingIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import { __, s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import HistoryCommentEditor from './history_comment_editor.vue';

export default {
  components: {
    GlDeprecatedButton,
    GlNewButton,
    EventItem,
    HistoryCommentEditor,
    GlLoadingIcon,
  },

  props: {
    comment: {
      type: Object,
      required: false,
      default: undefined,
    },
    discussionId: {
      type: String,
      required: false,
      default: undefined,
    },
  },

  data() {
    return {
      isEditingComment: false,
      isSavingComment: false,
      isDeletingComment: false,
      isConfirmingDeletion: false,
    };
  },

  computed: {
    commentNote() {
      return this.comment?.note;
    },
    actionButtons() {
      return [
        {
          iconName: 'pencil',
          onClick: this.showCommentInput,
          title: __('Edit Comment'),
        },
        {
          iconName: 'remove',
          onClick: this.showDeleteConfirmation,
          title: __('Delete Comment'),
        },
      ];
    },
  },

  methods: {
    showCommentInput() {
      this.isEditingComment = true;
    },
    getSaveConfig(note) {
      const isUpdatingComment = Boolean(this.comment);
      const method = isUpdatingComment ? 'put' : 'post';
      let url = joinPaths(window.location.pathname, 'notes');
      const data = { note: { note } };
      const emitName = isUpdatingComment ? 'onCommentUpdated' : 'onCommentAdded';

      // If we're updating the comment, use the comment ID in the URL. Otherwise, use the discussion ID in the request data.
      if (isUpdatingComment) {
        url = joinPaths(url, this.comment.id);
      } else {
        data.in_reply_to_discussion_id = this.discussionId;
      }

      return { method, url, data, emitName };
    },
    saveComment(note) {
      this.isSavingComment = true;
      const { method, url, data, emitName } = this.getSaveConfig(note);

      axios({ method, url, data })
        .then(({ data: responseData }) => {
          this.isEditingComment = false;
          this.$emit(emitName, responseData, this.comment);
        })
        .catch(() => {
          createFlash(
            s__(
              'VulnerabilityManagement|Something went wrong while trying to save the comment. Please try again later.',
            ),
          );
        })
        .finally(() => {
          this.isSavingComment = false;
        });
    },
    deleteComment() {
      this.isDeletingComment = true;
      const deleteUrl = joinPaths(window.location.pathname, 'notes', this.comment.id);

      axios
        .delete(deleteUrl)
        .then(() => {
          this.$emit('onCommentDeleted', this.comment);
        })
        .catch(() =>
          createFlash(
            s__(
              'VulnerabilityManagement|Something went wrong while trying to delete the comment. Please try again later.',
            ),
          ),
        )
        .finally(() => {
          this.isDeletingComment = false;
        });
    },
    cancelEditingComment() {
      this.isEditingComment = false;
    },
    showDeleteConfirmation() {
      this.isConfirmingDeletion = true;
    },
    cancelDeleteConfirmation() {
      this.isConfirmingDeletion = false;
    },
  },
};
</script>

<template>
  <history-comment-editor
    v-if="isEditingComment"
    class="discussion-reply-holder m-3"
    :initial-comment="commentNote"
    :is-saving="isSavingComment"
    @onSave="saveComment"
    @onCancel="cancelEditingComment"
  />

  <event-item
    v-else-if="comment"
    :id="comment.id"
    :author="comment.author"
    :created-at="comment.updated_at"
    :show-action-buttons="comment.current_user.can_edit"
    :show-right-slot="isConfirmingDeletion"
    :action-buttons="actionButtons"
    icon-name="comment"
    icon-class="timeline-icon m-0"
    class="m-3"
  >
    <div v-html="comment.note"></div>

    <template #right-content>
      <gl-new-button
        ref="confirmDeleteButton"
        variant="danger"
        :disabled="isDeletingComment"
        @click="deleteComment"
      >
        <gl-loading-icon v-if="isDeletingComment" class="mr-1" />
        {{ __('Delete') }}
      </gl-new-button>
      <gl-new-button
        ref="cancelDeleteButton"
        class="ml-2"
        :disabled="isDeletingComment"
        @click="cancelDeleteConfirmation"
      >
        {{ __('Cancel') }}
      </gl-new-button>
    </template>
  </event-item>

  <div v-else class="discussion-reply-holder">
    <gl-deprecated-button ref="addCommentButton" class="btn-text-field" @click="showCommentInput">
      {{ s__('vulnerability|Add a comment') }}
    </gl-deprecated-button>
  </div>
</template>

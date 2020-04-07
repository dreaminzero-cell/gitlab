import { shallowMount } from '@vue/test-utils';
import { GlNewButton, GlLoadingIcon } from '@gitlab/ui';

import Toolbar from '~/static_site_editor/components/toolbar.vue';

describe('Static Site Editor Toolbar', () => {
  let wrapper;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(Toolbar, {
      propsData: {
        saveable: false,
        ...propsData,
      },
    });
  };

  const findSaveChangesButton = () => wrapper.find(GlNewButton);
  const findLoadingIndicator = () => wrapper.find(GlLoadingIcon);

  beforeEach(() => {
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders Submit Changes button', () => {
    expect(findSaveChangesButton().exists()).toBe(true);
  });

  it('disables Submit Changes button', () => {
    expect(findSaveChangesButton().attributes('disabled')).toBe('true');
  });

  it('displays Submit Changes label', () => {
    expect(findSaveChangesButton().text()).toBe('Save Changes');
  });

  it('does not display saving changes indicator', () => {
    expect(findLoadingIndicator().classes()).toContain('invisible');
  });

  describe('when saveable', () => {
    it('enables Submit Changes button', () => {
      buildWrapper({ saveable: true });

      expect(findSaveChangesButton().attributes('disabled')).toBeFalsy();
    });
  });

  describe('when saving changes', () => {
    beforeEach(() => {
      buildWrapper({ saveable: true, savingChanges: true });
    });

    it('disables Submit Changes button', () => {
      expect(findSaveChangesButton().attributes('disabled')).toBe('true');
    });

    it('displays saving changes indicator', () => {
      expect(findLoadingIndicator().classes()).not.toContain('invisible');
    });
  });
});

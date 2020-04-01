import CommitsList from '~/commits';
import GpgBadges from '~/gpg_badges';
import ShortcutsNavigation from '~/behaviors/shortcuts/shortcuts_navigation';

import mountCommits from 'ee/projects/commits';

document.addEventListener('DOMContentLoaded', () => {
  new CommitsList(document.querySelector('.js-project-commits-show').dataset.commitsLimit); // eslint-disable-line no-new
  new ShortcutsNavigation(); // eslint-disable-line no-new
  GpgBadges.fetch();
  mountCommits(document.getElementById('sammy'));
});

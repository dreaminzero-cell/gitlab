require 'spec_helper'

describe ObjectStorageUploadWorker do
  let(:local) { ObjectStoreUploader::LOCAL_STORE }
  let(:remote) { ObjectStoreUploader::REMOTE_STORE }

  def perform
    described_class.perform_async(uploader_class.name, subject_class, file_field, subject_id)
  end

  context 'for LFS' do
    let!(:lfs_object) { create(:lfs_object, :with_file, file_store: local) }
    let(:uploader_class) { LfsObjectUploader }
    let(:subject_class) { LfsObject }
    let(:file_field) { :file }
    let(:subject_id) { lfs_object.id }

    context 'when object storage is enabled' do
      before do
        stub_lfs_object_storage
      end

      it 'uploads object to storage' do
        expect { perform }.to change { lfs_object.reload.file_store }.from(local).to(remote)
      end

      context 'when background upload is disabled' do
        before do
          allow(Gitlab.config.lfs.object_store).to receive(:background_upload) { false }
        end

        it 'is skipped' do
          expect { perform }.not_to change { lfs_object.reload.file_store }
        end
      end
    end

    context 'when object storage is disabled' do
      before do
        stub_lfs_object_storage(enabled: false)
      end

      it "doesn't migrate files" do
        perform

        expect(lfs_object.reload.file_store).to eq(local)
      end
    end
  end

  context 'for legacy artifacts' do
    let(:build) { create(:ci_build) }
    let(:uploader_class) { ArtifactUploader }
    let(:subject_class) { Ci::Build }
    let(:file_field) { :artifacts_file }
    let(:subject_id) { build.id }

    before do
      # Mock the legacy way of artifacts
      path = Rails.root.join(uploader_class.local_store_path,
                  build.created_at.utc.strftime('%Y_%m'),
                  build.project_id.to_s,
                  build.id.to_s)

      FileUtils.mkdir_p(path)
      FileUtils.copy(
        Rails.root.join('spec/fixtures/ci_build_artifacts.zip'),
        File.join(path, "ci_build_artifacts.zip"))

      FileUtils.copy(
        Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'),
        File.join(path, "ci_build_artifacts_metadata.gz"))

      build.update_columns(
        artifacts_file: 'ci_build_artifacts.zip',
        artifacts_metadata: 'ci_build_artifacts_metadata.gz')
    end

    context 'when local storage is used' do
      let(:store) { local }

      context 'and remote storage is defined' do
        before do
          stub_artifacts_object_storage
        end

        it "migrates file to remote storage" do
          perform

          expect(build.reload.artifacts_file_store).to eq(remote)
        end

        context 'for artifacts_metadata' do
          let(:file_field) { :artifacts_metadata }

          it 'migrates metadata to remote storage' do
            perform

            expect(build.reload.artifacts_metadata_store).to eq(remote)
          end
        end
      end
    end
  end

  context 'for job artifacts' do
    let(:artifact) { create(:ci_job_artifact) }
    let(:uploader_class) { JobArtifactUploader }
    let(:subject_class) { Ci::JobArtifact }
    let(:file_field) { :file }
    let(:subject_id) { artifact.id }

    context 'when local storage is used' do
      let(:store) { local }

      context 'and remote storage is defined' do
        before do
          stub_artifacts_object_storage
        end

        it "migrates file to remote storage" do
          perform

          expect(artifact.reload.file_store).to eq(remote)
        end
      end
    end
  end
end

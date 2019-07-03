# frozen_string_literal: true

class ImportCommonMetricsKnative < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    Importers::CommonMetrics::Importer.new.execute
  end

  def down
    # no-op
  end
end

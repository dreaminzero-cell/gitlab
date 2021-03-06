# frozen_string_literal: true

class CreateClustersApplicationsFluentd < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :clusters_applications_fluentd do |t|
      t.integer :protocol, null: false, limit: 2
      t.integer :status, null: false
      t.integer :port, null: false
      t.references :cluster, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.string :version, null: false, limit: 255
      t.string :host, null: false, limit: 255
      t.text :status_reason
    end
  end
end

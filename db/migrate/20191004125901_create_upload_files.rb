# frozen_string_literal: true

class CreateUploadFiles < ActiveRecord::Migration[(Rails.version =~ /5.1/ ? 5.1 : 5.2)]
  def change
    create_table :browse_everything_upload_files do |t|
      t.string :container_id
      t.string :name

      t.timestamps
    end
  end
end

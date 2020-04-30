# frozen_string_literal: true

class AddFileAttrsUploadFiles < ActiveRecord::Migration[(Rails.version =~ /5.1/ ? 5.1 : 5.2)]
  def change
    change_table :browse_everything_upload_files do |t|
      t.string :file_path
      t.string :file_name
      t.string :file_content_type
    end
  end
end

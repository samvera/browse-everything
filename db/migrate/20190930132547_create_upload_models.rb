class CreateUploadModels < ActiveRecord::Migration[6.0]
  def change
    create_table :upload_models do |t|
      t.text :upload

      t.timestamps
    end
  end
end

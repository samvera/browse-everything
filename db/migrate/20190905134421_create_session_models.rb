class CreateSessionModels < ActiveRecord::Migration[5.2]
  def change
    create_table :session_models do |t|
      t.text :session

      t.timestamps
    end
  end
end

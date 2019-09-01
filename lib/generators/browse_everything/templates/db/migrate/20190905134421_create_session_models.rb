class CreateSessionModels < ActiveRecord::Migration[6.0]
  def change
    create_table :session_models do |t|
      t.text :session

      t.timestamps
    end
  end
end

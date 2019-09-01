class CreateAuthorizationModels < ActiveRecord::Migration[6.0]
  def change
    create_table :authorization_models do |t|
      t.text :authorization

      t.timestamps
    end
  end
end

# frozen_string_literal: true
class CreateAuthorizationModels < ActiveRecord::Migration[5.2]
  def change
    create_table :authorization_models do |t|
      t.text :authorization

      t.timestamps
    end
  end
end

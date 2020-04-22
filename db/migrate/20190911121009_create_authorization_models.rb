# frozen_string_literal: true

class CreateAuthorizationModels < ActiveRecord::Migration[(Rails.version =~ /5.1/ ? 5.1 : 5.2)]
  def change
    create_table :browse_everything_authorization_models do |t|
      t.string :uuid
      t.text :authorization

      t.timestamps
    end
  end
end

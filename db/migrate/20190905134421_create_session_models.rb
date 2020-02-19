# frozen_string_literal: true

class CreateSessionModels < ActiveRecord::Migration[(Rails.version =~ /5.1/ ? 5.1 : 5.2)]
  def change
    create_table :session_models do |t|
      t.string :uuid
      t.text :session

      t.timestamps
    end
  end
end

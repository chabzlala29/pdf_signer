class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :uuid
      t.datetime :expires_at

      t.timestamps
    end
  end
end



module MyColumnMethods

  def references_uuid(other, options={})
    options[:type] = :uuid
    options[:index] = true
    options[:foreign_key] = true
    unless options.has_key? :null
      options[:null] = false
    end
    self.references other, options
  end

end

class ActiveRecord::Migration

  # this should be used in migrations instead of create_table
  def create_model(name)
    create_table name, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.timestamps
      t.integer :_state, default: 0, null: false, index: true
      t.uuid :created_by_id, index: true
      t.text :created_by_name, null: false
      t.text :extern_id, index: true
      t.uuid :updated_by_id, index: true
      t.text :updated_by_name
      t.class.include MyColumnMethods
      yield t
    end
    add_foreign_key name, :users, column: :created_by_id
    add_foreign_key name, :users, column: :updated_by_id
  end

  # this should be used to create tables that belong to an org
  def create_org_model(name)
    create_model name do |t|
      t.references_uuid :org
      yield t
    end
  end


end

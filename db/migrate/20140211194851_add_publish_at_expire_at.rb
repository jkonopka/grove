class AddPublishAtExpireAt < ActiveRecord::Migration
  def self.up
    add_column :posts, :publish_at, :timestamp
    add_column :posts, :expire_at, :timestamp
    add_index :posts, :publish_at
    add_index :posts, :expire_at
  end

  def self.down
    remove_index :posts, :publish_at
    remove_index :posts, :expire_at
    remove_column :posts, :publish_at
    remove_column :posts, :expire_at
  end
end

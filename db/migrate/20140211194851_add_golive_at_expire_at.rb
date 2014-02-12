class AddGoliveAtExpireAt < ActiveRecord::Migration
  def self.up
    add_column :posts, :golive_at, :datetime
    add_column :posts, :expire_at, :datetime
    add_index :posts, :golive_at
    add_index :posts, :expire_at
  end

  def self.down
    drop_index :posts, :golive_at
    drop_index :posts, :expire_at
    remove_column :posts, :golive_at
    remove_column :posts, :expire_at
  end
end

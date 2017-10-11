class AddCredentialsToStockLocations < ActiveRecord::Migration[4.2]
  def change
    add_column :spree_stock_locations, :fedex_account, :string
    add_column :spree_stock_locations, :fedex_password, :string
    add_column :spree_stock_locations, :fedex_key, :string
    add_column :spree_stock_locations, :fedex_login, :string
    add_column :spree_stock_locations, :fedex_freight_account, :string
  end
end

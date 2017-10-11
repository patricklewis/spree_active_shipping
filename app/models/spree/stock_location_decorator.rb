Spree::StockLocation.class_eval do
  validates_presence_of :address1, :city, :zipcode, :country_id
  validate :state_id_or_state_name_is_present

  def state_id_or_state_name_is_present
    if state_id.nil? && state_name.nil?
      errors.add(:state_name, "can't be blank")
    end
  end

  def stock_fedex_credentials_present?
    respond_to?(:fedex_account) &&
    respond_to?(:fedex_password) &&
    respond_to?(:fedex_key) &&
    respond_to?(:fedex_login)
  end
end

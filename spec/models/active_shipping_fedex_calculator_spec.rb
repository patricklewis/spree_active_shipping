require 'spec_helper'
include ActiveShipping

module ActiveShipping
  describe Spree::Calculator::Shipping do
    WebMock.disable_net_connect!
    # NOTE: All specs will use the bogus calculator (no login information needed)

    let(:address) { FactoryGirl.create(:address) }
    let(:bill_address) { FactoryGirl.create(:bill_address, state_name: 'NY', state_id: nil) }
    let(:stock_location) { FactoryGirl.create(:stock_location) }
    let!(:order) do
      order = FactoryGirl.create(:order_with_line_items, ship_address: address, bill_address: bill_address, line_items_count: 2)
      order.line_items.first.tap do |line_item|
        line_item.quantity = 2
        line_item.variant.save
        line_item.variant.weight = 1
        line_item.variant.save
        line_item.save
        # product packages?
      end
      order.line_items.last.tap do |line_item|
        line_item.quantity = 2
        line_item.variant.save
        line_item.variant.weight = 2
        line_item.variant.save
        line_item.save
        # product packages?
      end
      order
    end

    let(:carrier) {
      ActiveShipping::FedEx.new(login: '100340239',
                                account: '510087100',
                                key: 'Ca0Mcv6fqqKdDINs',
                                password: 'OdVTOB3GOR5x4wFEc9fKZlooQ',
                                test: true
      )
    }

    let(:calculator) { Spree::Calculator::Shipping::Fedex::FreightEconomy.new }
    let(:package) { order.shipments.first.to_package }

    before(:each) do
      Rails.cache.clear
      Spree::StockLocation.destroy_all
      stock_location
      order.create_proposed_shipments
      expect(order.shipments.count).to eq(1)
      Spree::ActiveShipping::Config.set(fedex_freight_account: '510087100')
      Spree::ActiveShipping::Config.set(test_mode: true)
      Spree::ActiveShipping::Config.set(units: "imperial")
      Spree::ActiveShipping::Config.set(unit_multiplier: 1)
      allow(calculator).to receive(:carrier).and_return(carrier)
      Rails.cache.clear
    end

    describe 'calculator' do
      it 'carrier is FreightEconomy' do
        expect(calculator.carrier).to be(carrier)
      end

    end


    describe "compute" do
      context 'base Fedex' do
        it "freight Fedex" do
          stub_request(:post, /https:\/\/gatewaybeta.fedex.com\/xml.*/).
              to_return(:body => fixture(:freight_fedex_response))
          expect(calculator.class).to receive(:description).and_return("FedEx Freight Economy")
          expect(calculator.compute(package)).to eq(357.29)
        end
      end

      context 'base Fedex' do
        let(:calculator) { Spree::Calculator::Shipping::Fedex::GroundHomeDelivery.new }
        it "should return base FedEx Ground Home Delivery" do
          stub_request(:post, /https:\/\/gatewaybeta.fedex.com\/xml.*/).
              to_return(:body => fixture(:base_fedex_response))
          expect(calculator.class).to receive(:description).and_return("FedEx Ground Home Delivery")
          rate = calculator.compute(package)
          expect(rate).to eq(12.43)
        end
      end


      describe "service_name" do
        it "should return description when not defined" do
          expect(calculator.class.service_name).to eq(calculator.description)
        end
      end
    end
end

end

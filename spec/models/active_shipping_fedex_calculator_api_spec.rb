require 'spec_helper'
include ActiveShipping

module ActiveShipping
  describe Spree::Calculator::Shipping do
    WebMock.allow_net_connect!
    # NOTE: All specs will use the bogus calculator (no login information needed)

    let(:address) { FactoryGirl.create(:address) }
    let(:stock_location) { FactoryGirl.create(:stock_location) }
    let!(:order) do
      order = FactoryGirl.create(:order_with_line_items, :ship_address => address, :line_items_count => 2)
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
      # Spree::ActiveShipping::Config.set(fedex_freight_account: '510087100')
      Spree::ActiveShipping::Config.set(test_mode: true)
      Spree::ActiveShipping::Config.set(units: "imperial")
      Spree::ActiveShipping::Config.set(unit_multiplier: 1)
      allow(calculator).to receive(:carrier).and_return(carrier)
      Rails.cache.clear
    end

    describe "compute" do


      context "with valid response" do
        before do
          expect(carrier).to receive(:carrier).and_return(carrier)
        end

        it "should return rate based on calculator's service_name" do
          expect(calculator.class).to receive(:description).and_return("FedEx Freight Economy")
          rate = calculator.compute(package)
          expect(rate).to be_nil
        end

        it "should include handling_fee when configured" do
          expect(calculator.class).to receive(:description).and_return("FedEx Freight Economy")
          Spree::ActiveShipping::Config.set(:handling_fee => 100)
          rate = calculator.compute(package)
          expect(rate).to be_nil
        end

        it "should return nil if service_name is not found in rate_hash" do
          expect(calculator.class).to receive(:description).and_return("FedEx Freight Economy")
          rate = calculator.compute(package)
          expect(rate).to be_nil
        end
      end
    end

    describe "service_name" do
      it "should return description when not defined" do
        expect(calculator.class.service_name).to eq(calculator.description)
      end
    end
end

end

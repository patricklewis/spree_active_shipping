require 'spec_helper'
include ActiveShipping

module ActiveShipping
  describe Spree::Calculator::Shipping do
    WebMock.disable_net_connect!
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
                                test_mode: true
      )
    }

    let(:calculator) { Spree::Calculator::Shipping::Fedex::FreightEconomy.new }
    let(:package) { order.shipments.first.to_package }

    before(:each) do
      Spree::StockLocation.destroy_all
      stock_location
      order.create_proposed_shipments
      expect(order.shipments.count).to eq(1)
      Spree::ActiveShipping::Config.set(fedex_freight_account: '510087100')
      Spree::ActiveShipping::Config.set(units: "imperial")
      Spree::ActiveShipping::Config.set(unit_multiplier: 1)
      allow(calculator).to receive(:carrier).and_return(carrier)
      Rails.cache.clear
    end


    describe "available" do
      context "when rates are available" do

        before do
          expect(carrier).not_to be_empty
        end

        it "should return true" do
          expect(calculator.available?(package)).to be(true)
        end

        it "should use zero as a valid weight for service" do
          allow(calculator).to receive(:max_weight_for_country).and_return(0)
          expect(calculator.available?(package)).to be(true)
        end
      end



    end


    describe "compute" do
      it "should use the carrier supplied in the initializer" do
        expect(calculator.compute(package)).not_to to_return(status: 200)
      end

      xit "should ignore variants that have a nil weight" do
        variant = order.line_items.first.variant
        variant.weight = nil
        variant.save
        calculator.compute(package)
      end

      xit "should create a package with the correct total weight in ounces" do
        # (10 * 2 + 5.25 * 1) * 16 = 404
        expect(Package).to receive(:new).with(404, [], :units => :imperial)
        calculator.compute(package)
      end

      xit "should check the cache first before finding rates" do
        Rails.cache.fetch(calculator.send(:cache_key, order)) { Hash.new }
        expect(carrier).not_to receive(:find_rates)
        calculator.compute(package)
      end

      context "with valid response" do
        before do
          expect(carrier).to receive(:find_rates).and_return(true)
        end

        xit "should return rate based on calculator's service_name" do
          expect(calculator.class).to receive(:description).and_return("Super Fast")
          rate = calculator.compute(package)
          expect(rate).to eq(9.99)
        end

        xit "should include handling_fee when configured" do
          expect(calculator.class).to receive(:description).and_return("Super Fast")
          Spree::ActiveShipping::Config.set(:handling_fee => 100)
          rate = calculator.compute(package)
          expect(rate).to eq(10.99)
        end

        xit "should return nil if service_name is not found in rate_hash" do
          expect(calculator.class).to receive(:description).and_return("Extra-Super Fast")
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

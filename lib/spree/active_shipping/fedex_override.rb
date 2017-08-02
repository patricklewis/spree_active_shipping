module Spree
  module ActiveShipping
    module FedexOverride
      def self.included(base)
        base.class_eval do
          def build_location_node(xml, name, location)
            xml.public_send(name) do
              xml.Address do
                xml.StreetLines(location.address1) if location.address1
                xml.StreetLines(location.address2) if location.address2
                xml.City(location.city) if location.city
                xml.StateOrProvinceCode(location.state) if location.state
                xml.PostalCode(location.postal_code)
                xml.CountryCode(location.country_code(:alpha2))
                xml.Residential(true) unless location.commercial?
              end
            end
          end
        end
      end
    end
  end
end
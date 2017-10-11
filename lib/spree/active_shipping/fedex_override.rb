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

          def find_rates(origin, destination, packages, options = {})
            options = @options.merge!(options)
            packages = Array(packages)

            rate_request = build_rate_request(origin, destination, packages, options)

            xml = commit(save_request(rate_request), (options[:test] || false))

            parse_rate_response(origin, destination, packages, xml, options)
          end

          def find_tracking_info(tracking_number, options = {})
            options = @options.merge!(options)

            tracking_request = build_tracking_request(tracking_number, options)
            xml = commit(save_request(tracking_request), (options[:test] || false))
            parse_tracking_response(xml, options)
          end


          # Get Shipping labels
          def create_shipment(origin, destination, packages, options = {})
            options = @options.merge!(options)
            packages = Array(packages)
            raise Error, "Multiple packages are not supported yet." if packages.length > 1

            request = build_shipment_request(origin, destination, packages, options)
            logger.debug(request) if logger

            response = commit(save_request(request), (options[:test] || false))
            parse_ship_response(response)
          end
        end
      end
    end
  end
end
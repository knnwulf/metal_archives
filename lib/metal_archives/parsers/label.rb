# frozen_string_literal: true

require 'date'
require 'nokogiri'

module MetalArchives
  module Parsers
    ##
    # Label parser
    #
    class Label # :nodoc:
      class << self
        def find_endpoint(params)
          "#{MetalArchives.config.default_endpoint}labels/#{params[:name]}/#{params[:id]}"
        end

        def parse(response)
          props = {}
          doc = Nokogiri::HTML(response)

          props[:name] = doc.css('#label_info .label_name').first.content

          props[:contact] = []
          doc.css('#label_contact a').each do |contact|
            props[:contact] << {
              :title => contact.content,
              :content => contact.attr(:href)
            }
          end

          doc.css('#label_info dl').each do |dl|
            dl.search('dt').each do |dt|
              content = sanitize(dt.next_element.content)

              next if content == 'N/A'

              case sanitize(dt.content)
              when 'Address:'
                props[:address] = content
              when 'Country:'
                props[:country] = ParserHelper.parse_country css('a').first.content
              when 'Phone number:'
                props[:phone] = content
              when 'Status:'
                props[:status] = content.downcase.tr(' ', '_').to_sym
              when 'Specialised in:'
                props[:specializations] = ParserHelper.parse_genre content
              when 'Founding date :'
                begin
                  dof = Date.parse content
                  props[:date_founded] = NilDate.new dof.year, dof.month, dof.day
                rescue ArgumentError => e
                  props[:date_founded] = NilDate.parse content
                end
              when 'Sub-labels:'
                # TODO
              when 'Online shopping:'
                if content == 'Yes'
                  props[:online_shopping] = true
                elsif content == 'No'
                  props[:online_shopping] = false
                end
              else
                raise "Unknown token: #{dt.content}"
              end
            end
          end

          props
        end
      end
    end
  end
end

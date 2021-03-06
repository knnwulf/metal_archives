# frozen_string_literal: true

require 'json'
require 'date'

module MetalArchives
  module Parsers
    ##
    # Release parser
    #
    class Release < Parser # :nodoc:
      class << self
        TYPE_TO_QUERY = {
          :full_length => 1,
          :live => 2,
          :demo => 3,
          :single => 4,
          :ep => 5,
          :video => 6,
          :boxed_set => 7,
          :split => 8,
          :compilation => 10,
          :split_video => 12,
          :collaboration => 13
        }.freeze

        TYPE_TO_SYM = {
          'Full-length' => :full_length,
          'Live album' => :live,
          'Demo' => :demo,
          'Single' => :single,
          'EP' => :ep,
          'Video' => :video,
          'Boxed set' => :boxed_set,
          'Split' => :split,
          'Compilation' => :compilation,
          'Split video' => :split_video,
          'Collaboration' => :collaboration
        }.freeze

        FORMAT_TO_QUERY = {
          :cd => 'CD',
          :cassette => 'Cassette',
          :vinyl => 'Vinyl*',
          :vhs => 'VHS',
          :dvd => 'DVD',
          :digital => 'Digital',
          :blu_ray => 'Blu-ray*',
          :other => 'Other',
          :unknown => 'Unknown'
        }.freeze

        FORMAT_TO_SYM = {
          'CD' => :cd,
          'Cassette' => :cassette,
          'VHS' => :vhs,
          'DVD' => :dvd,
          'Digital' => :digital,
          'Other' => :other,
          'Unknown' => :unknown
        }

        ##
        # Map attributes to MA attributes
        #
        # Returns +Hash+
        #
        # [+params+]
        #     +Hash+
        #
        def map_params(query)
          params = {
            :bandName => query[:band_name] || '',
            :releaseTitle => query[:title] || '',
            :releaseYearFrom => query[:from_year] || '',
            :releaseMonthFrom => query[:from_month] || '',
            :releaseYearTo => query[:to_year] || '',
            :releaseMonthTo => query[:to_month] || '',
            :country => map_countries(query[:country]) || '',
            :location => query[:location] || '',
            :releaseLabelName => query[:label_name] || '',
            :releaseCatalogNumber => query[:catalog_id] || '',
            :releaseIdentifiers => query[:identifier] || '',
            :releaseRecordingInfo => query[:recording_info] || '',
            :releaseDescription => query[:version_description] || '',
            :releaseNotes => query[:notes] || '',
            :genre => query[:genre] || '',
            :releaseType => map_types(query[:types]),
            :releaseFormat => map_formats(query[:formats])
          }

          params
        end

        ##
        # Parse main HTML page
        #
        # Returns +Hash+
        #
        # [Raises]
        # - rdoc-ref:MetalArchives::Errors::ParserError when parsing failed. Please report this error.
        #
        def parse_html(response)
          props = {}
          doc = Nokogiri::HTML response

          props[:title] = sanitize doc.css('#album_info .album_name a').first.content

          doc.css('#album_info dl').each do |dl|
            dl.search('dt').each do |dt|
              content = sanitize dt.next_element.content

              next if content == 'N/A'

              case sanitize(dt.content)
              when 'Type:'
                props[:type] = map_type content
              when 'Release date:'
                begin
                  props[:date_released] = NilDate.parse content
                rescue MetalArchives::Errors::ArgumentError => e
                  dr = Date.parse content
                  props[:date_released] = NilDate.new dr.year, dr.month, dr.day
                end
              when 'Catalog ID:'
                props[:catalog_id] = content
              when 'Identifier:'
                props[:identifier] = content
              when 'Version desc.:'
                props[:version_description] = content
              when 'Label:'
                # TODO: label
              when 'Format:'
                props[:format] = map_format content
              when 'Limitation:'
                props[:limitation] = content.to_i
              when 'Reviews:'
                next if content == 'None yet'
                # TODO: reviews
              else
                raise MetalArchives::Errors::ParserError, "Unknown token: #{dt.content}"
              end
            end
          end

          props
        rescue => e
          e.backtrace.each { |b| MetalArchives.config.logger.error b }
          raise Errors::ParserError, e
        end

        private

        ##
        # Map MA countries to query parameters
        #
        # Returns +Array+ of +ISO3166::Country+
        #
        # [+types+]
        #     +Array+ containing one or more +String+s
        #
        def map_countries(countries)
          countries && countries.map { |c| c.alpha2 }
        end

        ##
        # Map MA release type to query parameters
        #
        # Returns +Array+ of +Integer+
        #
        # [+types+]
        #     +Array+ containing one or more +Symbol+, see rdoc-ref:Release.type
        #
        def map_types(type_syms)
          return unless type_syms

          types = []
          type_syms.each do |type|
            raise MetalArchives::Errors::ParserError, "Unknown type: #{type}" unless TYPE_TO_QUERY[type]

            types << TYPE_TO_QUERY[type]
          end

          types
        end

        ##
        # Map MA release type to +Symbol+
        #
        # Returns +Symbol+, see rdoc-ref:Release.type
        #
        def map_type(type)
          raise MetalArchives::Errors::ParserError, "Unknown type: #{type}" unless TYPE_TO_SYM[type]

          TYPE_TO_SYM[type]
        end

        ##
        # Map MA release format to query parameters
        #
        # Returns +Array+ of +Integer+
        #
        # [+types+]
        #     +Array+ containing one or more +Symbol+, see rdoc-ref:Release.type
        #
        def map_formats(format_syms)
          return unless format_syms

          formats = []
          format_syms.each do |format|
            raise MetalArchives::Errors::ParserError, "Unknown format: #{format}" unless FORMAT_TO_QUERY[format]

            formats << FORMAT_TO_QUERY[format]
          end

          formats
        end

        ##
        # Map MA release format to +Symbol+
        #
        # Returns +Symbol+, see rdoc-ref:Release.format
        #
        def map_format(format)
          return :cd if format =~ /CD/
          return :vinyl if format =~ /[Vv]inyl/
          return :blu_ray if format =~ /[Bb]lu.?[Rr]ay/

          raise MetalArchives::Errors::ParserError, "Unknown format: #{format}" unless FORMAT_TO_SYM[format]

          FORMAT_TO_SYM[format]
        end
      end
    end
  end
end

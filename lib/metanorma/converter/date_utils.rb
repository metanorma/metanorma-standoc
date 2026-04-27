require "date"

module Metanorma
  module Standoc
    module Utils
      # Convert dates to ISO format, complete partial dates, and return the latest
      def complete_and_compare_dates(dates)
        completed_dates = dates.map do |date_str|
          complete_iso_date(date_str)
        end.compact
        completed_dates.empty? and return nil
        completed_dates.max
      end

      # Complete partial ISO dates (non-inclusive cutoff: adds 1 day)
      # YYYY -> YYYY+1-01-01, YYYY-MM -> YYYY-MM+1-01, YYYY-MM-DD -> unchanged
      def complete_iso_date(date_str)
        date_str.is_a?(String) or return nil
        parse_partial_date(date_str.strip)
      end

      # Parse and complete partial date strings
      def parse_partial_date(date_str)
        complete_year_only(date_str) ||
          complete_year_month(date_str) ||
          parse_complete_date(date_str)
      end

      # Complete YYYY format to next year (non-inclusive cutoff)
      def complete_year_only(date_str)
        /^\d{4}$/.match?(date_str) or return nil
        Date.new(date_str.to_i, 12, 31) + 1
      end

      # Complete YYYY-MM format to first day of next month (non-inclusive cutoff)
      def complete_year_month(date_str)
        date_str =~ /^(\d{4})-(\d{1,2})$/ or return nil
        year = $1.to_i
        month = $2.to_i
        last_day = Date.new(year, month, -1).day
        Date.new(year, month, last_day) + 1
      end

      # Parse complete date or return nil
      def parse_complete_date(date_str)
        Date.parse(date_str)
      rescue ArgumentError
        nil
      end
    end
  end
end

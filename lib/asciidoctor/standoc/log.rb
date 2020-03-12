module Asciidoctor
  module Standoc
    class Log
      def initialize
        @log = {}
      end

      def add(category, loc, msg)
        @log[category] = [] unless @log[category]
        @log[category] << { location: current_location(loc), message: msg }
        loc = loc.nil? ? "" : "(#{current_location(loc)}): "
        warn "#{category}: #{loc}#{msg}"
      end

      def current_location(n)
        return "" if n.nil?
        return n if n.is_a? String
        return "Asciidoctor Line #{"%06d" % n.lineno}" if n.respond_to?(:lineno) &&
          !n.lineno.nil? && !n.lineno.empty?
        return "XML Line #{"%06d" % n.line}" if n.respond_to?(:line) &&
          !n.line.nil?
        return "ID #{n.id}" if n.respond_to?(:id) && !n.id.nil?
        while !n.nil? &&
            (!n.respond_to?(:level) || n.level.positive?) &&
            (!n.respond_to?(:context) || n.context != :section)
          n = n.parent
          return "Section: #{n.title}" if n&.respond_to?(:context) &&
            n&.context == :section
        end
        "??"
      end

      def write(file)
        File.open(file, "w:UTF-8") do |f|
          f.puts "#{file} errors"
          @log.keys.each do |key|
            f.puts "\n\n== #{key}\n\n"
            @log[key].sort do |a, b|
              a[:location] <=> b[:location]
            end.each do |n|
              loc = n[:location] ? "(#{n[:location]}): " : ""
              f.puts "#{loc}#{n[:message]}" 
            end
          end
        end
      end
    end
  end
end

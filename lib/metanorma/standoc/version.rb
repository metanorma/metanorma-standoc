module Metanorma
  class << self
    # https://stackoverflow.com/a/53399471
    def parent_of(mod)
      parent_name = mod.name =~ /::[^:]+\Z/ ? $`.freeze : nil
      Object.const_get(parent_name) if parent_name
    end

    def all_modules(mod)
      [mod] + mod.constants.map { |c| mod.const_get(c) }
        .select {|c| c.is_a?(Module) && parent_of(c) == mod }
        .flat_map {|m| all_modules(m) }
    end

    def versioned(mod, flavour)
      all_modules(mod).select {|c| defined? c::VERSION}.
        select {|c| c.name =~ /::#{flavour}$/ }
    end
  end

  module Standoc
    VERSION = "1.6.4".freeze
  end
end

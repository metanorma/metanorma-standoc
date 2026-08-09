# frozen_string_literal: true

module Metanorma
  module StandardDocument
    class Root < Metanorma::Document::Root
      attribute :autonum, :string
      attribute :fmt_xref_label, :string
    end
  end
end

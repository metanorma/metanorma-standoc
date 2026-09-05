# frozen_string_literal: true

module Metanorma
  module Standoc::Document
    class Root < Metanorma::Document::Root
      attribute :autonum, :string
      attribute :fmt_xref_label, :string
    end
  end
end

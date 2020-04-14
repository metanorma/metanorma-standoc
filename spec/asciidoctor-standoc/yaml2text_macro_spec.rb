require "spec_helper"

RSpec.describe Asciidoctor::Standoc::Yaml2TextPreprocessor do
  context 'yaml2text preprocess macro' do
    context 'Array of hashes' do
      let(:example_yaml_content) do
        <<~TEXT
        ---
        - name: spaghetti
          desc: wheat noodles of 9mm diameter
          symbol: SPAG
          symbol_def: the situation is message like spaghetti at a kid's meal
        TEXT
      end
      let(:example_file) { 'example.yml' }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [yaml2text,#{example_file},my_context]
          ----
          {my_context.*,item,EOF}
            {item.name}:: {item.desc}
          {EOF}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <dl id='_'>
            <dt>spaghetti</dt>
            <dd>
              <p id='_'>wheat noodles of 9mm diameter</p>
            </dd>
          </dl>
          </sections>
          </standard-document>
        TEXT
      end

      before do
        File.new(example_file, 'w').tap { |n| n.puts(example_yaml_content) }.close
      end

      after do
        FileUtils.rm_rf(example_file)
      end

      it 'reads the file' do
        expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to(be_equivalent_to xmlpp(output))
      end
    end

    context 'An array of strings' do
      let(:example_yaml_content) do
        <<~TEXT
        ---
        - lorem
        - ipsum
        - dolor
        TEXT
      end
      let(:example_file) { 'example.yml' }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [yaml2text,#{example_file},ar]
          ----
          {ar.*,s,EOS}
          === {s.#} {s}

          This section is about {s}.

          {EOS}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <clause id="_" inline-header="false" obligation="normative">
             <title>0 lorem</title>
             <p id='_'>This section is about lorem.</p>
           </clause>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>1 ipsum</title>
             <p id='_'>This section is about ipsum.</p>
           </clause>
           <clause id='_' inline-header='false' obligation='normative'>
             <title>2 dolor</title>
             <p id='_'>This section is about dolor.</p>
            </clause>
          </sections>
          </standard-document>
        TEXT
      end

      before do
        File.new(example_file, 'w').tap { |n| n.puts(example_yaml_content) }.close
      end

      after do
        FileUtils.rm_rf(example_file)
      end

      it 'reads the file' do
        expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to(be_equivalent_to xmlpp(output))
      end
    end

    context 'A simple hash' do
      let(:example_yaml_content) do
        <<~TEXT
        ---
        name: Lorem ipsum
        desc: dolor sit amet
        TEXT
      end
      let(:example_file) { 'example.yml' }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [yaml2text,#{example_file},my_item]
          ----
          === {my_item.name}

          {my_item.desc}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <clause id="_" inline-header="false" obligation="normative">
            <title>Lorem ipsum</title>
            <p id='_'>dolor sit amet</p>
          </clause>
          </sections>
          </standard-document>
        TEXT
      end

      before do
        File.new(example_file, 'w').tap { |n| n.puts(example_yaml_content) }.close
      end

      after do
        FileUtils.rm_rf(example_file)
      end

      it 'reads the file' do
        expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to(be_equivalent_to xmlpp(output))
      end
    end

    context 'A simple hash with free keys' do
      let(:example_yaml_content) do
        <<~TEXT
        ---
        name: Lorem ipsum
        desc: dolor sit amet
        TEXT
      end
      let(:example_file) { 'example.yml' }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [yaml2text,#{example_file},my_item]
          ----
          {my_item.*,key,EOI}
          === {key}

          {my_item[key]}

          {EOI}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <clause id="_" inline-header="false" obligation="normative">
            <title>name</title>
              <p id='_'>Lorem ipsum</p>
            </clause>
            <clause id='_' inline-header='false' obligation='normative'>
              <title>desc</title>
          </clause>
          </sections>
          </standard-document>
        TEXT
      end

      before do
        File.new(example_file, 'w').tap { |n| n.puts(example_yaml_content) }.close
      end

      after do
        FileUtils.rm_rf(example_file)
      end

      it 'reads the file' do
        expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to(be_equivalent_to xmlpp(output))
      end
    end

    context 'An array of hashes' do
      let(:example_yaml_content) do
        <<~TEXT
        ---
        - name: Lorem
          desc: ipsum
          nums: [2]
        - name: dolor
          desc: sit
          nums: []
        - name: amet
          desc: lorem
          nums: [2, 4, 6]
        TEXT
      end
      let(:example_file) { 'example.yml' }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [yaml2text,array_of_hashes.yaml,ar]
          ----
          {ar.*,item,EOF}

          {item.name}:: {item.desc}

          {item.nums.*,num,EON}
          - {item.name}: {num}
          {EON}

          {EOF}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <clause id="_" inline-header="false" obligation="normative">
            <title>name</title>
              <p id='_'>Lorem ipsum</p>
            </clause>
            <clause id='_' inline-header='false' obligation='normative'>
              <title>desc</title>
          </clause>
          </sections>
          </standard-document>
        TEXT
      end

      before do
        File.new(example_file, 'w').tap { |n| n.puts(example_yaml_content) }.close
      end

      after do
        FileUtils.rm_rf(example_file)
      end

      it 'reads the file' do
        expect(xmlpp(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true)))).to(be_equivalent_to xmlpp(output))
      end
    end
  end
end
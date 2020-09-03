require 'spec_helper'

RSpec.describe Asciidoctor::Standoc::Yaml2TextPreprocessor do
  describe '#process' do
    let(:example_file) { 'example.yml' }

    before do
      if defined?(example_yaml_content)
        File.open(example_file, 'w') { |n| n.puts(example_yaml_content) }
      end
    end

    after do
      FileUtils.rm_rf(example_file)
    end

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

      it 'correctly renders input yaml' do
        expect(
          xmlpp(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(xmlpp(output)))
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

      it 'correctly renders input yaml' do
        expect(
          xmlpp(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(xmlpp(output)))
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

      it 'correctly renders input yaml' do
        expect(
          xmlpp(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(xmlpp(output)))
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
              <p id='_'>dolor sit amet</p>
          </clause>
          </sections>
          </standard-document>
        TEXT
      end

      it 'correctly renders input yaml' do
        expect(
          xmlpp(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(xmlpp(output)))
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
            <dl id='_'>
            <dt>Lorem</dt>
            <dd>
              <p id='_'>ipsum</p>
              <ul id='_'>
                <li>
                  <p id='_'>Lorem: 2</p>
                </li>
              </ul>
            </dd>
            <dt>dolor</dt>
            <dd>
              <p id='_'>sit</p>
            </dd>
            <dt>amet</dt>
            <dd>
              <p id='_'>lorem</p>
              <ul id='_'>
                <li>
                  <p id='_'>amet: 2</p>
                </li>
                <li>
                  <p id='_'>amet: 4</p>
                </li>
                <li>
                  <p id='_'>amet: 6</p>
                </li>
              </ul>
            </dd>
          </dl>
            </sections>
            </standard-document>
        TEXT
      end

      it 'correctly renders input yaml' do
        expect(
          xmlpp(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(xmlpp(output)))
      end
    end

    context "An array with interpolated file names, etc. \
              for Asciidoc's consumption" do
      let(:example_yaml_content) do
        <<~TEXT
          ---
          prefix: doc-
          items:
          - lorem
          - ipsum
          - dolor
        TEXT
      end
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [yaml2text,#{example_file},yaml]
          ------
          First item is {yaml.items[0]}.
          Last item is {yaml.items[-1]}.

          {yaml.items.*,s,EOS}
          === {s.#} -> {s.# + 1} {s} == {yaml.items[s.#]}

          [source,ruby]
          ----
          include::{yaml.prefix}{s.#}.rb[]
          ----

          {EOS}
          ------
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
            <preface>
              <foreword id='_' obligation='informative'>
                <title>Foreword</title>
                <p id='_'>First item is lorem. Last item is dolor.</p>
              </foreword>
            </preface>
            <sections>
              <clause id='_' inline-header='false' obligation='normative'>
                <title>0 → 1 lorem == lorem</title>
                <sourcecode lang='ruby' id='_'>link:doc-0.rb[]</sourcecode>
              </clause>
              <clause id='_' inline-header='false' obligation='normative'>
                <title>1 → 2 ipsum == ipsum</title>
                <sourcecode lang='ruby' id='_'>link:doc-1.rb[]</sourcecode>
              </clause>
              <clause id='_' inline-header='false' obligation='normative'>
                <title>2 → 3 dolor == dolor</title>
                <sourcecode lang='ruby' id='_'>link:doc-2.rb[]</sourcecode>
              </clause>
            </sections>
          </standard-document>
        TEXT
      end

      # TODO: fix frozen string error
      xit 'correctly renders input yaml' do
        expect(
          xmlpp(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(xmlpp(output)))
      end
    end

    context "Array of language codes" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [yaml2text,#{File.expand_path('../assets/codes.yml', __dir__)},ar]
          ----
          {ar.*,item,EOF}
          .{item.values[1]}
          [%noheader,cols="h,1"]
          |===
          {item.*,key,EOK}
          | {key} | {item[key]}

          {EOK}
          |===
          {EOF}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
            <sections>
              #{File.read(File.expand_path('../examples/codes_table.html', __dir__))}
            </sections>
          </standard-document>
        TEXT
      end

      it 'correctly renders input yaml' do
        expect(
          xmlpp(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(xmlpp(output)))
      end
    end

    context "Nested hash dot notation" do
      let(:example_yaml_content) do
        <<~TEXT
          data:
            acadsin-zho-hani-latn-2002:
              code: acadsin-zho-hani-latn-2002
              name:
                en: Academica Sinica -- Chinese Tongyong Pinyin (2002)
              authority: acadsin
              lang:
                system: iso-639-2
                code: zho
              source_script: Hani
              target_script: Latn
              system:
                id: '2002'
                specification: Academica Sinica -- Chinese Tongyong Pinyin (2002)
              notes: 'NOTE: OGC 11-122r1 code `zho_Hani2Latn_AcadSin_2002`'
        TEXT
      end
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [yaml2text,#{example_file},authorities]
          ----
          [cols="a,a,a,a",options="header"]
          |===
          | Script conversion system authority code | Name in English | Notes | Name en

          {authorities.data.*,key,EOI}
          | {key} | {authorities.data[key]['code']} | {authorities.data[key]['notes']} | {authorities.data[key].name.en}
          {EOI}

          |===
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
            <sections>
              <table id='_'>
                <thead>
                  <tr>
                    <th align='left'>Script conversion system authority code</th>
                    <th align='left'>Name in English</th>
                    <th align='left'>Notes</th>
                    <th align='left'>Name en</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td align='left'>
                      <p id='_'>acadsin-zho-hani-latn-2002</p>
                    </td>
                    <td align='left'>
                      <p id='_'>acadsin-zho-hani-latn-2002</p>
                    </td>
                    <td align='left'>
                      <note id='_'>
                        <p id='_'>
                          OGC 11-122r1 code
                          <tt>zho_Hani2Latn_AcadSin_2002</tt>
                        </p>
                      </note>
                    </td>
                    <td align='left'>
                      <p id='_'>Academica Sinica — Chinese Tongyong Pinyin (2002)</p>
                    </td>
                  </tr>
                </tbody>
              </table>
            </sections>
          </standard-document>
        TEXT
      end

      it 'correctly renders input yaml' do
        expect(
          xmlpp(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(xmlpp(output)))
      end
    end

    context 'Liquid code snippets' do
      let(:example_yaml_content) do
        <<~TEXT
          ---
          - name: One
            show: true
          - name: Two
            show: true
          - name: Three
            show: false
        TEXT
      end
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
          {% for item in my_context %}
          {% if item.show %}
          {{ item.name | upcase }}
          {{ item.name | size }}
          {% endif %}
          {% endfor %}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
            <p id='_'>ONE 3</p>
            <p id='_'>TWO 3</p>
          </sections>
          </standard-document>
        TEXT
      end

      it 'renders liquid markup' do
        expect(
          xmlpp(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(xmlpp(output)))
      end
    end
  end
end

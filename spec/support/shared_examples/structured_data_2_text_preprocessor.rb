RSpec.shared_examples "structured data 2 text preprocessor" do
  describe "#process" do
    let(:example_file) { "example.#{extention}" }

    before do
      File.open(example_file, "w") do |n|
        n.puts(transform_to_type(example_content))
      end
    end

    after do
      FileUtils.rm_rf(example_file)
    end

    context "Array of hashes" do
      let(:example_content) do
        [{ "name" => "spaghetti",
           "desc" => "wheat noodles of 9mm diameter",
           "symbol" => "SPAG",
           "symbol_def" =>
           "the situation is message like spaghetti at a kid's meal" }]
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

          [#{extention}2text,#{example_file},my_context]
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

      it "correctly renders input" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end

    context "An array of strings" do
      let(:example_content) do
        ["lorem", "ipsum", "dolor"]
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

          [#{extention}2text,#{example_file},ar]
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
          <clause id="_" anchor="_0_lorem" inline-header="false" obligation="normative">
             <title>0 lorem</title>
             <p id='_'>This section is about lorem.</p>
           </clause>
           <clause id="_" anchor="_1_ipsum" inline-header='false' obligation='normative'>
             <title>1 ipsum</title>
             <p id='_'>This section is about ipsum.</p>
           </clause>
           <clause id="_" anchor="_2_dolor" inline-header='false' obligation='normative'>
             <title>2 dolor</title>
             <p id='_'>This section is about dolor.</p>
            </clause>
          </sections>
          </standard-document>
        TEXT
      end

      it "correctly renders input" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end

    context "A simple hash" do
      let(:example_content) do
        { "name" => "Lorem ipsum", "desc" => "dolor sit amet" }
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

          [#{extention}2text,#{example_file},my_item]
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
          <clause id="_" anchor="_lorem_ipsum" inline-header="false" obligation="normative">
            <title>Lorem ipsum</title>
            <p id='_'>dolor sit amet</p>
          </clause>
          </sections>
          </standard-document>
        TEXT
      end

      it "correctly renders input" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end

    context "A simple hash with free keys" do
      let(:example_content) do
        { "name" => "Lorem ipsum", "desc" => "dolor sit amet" }
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

          [#{extention}2text,#{example_file},my_item]
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
          <clause id="_" anchor="_name" inline-header="false" obligation="normative">
              <title>name</title>
              <p id='_'>Lorem ipsum</p>
            </clause>
            <clause id="_" anchor="_desc" inline-header='false' obligation='normative'>
              <title>desc</title>
              <p id='_'>dolor sit amet</p>
          </clause>
          </sections>
          </standard-document>
        TEXT
      end

      it "correctly renders input" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end

    context "An array of hashes" do
      let(:example_content) do
        [{ "name" => "Lorem", "desc" => "ipsum", "nums" => [2] },
         { "name" => "dolor", "desc" => "sit", "nums" => [] },
         { "name" => "amet", "desc" => "lorem", "nums" => [2, 4, 6] }]
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

          [#{extention}2text,#{example_file},ar]
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

      it "correctly renders input" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end

    context "An array with interpolated file names, etc. \
              for Asciidoc's consumption" do
      let(:example_content) do
        { "prefix" => "doc-", "items" => ["lorem", "ipsum", "dolor"] }
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

          [#{extention}2text,#{example_file},#{extention}]
          ------
          First item is {#{extention}.items[0]}.
          Last item is {#{extention}.items[-1]}.

          {#{extention}.items.*,s,EOS}
          === {s.#} -> {s.# + 1} {s} == {#{extention}.items[s.#]}

          [source,ruby]
          ----
          include::{#{extention}.prefix}{s.#}.rb[]
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
              <clause id="_" anchor="_0_1_lorem_lorem" inline-header='false' obligation='normative'>
                <title>0 → 1 lorem == lorem</title>
                <sourcecode lang='ruby' id='_'><body>link:doc-0.rb[role=include]</body></sourcecode>
              </clause>
              <clause id="_" anchor="_1_2_ipsum_ipsum" inline-header='false' obligation='normative'>
                <title>1 → 2 ipsum == ipsum</title>
                <sourcecode lang='ruby' id='_'><body>link:doc-1.rb[role=include]</body></sourcecode>
              </clause>
              <clause id="_" anchor="_2_3_dolor_dolor" inline-header='false' obligation='normative'>
                <title>2 → 3 dolor == dolor</title>
                <sourcecode lang='ruby' id='_'><body>link:doc-2.rb[role=include]</body></sourcecode>
              </clause>
            </sections>
          </standard-document>
        TEXT
      end

      it "correctly renders input" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end

    context "Array of language codes" do
      let(:example_content) do
        YAML.safe_load(
          File.read(File.expand_path("../../assets/codes.yml", __dir__)),
        )
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

          [#{extention}2text,#{example_file},ar]
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
              #{File.read(File.expand_path('../../examples/codes_table.html', __dir__))}
            </sections>
          </standard-document>
        TEXT
      end

      it "correctly renders input" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end

    context "Nested hash dot notation" do
      let(:example_content) do
        { "data" =>
          { "acadsin-zho-hani-latn-2002" =>
            { "code" => "acadsin-zho-hani-latn-2002",
              "name" => {
                "en" => "Academica Sinica -- Chinese Tongyong Pinyin (2002)",
              },
              "authority" => "acadsin",
              "lang" => { "system" => "iso-639-2", "code" => "zho" },
              "source_script" => "Hani",
              "target_script" => "Latn",
              "system" =>
              { "id" => "2002",
                "specification" =>
                "Academica Sinica -- Chinese Tongyong Pinyin (2002)" },
              "notes" =>
              "NOTE: OGC 11-122r1 code `zho_Hani2Latn_AcadSin_2002`" } } }
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

          [#{extention}2text,#{example_file},authorities]
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
                    <th id="_" valign="top" align='left'>Script conversion system authority code</th>
                    <th id="_" valign="top" align='left'>Name in English</th>
                    <th id="_" valign="top" align='left'>Notes</th>
                    <th id="_" valign="top" align='left'>Name en</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td id="_" valign="top" align='left'>
                      <p id='_'>acadsin-zho-hani-latn-2002</p>
                    </td>
                    <td id="_" valign="top" align='left'>
                      <p id='_'>acadsin-zho-hani-latn-2002</p>
                    </td>
                    <td id="_" valign="top" align='left'>
                      <note id='_'>
                        <p id='_'>
                          OGC 11-122r1 code
                          <tt>zho_Hani2Latn_AcadSin_2002</tt>
                        </p>
                      </note>
                    </td>
                    <td id="_" valign="top" align='left'>
                      <p id='_'>Academica Sinica — Chinese Tongyong Pinyin (2002)</p>
                    </td>
                  </tr>
                </tbody>
              </table>
            </sections>
          </standard-document>
        TEXT
      end

      it "correctly renders input" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end

    context "Liquid code snippets" do
      let(:example_content) do
        [{ "name" => "One", "show" => true },
         { "name" => "Two", "show" => true },
         { "name" => "Three", "show" => false }]
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

          [#{extention}2text,#{example_file},my_context]
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

      it "renders liquid markup" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end

    context "Date time objects support" do
      let(:example_content) do
        {
          "date" => Date.parse("1889-09-28"),
          "time" => Time.gm(2020, 10, 15, 5, 34),
        }
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

          [#{extention}2text,#{example_file},my_context]
          ----
          {{my_context.time}}

          {{my_context.date}}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
            <p id='_'>1889-09-28</p>
            <p id='_'>2020-10-15 05:34:00 UTC</p>
          </sections>
          </standard-document>
        TEXT
      end

      it "renders liquid markup" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end

    context "Nested files support" do
      let(:example_content) do
        {
          "date" => Date.parse("1889-09-28"),
          "time" => Time.gm(2020, 10, 15, 5, 34),
        }
      end
      let(:parent_file) { "parent_file.#{extention}" }
      let(:parent_file_content) { [nested_file, nested_file_2] }
      let(:parent_file_2) { "parent_file_2.#{extention}" }
      let(:parent_file_2_content) { ["name", "description"] }
      let(:parent_file_3) { "parent_file_3.#{extention}" }
      let(:parent_file_3_content) { ["one", "two"] }
      let(:nested_file) { "nested_file.#{extention}" }
      let(:nested_file_content) do
        {
          "name" => "nested file-main",
          "description" => "nested description-main",
          "one" => "nested one-main",
          "two" => "nested two-main",
        }
      end
      let(:nested_file_2) { "nested_file_2.#{extention}" }
      let(:nested_file_2_content) do
        {
          "name" => "nested2 name-main",
          "description" => "nested2 description-main",
          "one" => "nested2 one-main",
          "two" => "nested2 two-main",
        }
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

          [#{extention}2text,#{parent_file},paths]
          ----
          {% for path in paths %}

          [#{extention}2text,#{parent_file_2},attribute_names]
          ---
          {% for name in attribute_names %}

          [#{extention}2text,{{ path }},data]
          --

          == {{ data[name] | split: "-" | last }}: {{ data[name] }}

          --

          {% endfor %}
          ---

          [#{extention}2text,#{parent_file_3},attribute_names]
          ---
          {% for name in attribute_names %}

          [#{extention}2text,{{ path }},data]
          --

          == {{ data[name] }}

          --

          {% endfor %}
          ---

          {% endfor %}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
            <clause id="_" anchor="_main_nested_file_main" inline-header='false' obligation='normative'>
              <title>main: nested file-main</title>
            </clause>
            <clause id="_" anchor="_main_nested_description_main" inline-header='false' obligation='normative'>
              <title>main: nested description-main</title>
            </clause>
            <clause id="_" anchor="_nested_one_main" inline-header='false' obligation='normative'>
              <title>nested one-main</title>
            </clause>
            <clause id="_" anchor="_nested_two_main" inline-header='false' obligation='normative'>
              <title>nested two-main</title>
            </clause>
            <clause id="_" anchor="_main_nested2_name_main" inline-header='false' obligation='normative'>
              <title>main: nested2 name-main</title>
            </clause>
            <clause id="_" anchor="_main_nested2_description_main" inline-header='false' obligation='normative'>
              <title>main: nested2 description-main</title>
            </clause>
            <clause id="_" anchor="_nested2_one_main" inline-header='false' obligation='normative'>
              <title>nested2 one-main</title>
            </clause>
            <clause id="_" anchor="_nested2_two_main" inline-header='false' obligation='normative'>
              <title>nested2 two-main</title>
            </clause>
          </sections>
          </standard-document>
        TEXT
      end
      let(:file_list) do
        {
          parent_file => parent_file_content,
          parent_file_2 => parent_file_2_content,
          parent_file_3 => parent_file_3_content,
          nested_file => nested_file_content,
          nested_file_2 => nested_file_2_content,
        }
      end

      before do
        file_list.each_pair do |file, content|
          File.open(file, "w") do |n|
            n.puts(transform_to_type(content))
          end
        end
      end

      after do
        file_list.keys.each do |file|
          FileUtils.rm_rf(file)
        end
      end

      it "renders liquid markup" do
        expect(
          Xml::C14n.format(
            strip_guid(
              Asciidoctor.convert(input,
                                  backend: :standoc,
                                  header_footer: true),
            ),
          ),
        ).to(be_equivalent_to(Xml::C14n.format(output)))
      end
    end
  end
end

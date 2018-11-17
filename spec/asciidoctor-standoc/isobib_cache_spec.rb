require "spec_helper"
require "isobib"
require "fileutils"

RSpec.describe Asciidoctor::Standoc do

  IETF_123_SHORT = <<~EOS
<bibitem type="international-standard" id="IETF123">
  <title format="text/plain" language="en" script="Latn">Rubber latex -- Sampling</title>
  <docidentifier type="IETF">RFC 123</docidentifier>
  <contributor>    <role type="publisher"/>    <organization>      <name>International Organization for Standardization</name>      <abbreviation>ISO</abbreviation>      <uri>www.iso.org</uri>    </organization>  </contributor>
  <status>Published</status>
</bibitem>
EOS

  ISO_123_SHORT = <<~EOS
<bibitem type="international-standard" id="ISO123">
  <title format="text/plain" language="en" script="Latn">Rubber latex -- Sampling</title>
  <docidentifier type="ISO">ISO 123</docidentifier>
  <contributor>    <role type="publisher"/>    <organization>      <name>International Organization for Standardization</name>      <abbreviation>ISO</abbreviation>      <uri>www.iso.org</uri>    </organization>  </contributor>
  <status>Published</status>
</bibitem>
EOS

  ISO_124_SHORT = <<~EOS
<bibitem type="international-standard" id="ISO124">
  <fetched>#{Date.today}</fetched>
  <title format="text/plain" language="en" script="Latn">Latex, rubber -- Determination of total solids content</title>
  <docidentifier type="ISO">ISO 124</docidentifier>
  <contributor>    <role type="publisher"/>    <organization>      <name>International Organization for Standardization</name>      <abbreviation>ISO</abbreviation>      <uri>www.iso.org</uri>    </organization>  </contributor>
  <status>Published</status>
</bibitem>
EOS

  ISO_124_SHORT_ALT = <<~EOS
<bibitem type="international-standard" id="ISO124">
  <fetched>#{Date.today}</fetched>
  <title format="text/plain" language="en" script="Latn">Latex, rubber -- Replacement</title>
  <docidentifier type="ISO">ISO 124</docidentifier>
  <contributor>    <role type="publisher"/>    <organization>      <name>International Organization for Standardization</name>      <abbreviation>ISO</abbreviation>      <uri>www.iso.org</uri>    </organization>  </contributor>
  <status><stage>60</stage><substage>60</substage></status>
</bibitem>
EOS

  ISO_123_DATED = <<~EOS
<bibitem type="international-standard" id="ISO123-2001"> <fetched>#{Date.today}</fetched> <title format="text/plain" language="en" script="Latn">Rubber latex -- Sampling</title>  <title format="text/plain" language="fr" script="Latn">Latex de caoutchouc -- Échantillonnage</title>  <uri type="src">https://www.iso.org/standard/23281.html</uri>  <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:23281:en</uri>  <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>  <docidentifier type="ISO">ISO 123:2001</docidentifier>  <date type="published">    <on>2001</on>  </date>  <contributor>    <role type="publisher"/>    <organization>      <name>International Organization for Standardization</name>      <abbreviation>ISO</abbreviation>      <uri>www.iso.org</uri>    </organization>  </contributor>  <edition>3</edition>  <language>en</language>  <language>fr</language>  <script>Latn</script>  <status><stage>90</stage><substage>93</substage></status>  <copyright>    <from>2001</from>    <owner>      <organization>        <name>ISO</name>        </organization>    </owner>  </copyright>  <relation type="obsoletes">    <bibitem>      <formattedref>ISO 123:1985</formattedref>      </bibitem>  </relation>  <relation type="updates">    <bibitem>      <formattedref>ISO 123:2001</formattedref> </bibitem>  </relation> <editorialgroup> <technical_committee number="45" type="TC">ISO/TC 45/SC 3Raw materials (including latex) for use in the rubber industry</technical_committee> </editorialgroup> <ics><code>83.040.10</code><text>Latex and raw rubber</text></ics> </bibitem>
EOS

  ISO_123_UNDATED = <<~EOS
<bibitem type="international-standard" id="ISO123"> <fetched>#{Date.today}</fetched>
  <title format="text/plain" language="en" script="Latn">Rubber latex -- Sampling</title> <title format="text/plain" language="fr" script="Latn">Latex de caoutchouc -- Échantillonnage</title>
  <uri type="src">https://www.iso.org/standard/23281.html</uri> <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:23281:en</uri> <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri>
  <docidentifier type="ISO">ISO 123</docidentifier>
  <contributor> <role type="publisher"/> <organization> <name>International Organization for Standardization</name> <abbreviation>ISO</abbreviation> <uri>www.iso.org</uri> </organization> </contributor>
  <edition>3</edition> <language>en</language> <language>fr</language> <script>Latn</script> <status><stage>90</stage><substage>93</substage></status>
  <copyright> <from>2001</from> <owner> <organization> <name>ISO</name> </organization> </owner> </copyright>
  <relation type="obsoletes"> <bibitem> <formattedref>ISO 123:1985</formattedref> </bibitem> </relation>
  <relation type="updates"> <bibitem> <formattedref>ISO 123:2001</formattedref> </bibitem> </relation>
  <relation type="instance"> <bibitem type="international-standard"> <fetched>#{Date.today}</fetched> <title format="text/plain" language="en" script="Latn">Rubber latex -- Sampling</title> <title format="text/plain" language="fr" script="Latn">Latex de caoutchouc -- Échantillonnage</title> <uri type="src">https://www.iso.org/standard/23281.html</uri> <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:23281:en</uri> <uri type="rss">https://www.iso.org/contents/data/standard/02/32/23281.detail.rss</uri> <docidentifier type="ISO">ISO 123:2001</docidentifier> <date type="published"> <on>2001</on> </date> <contributor> <role type="publisher"/> <organization> <name>International Organization for Standardization</name> <abbreviation>ISO</abbreviation> <uri>www.iso.org</uri> </organization> </contributor> <edition>3</edition> <language>en</language> <language>fr</language> <script>Latn</script> <status> <stage>90</stage> <substage>93</substage> </status> <copyright> <from>2001</from> <owner> <organization> <name>ISO</name> </organization> </owner> </copyright> <relation type="obsoletes"> <bibitem> <formattedref>ISO 123:1985</formattedref> </bibitem> </relation> <relation type="updates"> <bibitem> <formattedref>ISO 123:2001</formattedref> </bibitem> </relation> <editorialgroup> <technical_committee number="45" type="TC">ISO/TC 45/SC 3Raw materials (including latex) for use in the rubber industry</technical_committee> </editorialgroup> <ics> <code>83.040.10</code> <text>Latex and raw rubber</text> </ics> </bibitem> </relation>
  <editorialgroup><technical_committee number="45" type="TC">ISO/TC 45/SC 3Raw materials (including latex) for use in the rubber industry</technical_committee></editorialgroup>
  <ics><code>83.040.10</code><text>Latex and raw rubber</text></ics></bibitem>
EOS

  ISO_124_DATED = <<~EOS
<bibitem type="international-standard" id="ISO124-2014"> <fetched>#{Date.today}</fetched> <title format="text/plain" language="en" script="Latn">Latex, rubber -- Determination of total solids content</title>  <title format="text/plain" language="fr" script="Latn">Latex de caoutchouc -- Détermination des matières solides totales</title>  <uri type="src">https://www.iso.org/standard/61884.html</uri>  <uri type="obp">https://www.iso.org/obp/ui/#!iso:std:61884:en</uri>  <uri type="rss">https://www.iso.org/contents/data/standard/06/18/61884.detail.rss</uri>  <docidentifier type="ISO">ISO 124:2014</docidentifier>  <date type="published">    <on>2014</on>  </date>  <contributor>    <role type="publisher"/>    <organization>      <name>International Organization for Standardization</name>      <abbreviation>ISO</abbreviation>      <uri>www.iso.org</uri>    </organization>  </contributor>  <edition>7</edition>  <language>en</language>  <language>fr</language>  <script>Latn</script>  <abstract format="plain" language="en" script="Latn">ISO 124:2014 specifies methods for the determination of the total solids content of natural rubber field and concentrated latices and synthetic rubber latex. These methods are not necessarily suitable for latex from natural sources other than the Hevea brasiliensis, for vulcanized latex, for compounded latex, or for artificial dispersions of rubber.</abstract>  <abstract format="plain" language="fr" script="Latn">L'ISO 124:2014 spécifie des méthodes pour la détermination des matières solides totales dans le latex de plantation, le latex de concentré de caoutchouc naturel et le latex de caoutchouc synthétique. Ces méthodes ne conviennent pas nécessairement au latex d'origine naturelle autre que celui de l'Hevea brasiliensis, au latex vulcanisé, aux mélanges de latex, ou aux dispersions artificielles de caoutchouc.</abstract>  <status><stage>60</stage><substage>60</substage></status>  <copyright>    <from>2014</from>    <owner>      <organization>        <name>ISO</name>        </organization>    </owner>  </copyright>  <relation type="obsoletes">    <bibitem>      <formattedref>ISO 124:2011</formattedref>      </bibitem>  </relation><editorialgroup><technical_committee number="45" type="TC">ISO/TC 45/SC 3Raw materials (including latex) for use in the rubber industry</technical_committee></editorialgroup><ics><code>83.040.10</code><text>Latex and raw rubber</text></ics></bibitem>
EOS

  it "does not activate biblio caches if isobib disabled" do
    FileUtils.rm_rf File.expand_path("~/.relaton-bib.pstore1")
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true
    FileUtils.rm_rf File.expand_path("~/.iev.pstore1")
    FileUtils.mv File.expand_path("~/.iev.pstore"), File.expand_path("~/.iev.pstore1"), force: true
    FileUtils.rm_rf "relaton/cache"
    FileUtils.rm_rf "test.iev.pstore"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:2001]]] _Standard_
    INPUT
    expect(File.exist?("#{Dir.home}/.relaton/cache")).to be false
    expect(File.exist?("#{Dir.home}/.iev.pstore")).to be false
    expect(File.exist?("relaton/cache")).to be false
    expect(File.exist?("test.iev.pstore")).to be false

    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
    FileUtils.rm_rf File.expand_path("~/.iev.pstore")
    FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev.pstore"), force: true
  end

  it "does not activate biblio caches if isobib caching disabled" do
    FileUtils.rm_rf File.expand_path("~/.relaton-bib.pstore1")
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true
    FileUtils.rm_rf File.expand_path("~/.iev.pstore1")
    FileUtils.mv File.expand_path("~/.iev.pstore"), File.expand_path("~/.iev.pstore1"), force: true
    FileUtils.rm_rf "relaton/cache"
    FileUtils.rm_rf "test.iev.pstore"
    mock_isobib_get_123
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      #{ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:2001]]] _Standard_
    INPUT
    expect(File.exist?("#{Dir.home}/.relaton/cache")).to be false
    expect(File.exist?("#{Dir.home}/.iev.pstore")).to be false
    expect(File.exist?("relaton/cache")).to be false
    expect(File.exist?("test.iev.pstore")).to be false

    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.rm_rf File.expand_path("~/.iev.pstore")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
    FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev.pstore"), force: true
  end

  it "flushes biblio caches" do
    relaton_bib_file  = File.expand_path("~/.relaton/cache")
    relaton_bib_file1 = File.expand_path("~/.relaton-bib.pstore1")
    iev_file          = File.expand_path("~/.iev.pstore")
    iev_file1         = File.expand_path("~/.iev.pstore1")
    FileUtils.rm_rf relaton_bib_file1 if File.exist? relaton_bib_file1
    FileUtils.mv relaton_bib_file, relaton_bib_file1 if File.exist? relaton_bib_file
    FileUtils.rm_rf iev_file1 if File.exist? iev_file1
    FileUtils.mv iev_file, iev_file1 if File.exist? iev_file

    File.open("#{Dir.home}/.relaton/cache", "w") { |f| f.write "XXX" }
    FileUtils.rm_rf File.expand_path("~/.iev.pstore")

    # mock_isobib_get_123
    VCR.use_cassette "isobib_get_123" do
      Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
        #{FLUSH_CACHE_ISOBIB_BLANK_HDR}
        [bibliography]
        == Normative References

        * [[[iso123,ISO 123:2001]]] _Standard_
      INPUT
    end
    expect(File.exist?("#{Dir.home}/.relaton/cache")).to be true
    expect(File.exist?("#{Dir.home}/.iev.pstore")).to be true

    db = Relaton::Db.new "#{Dir.home}/.relaton/cache", nil
    entry = db.load_entry("ISO(ISO 123:2001)")
    expect(db.fetched("ISO(ISO 123:2001)")).to eq(Date.today.to_s)
    expect(entry).to be_equivalent_to(ISO_123_DATED)

    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.rm_rf File.expand_path("~/.iev.pstore")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
    FileUtils.mv File.expand_path("~/.iev.pstore1"), File.expand_path("~/.iev.pstore"), force: true
  end

  it "does not fetch references for ISO references in preparation" do
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true
    FileUtils.rm_f "relaton/cache"
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      #{CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:--]]] footnote:[The standard is in press] _Standard_
    INPUT
    expect(File.exist?("#{Dir.home}/.relaton/cache")).to be true
    db = Relaton::Db.new "#{Dir.home}/.relaton/cache", nil
    entry = db.load_entry("ISO(ISO 123:--)")
    expect(entry).to be nil

    FileUtils.rm_f File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
  end

  it "inserts prefixes to fetched reference identifiers other than ISO IEC" do
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true
    FileUtils.rm_f "relaton/cache"
    mock_isobib_get_123
    mock_ietfbib_get_123
    out = Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      #{CACHED_ISOBIB_BLANK_HDR}
      
      <<iso123>>
      <<ietf123>>

      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:2001]]] _Standard_
      * [[[ietf123,RFC 123]]] _Standard_
    INPUT
      expect(out).to include '<eref type="inline" bibitemid="iso123" citeas="ISO 123:2001"/>'
      expect(out).to include '<eref type="inline" bibitemid="ietf123" citeas="IETF RFC 123"/>'
  end

  it "activates global cache" do
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true
    FileUtils.rm_f "relaton/cache"
    mock_isobib_get_123
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      #{CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:2001]]] _Standard_
    INPUT
    expect(File.exist?("#{Dir.home}/.relaton/cache")).to be true
    expect(File.exist?("relaton/cache")).to be false

    db = Relaton::Db.new "#{Dir.home}/.relaton/cache", nil
    entry = db.load_entry("ISO(ISO 123:2001)")
    expect(entry).to_not be nil

    FileUtils.rm_f File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
  end

  it "activates local cache" do
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true
    FileUtils.rm_f "relaton/cache"
    mock_isobib_get_123
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      #{LOCAL_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:2001]]] _Standard_
    INPUT
    expect(File.exist?("#{Dir.home}/.relaton/cache")).to be true
    expect(File.exist?("relaton/cache")).to be true

    db = Relaton::Db.new "#{Dir.home}/.relaton/cache", nil
    entry = db.load_entry("ISO(ISO 123:2001)")
    expect(entry).to_not be nil

    db = Relaton::Db.new "relaton/cache", nil
    entry = db.load_entry("ISO(ISO 123:2001)")
    expect(entry).to_not be nil

    FileUtils.rm_f File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
  end

  it "activates only local cache" do
    relaton_bib_file  = File.expand_path("~/.relaton/cache")
    relaton_bib_file1 = File.expand_path("~/.relaton-bib.pstore1")
    FileUtils.rm_rf relaton_bib_file1 if File.exist? relaton_bib_file1
    FileUtils.mv(relaton_bib_file, relaton_bib_file1, force: true) if File.exist? relaton_bib_file
    FileUtils.rm_rf "relaton/cache"
    mock_isobib_get_123
    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      #{LOCAL_ONLY_CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:2001]]] _Standard_
    INPUT
    expect(File.exist?("#{Dir.home}/.relaton/cache")).to be false
    expect(File.exist?("relaton/cache")).to be true

    db = Relaton::Db.new "relaton/cache", nil
    entry = db.load_entry("ISO(ISO 123:2001)")
    expect(entry).to_not be nil

    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
  end

  it "fetches uncached references" do
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true
    db = Relaton::Db.new "#{Dir.home}/.relaton/cache", nil
    db.save_entry("ISO(ISO 123:2001)",
        {
          "fetched" => Date.today.to_s,
          "bib" => IsoBibItem::XMLParser.from_xml(ISO_123_DATED)
        }
      )

    # mock_isobib_get_124
    VCR.use_cassette "isobib_get_124" do
      Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
        #{CACHED_ISOBIB_BLANK_HDR}
        [bibliography]
        == Normative References

        * [[[iso123,ISO 123:2001]]] _Standard_
        * [[[iso124,ISO 124:2014]]] _Standard_
      INPUT
    end

    entry = db.load_entry("ISO(ISO 123:2001)")
    expect(db.fetched("ISO(ISO 123:2001)")).to eq(Date.today.to_s)
    expect(entry).to be_equivalent_to(ISO_123_DATED)
    entry = db.load_entry("ISO(ISO 124:2014)")
    expect(db.fetched("ISO(ISO 124:2014)")).to eq(Date.today.to_s)
    expect(entry).to be_equivalent_to(ISO_124_DATED)

    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
  end

  it "expires stale undated references" do
    FileUtils.rm_rf File.expand_path("~/.relaton-bib.pstore1")
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true

        db = Relaton::Db.new "#{Dir.home}/.relaton/cache", nil
        db.save_entry("ISO 123",
        {
          "fetched" => (Date.today - 90),
          "bib" => IsoBibItem::XMLParser.from_xml(ISO_123_SHORT)
        }
      )

    # mock_isobib_get_123_undated
    VCR.use_cassette "isobib_get_123" do
      Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
        #{CACHED_ISOBIB_BLANK_HDR}
        [bibliography]
        == Normative References

        * [[[iso123,ISO 123]]] _Standard_
      INPUT
    end

    entry = db.load_entry("ISO(ISO 123)")
    expect(db.fetched("ISO(ISO 123)")).to eq(Date.today.to_s)
    expect(entry).to be_equivalent_to(ISO_123_UNDATED)

    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
  end

  it "does not expire stale dated references" do
    FileUtils.rm_rf File.expand_path("~/.relaton-bib.pstore1")
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true

    bibitem = IsoBibItem::XMLParser.from_xml ISO_123_DATED
    bibitem.instance_variable_set :@fetched, (Date.today - 90)

    db = Relaton::Db.new "#{Dir.home}/.relaton/cache", nil
    db.save_entry("ISO(ISO 123:2001)", bibitem.to_xml)
    #   {
    #     "fetched" => (Date.today - 90),
    #     "bib" => IsoBibItem::XMLParser.from_xml(ISO_123_DATED)
    #   }
    # )

    Asciidoctor.convert(<<~"INPUT", backend: :standoc, header_footer: true)
      #{CACHED_ISOBIB_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[iso123,ISO 123:2001]]] _Standard_
    INPUT

    entry = db.load_entry("ISO(ISO 123:2001)")
    expect(db.fetched("ISO(ISO 123:2001)")).to eq((Date.today - 90).to_s)
    # expect(entry).to be_equivalent_to(ISO_123_DATED) It can't be true since fetched date is changed

    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
  end

  it "prioritises local over global cache values" do
    FileUtils.rm_rf File.expand_path("~/.relaton-bib.pstore1")
    FileUtils.mv File.expand_path("~/.relaton/cache"), File.expand_path("~/.relaton-bib.pstore1"), force: true
    FileUtils.rm_rf "relaton/cache"

    db = Relaton::Db.new "#{Dir.home}/.relaton/cache", nil
    db.save_entry("ISO(ISO 123:2001)", IsoBibItem::XMLParser.from_xml(ISO_123_DATED).to_xml)
      #   {
      #     "fetched" => Date.today,
      #     "bib" => IsoBibItem::XMLParser.from_xml(ISO_123_DATED)
      #   }
      # )
    db.save_entry("ISO(ISO 124)", IsoBibItem::XMLParser.from_xml(ISO_124_SHORT).to_xml)
      #   {
      #     "fetched" => Date.today,
      #     "bib" => IsoBibItem::XMLParser.from_xml(ISO_124_SHORT)
      #   }
      # )

    localdb = Relaton::Db.new "relaton/cache", nil
    localdb.save_entry("ISO(ISO 124)", IsoBibItem::XMLParser.from_xml(ISO_124_SHORT_ALT).to_xml)
      #   {
      #     "fetched" => Date.today,
      #     "bib" => IsoBibItem::XMLParser.from_xml(ISO_124_SHORT_ALT)
      #   }
      # )

    input = <<~EOS
#{LOCAL_CACHED_ISOBIB_BLANK_HDR}
[bibliography]
== Normative References

* [[[ISO123-2001,ISO 123:2001]]] _Standard_
* [[[ISO124,ISO 124]]] _Standard_
EOS

    output = <<~EOS
#{BLANK_HDR}
<sections>
</sections>
<bibliography>
<references id="_" obligation="informative">
 <title>Normative References</title>
 #{ISO_123_DATED}
 #{ISO_124_SHORT_ALT}
</references></bibliography>
</standard-document>
EOS

    #expect(strip_guid(Asciidoctor.convert(input, backend: :standoc, header_footer: true))).to be_equivalent_to(output)
    Asciidoctor.convert(input, backend: :standoc, header_footer: true)

    expect(db.load_entry("ISO(ISO 123:2001)")).to be_equivalent_to(ISO_123_DATED)
    expect(db.load_entry("ISO(ISO 124)")).to be_equivalent_to(ISO_124_SHORT)
    expect(localdb.load_entry("ISO(ISO 123:2001)")).to be_equivalent_to(ISO_123_DATED)
    expect(localdb.load_entry("ISO(ISO 124)")).to be_equivalent_to(ISO_124_SHORT_ALT)

    FileUtils.rm_rf File.expand_path("~/.relaton/cache")
    FileUtils.mv File.expand_path("~/.relaton-bib.pstore1"), File.expand_path("~/.relaton/cache"), force: true
  end

private

  def mock_isobib_get_123
    expect(Isobib::IsoBibliography).to receive(:get).with("ISO 123", "2001", {}).and_return(IsoBibItem::XMLParser.from_xml(ISO_123_DATED))
  end

  def mock_isobib_get_123_undated
    expect(Isobib::IsoBibliography).to receive(:get).with("ISO 123", nil, {}).and_return(IsoBibItem::XMLParser.from_xml(ISO_123_UNDATED))
  end

  def mock_isobib_get_124
    expect(Isobib::IsoBibliography).to receive(:get).with("ISO 124", "2014", {}).and_return(IsoBibItem::XMLParser.from_xml(ISO_124_DATED))
  end

  def mock_ietfbib_get_123
    expect(IETFBib::RfcBibliography).to receive(:get).with("RFC 123", nil, {}).and_return(IsoBibItem::XMLParser.from_xml(IETF_123_SHORT))
  end

end

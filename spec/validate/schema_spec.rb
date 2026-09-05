require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Standoc do
  describe "Jing invocation" do
    it "passes JVM properties via java_opts without mutating _JAVA_OPTIONS" do
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Clause
        Para
      INPUT

      captured_opts = nil
      env_at_call = :not_called
      allow(Jing).to receive(:new) do |schema, opts = nil|
        captured_opts = opts
        env_at_call = ENV["_JAVA_OPTIONS"]
        jing = Jing.allocate
        allow(jing).to receive(:validate) { [] }
        jing
      end

      Asciidoctor.convert(input, *OPTIONS)

      expect(env_at_call).to be_nil
      expect(captured_opts[:java_opts]).to include("-Dfile.encoding=UTF-8")
      expect(captured_opts[:java_opts]).to include("-Dsun.jnu.encoding=UTF-8")
      expect(captured_opts[:java_opts])
        .to include("-Djdk.xml.maxGeneralEntitySizeLimit=")
      expect(captured_opts[:java_opts])
        .to include("-Djdk.xml.totalEntitySizeLimit=")
    end

    it "honors METANORMA_JING_JAVA_OPTS override" do
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Clause
        Para
      INPUT

      captured_opts = nil
      allow(Jing).to receive(:new) do |schema, opts = nil|
        captured_opts = opts
        jing = Jing.allocate
        allow(jing).to receive(:validate) { [] }
        jing
      end

      old_override = ENV["METANORMA_JING_JAVA_OPTS"]
      ENV["METANORMA_JING_JAVA_OPTS"] = "-Xmx2g"
      begin
        Asciidoctor.convert(input, *OPTIONS)
      ensure
        ENV["METANORMA_JING_JAVA_OPTS"] = old_override
      end

      expect(captured_opts[:java_opts]).to eq("-Xmx2g")
    end
  end

  describe "schema validation with retry" do
    it "retries on 'Too many open files' error and succeeds" do
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Clause
        Para
      INPUT

      # Mock Jing to fail once then succeed
      call_count = 0
      allow_any_instance_of(Jing).to receive(:validate) do
        call_count += 1
        if call_count == 1
          raise Jing::ExecutionError.new("jing execution failed: Too many open files - 'java'")
        else
          [] # Success on second attempt
        end
      end

      # Capture warnings to verify retry happened
      expect do
        Asciidoctor.convert(input, *OPTIONS)
      end.to output(/Retrying.*attempt 1\/3.*after 0\.1s delay/).to_stderr

      expect(call_count).to eq(2)
    end

    it "retries multiple times on 'Too many open files' error" do
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Clause
        Para
      INPUT

      # Mock Jing to fail 3 times then succeed
      call_count = 0
      allow_any_instance_of(Jing).to receive(:validate) do
        call_count += 1
        if call_count <= 3
          raise Jing::ExecutionError.new("jing execution failed: Too many open files - 'java'")
        else
          [] # Success on 4th attempt
        end
      end

      # Verify retry with exponential backoff occurs
      Asciidoctor.convert(input, *OPTIONS)

      # Should have tried 4 times total (initial + 3 retries)
      expect(call_count).to eq(4)
    end

    it "does not retry on non-file-descriptor errors" do
      input = <<~INPUT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:

        == Clause
        Para
      INPUT

      # Mock Jing with a different error
      call_count = 0
      allow_any_instance_of(Jing).to receive(:validate) do
        call_count += 1
        raise Jing::ExecutionError.new("jing execution failed: Some other error")
      end

      begin
        expect do
          Asciidoctor.convert(input, *OPTIONS)
        end.to raise_error(SystemExit)
      rescue SystemExit
      end

      expect(call_count).to eq(1) # Should only try once, no retries
    end
  end
end

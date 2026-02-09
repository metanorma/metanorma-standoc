require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Standoc do
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

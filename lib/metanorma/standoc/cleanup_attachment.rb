module Metanorma
  module Standoc
    module Cleanup
      def attachment_cleanup(xmldoc)
        xmldoc.xpath("//bibitem[uri/@type = 'attachment']").each do |b|
          b["hidden"] = "true"
          b.at("./docidentifier[@type = 'title']")&.remove
          u = b.at("./uri[@type = 'attachment']")
          c = b.at("./uri[@type = 'citation']") ||
            u.after("<uri type='citation'/>")
          uri = attachment_uri(u.text, b)
          u.children = uri
          c.children = uri
        end
      end

      def attachment_uri(path, bib)
        init_attachments
        path = File.join(@localdir, path)
        valid_attachment?(path, bib) or return ""
        @datauriattachment or return attachment_location(path)
        save_attachment(path, bib)
      end

      def save_attachment(path, bib)
        init_attachments
        f = File.basename(path)
        File.exist?(File.join(@attachmentsdir, f)) and
          f += "_#{UUIDTools::UUID.random_create}"
        out_fld = File.join(@attachmentsdir, f)
        FileUtils.cp(path, out_fld)
        datauri_attachment(out_fld, bib.document)
      end

      def attachment_location(path)
        f = path
        @datauriattachment and
          f = File.join(@attachmentsdir, File.basename(path))
        Pathname.new(File.expand_path(f))
          .relative_path_from(Pathname.new(File.expand_path(@output_dir))).to_s
      end

      def datauri_attachment(path, doc)
        @datauriattachment or return
        m = add_misc_container(doc)
        f = attachment_location(path)
        e = (m << "<attachment name='#{f}'/>").last_element_child
        Vectory::Utils::datauri(path, @output_dir).scan(/.{1,60}/)
          .each { |dd| e << "#{dd}\n" }
        f
      end

      def valid_attachment?(path, bib)
        File.exist?(path) and return true
        p = Pathname.new(path).cleanpath
        @log.add("Bibliography", bib, "Attachment #{p} does not exist",
                 severity: 0)
        false
      end

      def init_attachments
        @datauriattachment or return
        @attachmentsdir and return
        @attachmentsfld = "_#{@filename}_attachments"
        @attachmentsdir = File.join(@output_dir, @attachmentsfld)
        FileUtils.rm_rf(@attachmentsdir)
        FileUtils.mkdir_p(@attachmentsdir)
      end
    end
  end
end
